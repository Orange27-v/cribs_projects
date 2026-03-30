import 'dart:async';
import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:cribs_arena/screens/property/property_list_screen.dart';
import 'package:cribs_arena/exceptions/network_exception.dart';
import 'package:cribs_arena/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/screens/components/back_navigator.dart';
import 'package:cribs_arena/screens/property/widgets/full_screen_image_viewer.dart';
import 'package:cribs_arena/screens/booking/booking_screen.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/services/property_service.dart';
import 'package:cribs_arena/services/saved_property_service.dart';
import 'package:cribs_arena/services/auth_service.dart';
import 'package:cribs_arena/services/chat_service.dart';
import 'package:cribs_arena/services/property_tracking_service.dart';
import 'package:cribs_arena/screens/chat/conversation.dart';

import 'package:cribs_arena/screens/property/widgets/property_details_screen_skeleton.dart';
import 'package:cribs_arena/screens/auth/login_screen.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:cribs_arena/main.dart' as app_main;
import 'package:cribs_arena/helpers/chat_helper.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final Property? property;
  final String? propertyId;
  final bool isOwner;

  const PropertyDetailsScreen({
    super.key,
    this.property,
    this.propertyId,
    this.isOwner = false,
  }) : assert(property != null || propertyId != null,
            'Either property or propertyId must be provided');

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen>
    with RouteAware {
  final PageController _pageController = PageController();
  final PropertyService _propertyService = PropertyService();
  final SavedPropertyService _savedPropertyService = SavedPropertyService();
  final AuthService _authService = AuthService();
  final PropertyTrackingService _trackingService = PropertyTrackingService();

  Property? _property;
  bool _isLoading = false;
  String? _error;
  bool _isDescriptionExpanded = false;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    if (widget.property != null) {
      _property = widget.property;
      _checkSavedStatus(widget.property!);
      _trackPropertyView(widget.property!);

      // If property is passed but agent info is missing, fetch full details
      if (_property?.agent == null) {
        debugPrint(
            '⚠️ Property passed without agent info. Fetching full details using numeric ID...');
        _fetchPropertyById(_property!.id.toString());
      }
    } else if (widget.propertyId != null) {
      _fetchPropertyById(widget.propertyId!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to RouteObserver
    app_main.routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute);
  }

  /// Track property view - increment view count
  Future<void> _trackPropertyView(Property property) async {
    try {
      await _trackingService.incrementViewCount(
        property.id.toString(),
      );
      debugPrint('✅ Property view tracked for ${property.propertyId}');
    } catch (e) {
      // Silently fail - tracking shouldn't interrupt user experience
      debugPrint('⚠️ Failed to track property view: $e');
    }
  }

  /// Called when the top route has been popped off, and this route shows up.
  @override
  void didPopNext() {
    // Track view when user returns to this screen from another screen
    if (_property != null) {
      _trackPropertyView(_property!);
    }
  }

  @override
  void dispose() {
    // Unsubscribe from RouteObserver
    app_main.routeObserver.unsubscribe(this);
    _pageController.dispose();
    _propertyService.dispose();
    super.dispose();
  }

  Future<void> _fetchPropertyById(String id) async {
    if (!mounted) return;

    setState(() {
      // Only clear property if we don't have partial data yet
      if (_property == null) {
        _property = null; // Redundant but explicit
      }
      _error = null;
      _isLoading = true;
    });

    try {
      final fetched = await _propertyService.getPropertyById(id);
      if (mounted) {
        setState(() {
          _property = fetched;
          _isLoading = false;
        });
        _checkSavedStatus(fetched);
        _trackPropertyView(fetched);
      }
    } on NetworkException catch (e) {
      String errorMessage = 'Failed to load property';
      if (e.isConnectionError) {
        errorMessage = 'No internet connection';
      } else if (e.type == NetworkErrorType.notFound) {
        errorMessage = 'Property not found';
      }
      if (mounted) {
        setState(() {
          _error = errorMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ErrorHandler.getErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkSavedStatus(Property property) async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) setState(() => _isSaved = false);
      return;
    }

    try {
      final saved = await _savedPropertyService
          .isPropertySaved(property.propertyId.toString());
      if (mounted) setState(() => _isSaved = saved);
    } catch (e) {
      debugPrint('Error checking saved status: $e');
      if (mounted) setState(() => _isSaved = false);
    }
  }

  Future<void> _toggleSavedStatus(Property property) async {
    final isLoggedIn = await _authService.isLoggedIn();
    if (!isLoggedIn) {
      if (mounted) _showLoginDialog();
      return;
    }

    final originalSavedStatus = _isSaved;
    setState(() => _isSaved = !_isSaved);

    try {
      if (originalSavedStatus) {
        // Unsaving property
        await _savedPropertyService
            .unsaveProperty(property.propertyId.toString());

        // Decrement leads count (fire and forget)
        _trackingService
            .decrementLeadsCount(
              property.propertyId.toString(),
            )
            .then((_) => debugPrint('✅ Leads count decremented'))
            .catchError((e) {
          debugPrint('⚠️ Failed to decrement leads count: $e');
        });

        if (context.mounted) {
          SnackbarHelper.showInfo(context, 'Property unsaved',
              position: FlashPosition.bottom);
        }
      } else {
        // Saving property
        await _savedPropertyService
            .saveProperty(property.propertyId.toString());

        // Increment leads count (fire and forget)
        _trackingService
            .incrementLeadsCount(
              property.propertyId.toString(),
            )
            .then((_) => debugPrint('✅ Leads count incremented'))
            .catchError((e) {
          debugPrint('⚠️ Failed to increment leads count: $e');
        });

        if (context.mounted) {
          SnackbarHelper.showInfo(context, 'Property saved',
              position: FlashPosition.bottom);
        }
      }
    } on NetworkException catch (e) {
      setState(() => _isSaved = originalSavedStatus);
      if (!context.mounted) return;
      String message = e.message;
      if (e.isAuthError) {
        message = 'Please log in again';
        _showLoginDialog();
      } else if (e.isConnectionError) {
        message = 'No internet connection';
      }
      SnackbarHelper.showError(context, message,
          position: FlashPosition.bottom);
    } catch (e) {
      setState(() => _isSaved = originalSavedStatus);
      if (!context.mounted) return;
      SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
          position: FlashPosition.bottom);
    }
  }

  Future<void> _startChatWithAgent(Property property) async {
    final agent = property.agent;
    if (agent == null) {
      SnackbarHelper.showError(context, 'Agent information not available',
          position: FlashPosition.bottom);
      return;
    }

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user;

      if (currentUser == null) {
        _showLoginDialog();
        return;
      }

      // Get user_id and validate
      final rawUserId = currentUser['user_id'];
      if (rawUserId == null) {
        debugPrint('❌ Error: user_id is null in currentUser');
        SnackbarHelper.showError(
            context, 'User ID not found. Please log in again.',
            position: FlashPosition.bottom);
        return;
      }

      final userId = 'user_$rawUserId'; // Add user_ prefix for MongoDB format
      final agentId = 'agent_${agent.agentId}';

      debugPrint('💬 Starting chat: userId=$userId, agentId=$agentId');

      final chatService = ChatService();

      final userAvatarUrl =
          ChatHelper.getFullImageUrl(currentUser['profile_picture_url']);
      final agentAvatarUrl = ChatHelper.getFullImageUrl(agent.profileImage);

      debugPrint('👤 User avatar URL: $userAvatarUrl');
      debugPrint('👨‍💼 Agent avatar URL: $agentAvatarUrl');

      final conversationId = await chatService.findOrCreateConversation(
        userId: userId,
        agentId: agentId,
        userName: currentUser['full_name'] ?? 'You',
        userAvatar: userAvatarUrl,
        agentName: agent.fullName,
        agentAvatar: agentAvatarUrl,
      );

      if (!mounted) return;

      debugPrint('✅ Conversation created: $conversationId');

      // Create prefilled message with property details
      final prefilledMessage =
          "Hi! I'm interested in ${property.title}. Can you provide more information?";

      // Prepare property data for the property card in chat
      final propertyImages = property.images.map((img) {
        if (img.startsWith('http://') || img.startsWith('https://')) {
          return img;
        }
        return '$kMainBaseUrl/storage/$img';
      }).toList();

      final propertyData = {
        'propertyId': property
            .propertyId, // Use propertyId string for consistency across apps
        'title': property.title,
        'type': property.type,
        'location': property.location,
        'price': property.price,
        'beds': property.beds,
        'baths': property.baths,
        'images': propertyImages,
        'listingType': property.listingType,
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationScreen(
            conversationId: conversationId,
            otherParticipantId: agentId,
            agentName: agent.fullName,
            agentImageUrl: agentAvatarUrl,
            initialMessage: prefilledMessage,
            initialPropertyData: propertyData, // Pass property data for card
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error starting chat: $e');
      if (!mounted) return;
      SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
          position: FlashPosition.bottom);
    }
  }

  void _showLoginDialog() {
    showDialog(
      context: context,
      builder: (context) => CustomAlertDialog(
        title: const Text('Login Required'),
        content: const Text('You need to be logged in to save properties.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _property == null) {
      return const Scaffold(
        body: PropertyDetailsScreenSkeleton(),
      );
    }

    if (_error != null && _property == null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: kGrey),
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: kGrey700)),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    if (widget.propertyId != null) {
                      _fetchPropertyById(widget.propertyId!);
                    } else {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_property == null) {
      return const Scaffold(
        body: Center(child: Text('Property not found.')),
      );
    }

    final p = _property!;
    final String propertyTitle =
        p.title.isNotEmpty ? p.title : 'Untitled property';
    final List<String> propertyImages = p.images.isNotEmpty
        ? p.images
        : ['assets/images/property_skeleton.jpg'];
    final String propertyDescription =
        p.description.isNotEmpty ? p.description : 'No description available.';
    final String propertyListingType =
        p.listingType.isNotEmpty ? p.listingType : 'Unknown';

    debugPrint('Property Images: $propertyImages');

    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(p),
            const SizedBox(height: kSizedBoxH4),
            _buildImageSlider(propertyImages, propertyListingType),
            const SizedBox(height: kSizedBoxH12),
            _buildPageIndicator(propertyImages.length),
            _buildContent(
              p,
              propertyTitle,
              propertyDescription,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(p),
    );
  }

  Widget _buildHeader(Property p) {
    final String agentName =
        '${p.agent?.firstName ?? ''} ${p.agent?.lastName ?? ''}'.trim();
    final String listedByText = agentName.isNotEmpty
        ? '$agentName listed this property'
        : 'Agent unknown listed this property';
    final String timeAgoText = _getTimeAgo(p.createdAt);

    return Padding(
      padding: kPaddingFromLTRB16_16_16_12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BackNavigator(),
          const SizedBox(height: kSizedBoxH16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  listedByText,
                  style:
                      const TextStyle(color: kBlack54, fontSize: kFontSize12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                timeAgoText,
                style: const TextStyle(
                  color: kPrimaryColor,
                  fontSize: kFontSize10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime? createdAt) {
    if (createdAt == null) return 'Unknown time';
    final Duration diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 365) {
      final years = (diff.inDays / 365).floor();
      return '$years year${years == 1 ? '' : 's'} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} minute${diff.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildImageSlider(List<String> images, String listingType) {
    final List<String> fullImageUrls = images.map((img) {
      // If already a full URL, return as is
      if (img.startsWith('http://') || img.startsWith('https://')) {
        return img;
      }
      // Convert relative URL to full URL
      return '$kMainBaseUrl' 'storage/$img';
    }).toList();

    return SizedBox(
      height: kSizedBoxH250,
      child: PageView.builder(
        controller: _pageController,
        itemCount: fullImageUrls.length,
        itemBuilder: (context, index) {
          final fullImgUrl = fullImageUrls[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImageViewer(
                    images: fullImageUrls,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Container(
              margin: kPaddingH16,
              child: ClipRRect(
                borderRadius: kRadius8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      fullImgUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/property_skeleton.jpg',
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (widget.isOwner) _buildOwnerBadge(),
                    _buildStatusBadge(listingType),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOwnerBadge() {
    return Positioned(
      top: kSizedBoxH16,
      left: kSizedBoxW16,
      child: Container(
        padding: kPaddingH12V8,
        decoration: const BoxDecoration(
          color: kBlackOpacity07,
          borderRadius: kRadius20,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/icons/profile_user.svg',
              colorFilter: const ColorFilter.mode(kWhite, BlendMode.srcIn),
              width: kIconSize16,
              height: kIconSize16,
            ),
            const SizedBox(width: kSizedBoxW8),
            const Text(
              kOwnerText,
              style: TextStyle(
                color: kWhite,
                fontSize: kFontSize12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    return Positioned(
      top: kSizedBoxH16,
      right: kSizedBoxW16,
      child: Container(
        padding: kPaddingH12V8,
        decoration: const BoxDecoration(
          color: kBlackOpacity07,
          borderRadius: kRadius20,
        ),
        child: Text(
          status,
          style: const TextStyle(
            color: kWhite,
            fontSize: kFontSize12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator(int count) {
    return Center(
      child: SmoothPageIndicator(
        controller: _pageController,
        count: count,
        effect: const WormEffect(
          dotHeight: kSizedBoxH8,
          dotWidth: kSizedBoxW8,
          activeDotColor: kPrimaryColor,
          dotColor: kBlack12,
        ),
      ),
    );
  }

  Widget _buildContent(
    Property p,
    String title,
    String description,
  ) {
    return Expanded(
      child: Padding(
        padding: kPaddingH16,
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          thickness: kSizedBoxH6,
          radius: const Radius.circular(10),
          child: ListView(
            children: [
              const SizedBox(height: kSizedBoxH12),
              _buildTitleAndActions(p, title),
              const SizedBox(height: kSizedBoxH12),
              _buildStats(p.beds, p.baths, p.sqft.toString()),
              const SizedBox(height: kSizedBoxH12),
              _buildAddress(p),
              const SizedBox(height: kSizedBoxH12),
              _buildDescription(description),
              const SizedBox(height: kSizedBoxH12),
              _buildAmenities(p),
              const SizedBox(height: kSizedBoxH12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddress(Property p) {
    final String address = p.address ?? 'No address available.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address',
          style: TextStyle(
            fontSize: kFontSize10,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: kBlack87,
          ),
        ),
        const SizedBox(height: kSizedBoxH8),
        Text(
          address,
          style: const TextStyle(
            color: kBlack54,
            fontSize: kFontSize12,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndActions(Property p, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: kFontSize12,
                  fontWeight: FontWeight.bold,
                  color: kBlack87,
                ),
              ),
              const SizedBox(height: kSizedBoxH8),
              if (p.price > 0)
                FormattedPrice(
                  price: p.price,
                  style: GoogleFonts.roboto(
                    fontSize: kFontSize18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                )
              else
                Text(
                  'Price on request',
                  style: GoogleFonts.roboto(
                    fontSize: kFontSize18,
                    fontWeight: FontWeight.bold,
                    color: kPrimaryColor,
                  ),
                ),
            ],
          ),
        ),
        Row(
          children: [
            _iconButton(
              SvgPicture.asset(
                'assets/icons/chat.svg',
                colorFilter:
                    const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
                width: kIconSize24,
                height: kIconSize24,
              ),
              onTap: () => _startChatWithAgent(p),
            ),
            const SizedBox(width: kSizedBoxW12),
            _iconButton(
              SvgPicture.asset(
                'assets/icons/bookmark.svg',
                colorFilter: ColorFilter.mode(
                    _isSaved ? kGreen600 : kGrey, BlendMode.srcIn),
                width: kIconSize24,
                height: kIconSize24,
              ),
              onTap: () => _toggleSavedStatus(p),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStats(int beds, int baths, String sqft) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _StatItem(label: 'Beds', value: beds.toString()),
          const _DotSeparator(),
          _StatItem(label: 'Baths', value: baths.toString()),
          const _DotSeparator(),
          _StatItem(label: 'Sq ft', value: sqft),
        ],
      ),
    );
  }

  Widget _buildDescription(String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          kPropertyDescriptionTitleText,
          style: TextStyle(
            fontSize: kFontSize12,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: kBlack87,
          ),
        ),
        const SizedBox(height: kSizedBoxH12),
        Text(
          description,
          style: const TextStyle(
            color: kBlack54,
            fontSize: kFontSize12,
            height: 1.6,
          ),
          maxLines: _isDescriptionExpanded ? null : 3,
          overflow: _isDescriptionExpanded
              ? TextOverflow.visible
              : TextOverflow.ellipsis,
        ),
        const SizedBox(height: kSizedBoxH8),
        GestureDetector(
          onTap: () => setState(
            () => _isDescriptionExpanded = !_isDescriptionExpanded,
          ),
          child: Text(
            _isDescriptionExpanded ? 'Read Less' : kReadMoreText,
            style: const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: kFontSize12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons(Property p) {
    return SafeArea(
      child: Padding(
        padding: kPaddingFromLTRB16_8_16_16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PrimaryButton(
              text: kBookInspectionText,
              onPressed: () async {
                final bool loggedIn = await _authService.isLoggedIn();
                if (!loggedIn) {
                  _showLoginDialog();
                  return;
                }

                if (!mounted) return;

                if (p.agent != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        agent: p.agent!,
                        propertyDbId: p.id,
                      ),
                    ),
                  );
                } else {
                  SnackbarHelper.showError(
                      context, 'Agent information not available.',
                      position: FlashPosition.bottom);
                }
              },
              icon: const Icon(Icons.arrow_forward,
                  size: kIconSize18, color: kWhite),
            ),
            const SizedBox(height: kSizedBoxH12),
            OutlinedActionButton(
              text: kSeeOtherPropertiesText,
              backgroundColor: kLightBlue,
              borderColor: kLightBlue,
              fontSize: kFontSize12,
              onPressed: () {
                final agent = p.agent;
                if (agent == null) {
                  SnackbarHelper.showError(
                    context,
                    'Agent information not available.',
                    position: FlashPosition.bottom,
                  );
                  return;
                }
                final agentId = p.agentId?.toString();
                if (agentId == null || agentId.isEmpty) {
                  SnackbarHelper.showError(
                    context,
                    'Agent ID not available.',
                    position: FlashPosition.bottom,
                  );
                  return;
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyListScreen(
                      agentId: agentId,
                      agentName: agent.fullName,
                    ),
                  ),
                );
              },
              icon: Icons.remove_red_eye_outlined,
            ),
            const SizedBox(height: kSizedBoxH16),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenities(Property p) {
    if (p.amenities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: kFontSize12,
            fontWeight: FontWeight.w500,
            height: 1.5,
            color: kBlack87,
          ),
        ),
        const SizedBox(height: kSizedBoxH12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: p.amenities.map((amenity) {
            return Chip(
              label: Text(amenity),
              backgroundColor: kLightBlue,
              labelStyle: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kPrimaryColor,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _iconButton(Widget icon, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        padding: kPaddingAll12,
        decoration: const BoxDecoration(
          color: kPrimaryColorOpacity01,
          shape: BoxShape.circle,
        ),
        child: icon,
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: kFontSize12,
            color: kBlack87,
          ),
        ),
        const SizedBox(width: kSizedBoxW6),
        Text(
          label,
          style: const TextStyle(color: kBlack54, fontSize: kFontSize12),
        ),
      ],
    );
  }
}

class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: kPaddingH10,
      child: Text(
        '•',
        style: TextStyle(fontSize: kFontSize12, color: kBlack26),
      ),
    );
  }
}
