import 'dart:async';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/exceptions/network_exception.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/models/listed_property.dart';
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/screens/agents/all_agents_screen.dart';
import 'package:cribs_arena/screens/property/new_listings_screen.dart';
import 'package:cribs_arena/screens/property/recommended_property_screen.dart';
import 'package:cribs_arena/screens/property/property_details_screen.dart';
import 'package:cribs_arena/screens/property/widgets/property_list_item.dart';
import 'package:cribs_arena/screens/property/widgets/property_summary_card_skeleton.dart';
import 'package:cribs_arena/services/fetch_nearby_agents_services.dart';
import 'package:cribs_arena/services/new_listing_service.dart';
import 'package:cribs_arena/services/recommended_property_service.dart';
import 'package:cribs_arena/services/saved_property_service.dart';
import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../agents/agent_card.dart';
import '../agents/agent_card_skeleton.dart';
import '../agents/agent_profile_bottom_sheet.dart';
import '../property/widgets/property_list_item_skeleton.dart';
import '../property/widgets/property_summary_card.dart';

class MyFeedScreen extends StatefulWidget {
  const MyFeedScreen({super.key});

  @override
  State<MyFeedScreen> createState() => _MyFeedScreenState();
}

class _MyFeedScreenState extends State<MyFeedScreen> {
  final ScrollController _agentsController = ScrollController();
  final ScrollController _recommendedPropertiesController = ScrollController();
  final ScrollController _newListingsController = ScrollController();
  final PageController _bannerController = PageController();
  Timer? _bannerTimer;

  int _agentsPage = 0, _recommendedPage = 0, _newListingsPage = 0;

  List<Agent> _recommendedAgents = [];
  bool _loadingAgents = true;
  String _agentsError = '';

  List<Property> _recommendedProperties = [];
  bool _loadingRecommendedProperties = false;
  String? _recommendedPropertiesError;

  List<Property> _newListings = [];
  bool _loadingNewListings = false;
  String? _newListingsError;

  // Track bookmark states for new listings
  final Map<String, bool> _bookmarkStates = {};

  final RecommendedPropertyService _recommendedPropertyService =
      RecommendedPropertyService();
  final NewListingService _newListingService = NewListingService();
  final FetchNearbyAgentsService _fetchNearbyAgentsService =
      FetchNearbyAgentsService();
  final SavedPropertyService _savedPropertyService = SavedPropertyService();

  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _setupScrollListeners();
    _startBannerAutoSlide();
    _loadAllData();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _agentsController.dispose();
    _recommendedPropertiesController.dispose();
    _newListingsController.dispose();
    _savedPropertyService.dispose();
    super.dispose();
  }

  void _setupScrollListeners() {
    // Enhanced scroll listeners with safety checks
    _agentsController.addListener(() {
      if (!mounted || !_agentsController.hasClients) return;
      _updatePage(
        _agentsController,
        160,
        10,
        _recommendedAgents.length,
        (p) {
          if (mounted) setState(() => _agentsPage = p);
        },
      );
    });

    _recommendedPropertiesController.addListener(() {
      if (!mounted || !_recommendedPropertiesController.hasClients) return;
      _updatePage(
        _recommendedPropertiesController,
        220,
        12,
        _recommendedProperties.length,
        (p) {
          if (mounted) setState(() => _recommendedPage = p);
        },
      );
    });

    _newListingsController.addListener(() {
      if (!mounted || !_newListingsController.hasClients) return;
      _updatePage(
        _newListingsController,
        300,
        12,
        _newListings.length,
        (p) {
          if (mounted) setState(() => _newListingsPage = p);
        },
      );
    });
  }

  void _startBannerAutoSlide() {
    const bannerCount = 3; // Number of banner images
    _bannerTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || !_bannerController.hasClients) return;

      final nextPage = (_bannerController.page?.round() ?? 0) + 1;

      if (nextPage >= bannerCount) {
        // Loop back to first page
        _bannerController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _bannerController.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _updatePage(
    ScrollController controller,
    double width,
    double spacing,
    int len,
    Function(int) update,
  ) {
    if (len < 2) return;

    // Comprehensive safety checks
    if (!mounted) return;
    if (!controller.hasClients) return;
    if (controller.positions.isEmpty) return;

    try {
      // Check if position has valid dimensions
      if (!controller.position.hasContentDimensions) return;

      final offset = controller.offset;

      // Ensure offset is valid and not infinity/NaN
      if (!offset.isFinite || offset < 0) return;

      final index = (offset / (width + spacing)).round().clamp(0, len - 1);

      // Only update if mounted and index is valid
      if (mounted && index >= 0 && index < len) {
        update(index);
      }
    } catch (e) {
      // Silently catch any scroll position errors during rapid updates
      debugPrint('Scroll update error: $e');
    }
  }

  Future<void> _loadAllData({bool forceRefresh = false}) async {
    Position? position;
    String? locationError;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        locationError =
            'Location services are disabled. Please enable location services.';
      } else {
        // Check location permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            locationError =
                'Location permissions are denied. Please grant location permission.';
          }
        }

        if (permission == LocationPermission.deniedForever) {
          locationError =
              'Location permissions are permanently denied. Please enable them in app settings.';
        } else if (locationError == null) {
          // Try to get position only if permissions are OK
          try {
            position = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: Duration(seconds: 10),
              ),
            ).timeout(const Duration(seconds: 10));
            if (mounted) {
              setState(() => _currentPosition = position);
            }
          } catch (e) {
            locationError = 'Failed to get location: ${e.toString()}';
            debugPrint('Location error: $e');
          }
        }
      }
    } catch (e) {
      locationError =
          'Failed to get location. Please enable location services.';
      debugPrint('Location error: $e');
    }

    if (position != null) {
      // Only fetch if we don't have data already (unless forceRefresh)
      final futures = <Future<void>>[];
      if (forceRefresh || _recommendedProperties.isEmpty) {
        futures.add(
            _fetchRecommendedProperties(position.latitude, position.longitude));
      }
      if (forceRefresh || _newListings.isEmpty) {
        futures.add(_fetchNewListings(position.latitude, position.longitude));
      }
      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    } else {
      final errorMessage = locationError ?? 'Location not available';
      debugPrint('Location unavailable: $errorMessage');
      // Don't clear existing data, just set error state if we don't have data
      if (mounted && _recommendedProperties.isEmpty) {
        setState(() {
          _recommendedPropertiesError = errorMessage;
        });
      }
      if (mounted && _newListings.isEmpty) {
        setState(() {
          _newListingsError = errorMessage;
        });
      }
    }

    await _fetchRecommendedAgents(forceRefresh: forceRefresh);
  }

  Future<void> _onRefresh() async => _loadAllData(forceRefresh: true);

  Future<void> _fetchRecommendedProperties(
      double latitude, double longitude) async {
    if (!mounted) return;

    // Only show loading if we don't have data
    if (_recommendedProperties.isEmpty) {
      setState(() {
        _loadingRecommendedProperties = true;
        _recommendedPropertiesError = null;
      });
    }

    try {
      final properties = await _recommendedPropertyService
          .getRecommendedProperties(latitude, longitude)
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _recommendedProperties = properties;
          _loadingRecommendedProperties = false;
          _recommendedPropertiesError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_recommendedProperties.isEmpty) {
            _recommendedPropertiesError = getErrorMessage(e);
          }
          _loadingRecommendedProperties = false;
        });
        debugPrint('Error fetching recommended properties: $e');
      }
    }
  }

  Future<void> _fetchNewListings(double latitude, double longitude) async {
    if (!mounted) return;

    // Only show loading if we don't have data
    if (_newListings.isEmpty) {
      setState(() {
        _loadingNewListings = true;
        _newListingsError = null;
      });
    }

    try {
      final listings = await _newListingService
          .getNewListingsNearby(latitude, longitude)
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _newListings = listings;
          _loadingNewListings = false;
          _newListingsError = null;
        });

        // Load bookmark states for the fetched listings
        _loadBookmarkStates(listings);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (_newListings.isEmpty) {
            _newListingsError = getErrorMessage(e);
          }
          _loadingNewListings = false;
        });
        debugPrint('Error fetching new listings: $e');
      }
    }
  }

  Future<void> _loadBookmarkStates(List<Property> properties) async {
    for (final property in properties) {
      try {
        final isSaved =
            await _savedPropertyService.isPropertySaved(property.propertyId);
        if (mounted) {
          setState(() {
            _bookmarkStates[property.propertyId] = isSaved;
          });
        }
      } catch (e) {
        // Silently fail - bookmark state will default to false
        debugPrint(
            'Error loading bookmark state for ${property.propertyId}: $e');
      }
    }
  }

  Future<void> _fetchRecommendedAgents({bool forceRefresh = false}) async {
    // Only show loading if we don't have data or force refresh
    if (forceRefresh || _recommendedAgents.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingAgents = true;
          _agentsError = '';
        });
      }
    }

    try {
      final agents = await _fetchNearbyAgentsService
          .getNearbyAgents()
          .timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _recommendedAgents = agents.take(8).toList();
          _loadingAgents = false;
          _agentsError = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (forceRefresh || _recommendedAgents.isEmpty) {
            _recommendedAgents = [];
            _agentsError = getErrorMessage(e);
          }
          _loadingAgents = false;
        });
        debugPrint('Error fetching agents: $e');
      }
    }
  }

  Future<void> _toggleBookmark(String propertyId) async {
    final currentState = _bookmarkStates[propertyId] ?? false;

    // Optimistically update UI
    setState(() {
      _bookmarkStates[propertyId] = !currentState;
    });

    try {
      if (currentState) {
        await _savedPropertyService.unsaveProperty(propertyId);
      } else {
        await _savedPropertyService.saveProperty(propertyId);
      }
    } on NetworkException catch (e) {
      // Revert UI on error
      setState(() {
        _bookmarkStates[propertyId] = currentState;
      });

      if (!mounted) return;

      String message = 'Failed to update bookmark';
      if (e.isAuthError) {
        message = 'Please log in to bookmark properties';
      } else if (e.isConnectionError) {
        message = 'No internet connection';
      }

      SnackbarHelper.showError(
        context,
        message,
        position: FlashPosition.bottom,
      );
    } catch (e) {
      // Revert UI on error
      setState(() {
        _bookmarkStates[propertyId] = currentState;
      });

      if (!mounted) return;

      SnackbarHelper.showError(
        context,
        'Failed to update bookmark',
        position: FlashPosition.bottom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomRefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          padding: const EdgeInsets.only(top: 20, bottom: 24),
          children: [
            _buildHeader(),
            SizedBox(height: kSizedBoxH16),
            _sectionHeader('Recommended Agents', () {
              if (_currentPosition != null) {
                final position = _currentPosition!;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AllAgentsScreen(
                      userLatitude: position.latitude,
                      userLongitude: position.longitude,
                    ),
                  ),
                );
              } else {
                SnackbarHelper.showError(
                  context,
                  'Location not available. Please enable location services and try again.',
                  position: FlashPosition.bottom,
                );
              }
            }),
            SizedBox(height: kSizedBoxH16),
            _recommendedAgentsWidget(),
            SizedBox(height: kSizedBoxH24),
            _sectionHeader('Recommended Properties', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const RecommendedPropertyScreen(),
                ),
              );
            }),
            SizedBox(height: kSizedBoxH16),
            _recommendedPropertiesWidget(),
            SizedBox(height: kSizedBoxH24),
            _sectionHeader('New Listings Near You', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NewListingsScreen(
                    latitude: _currentPosition?.latitude,
                    longitude: _currentPosition?.longitude,
                  ),
                ),
              );
            }),
            SizedBox(height: kSizedBoxH16),
            _newListingsWidget(),
            SizedBox(height: kSizedBoxH24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final List<String> bannerImages = [
      'assets/images/slider1.jpg',
      'assets/images/slider2.jpg',
      'assets/images/slider3.jpg',
    ];

    return Padding(
      padding: kPaddingH16,
      child: SizedBox(
        height: 200,
        child: PageView.builder(
          controller: _bannerController,
          itemCount: bannerImages.length,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(bannerImages[index]),
                  fit: BoxFit.contain,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, VoidCallback onTap) => Padding(
        padding: kPaddingH16,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: kFontSize18,
                fontWeight: FontWeight.bold,
                color: kDarkTextColor,
              ),
            ),
            GestureDetector(
              onTap: onTap,
              child: Text(
                'see all',
                style: GoogleFonts.roboto(
                  color: kPrimaryColorDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _recommendedAgentsWidget() {
    if (_loadingAgents) {
      return SizedBox(
        height: 250,
        child: ListView.builder(
          key: const ValueKey('agents_loading'),
          scrollDirection: Axis.horizontal,
          itemCount: 2,
          padding: kPaddingH16,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(right: 10),
            child: SizedBox(width: 160, child: AgentCardSkeleton()),
          ),
        ),
      );
    }

    if (_agentsError.isNotEmpty) {
      return SizedBox(
        height: 250,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: kGrey500,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to Load Agents',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kDarkTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _agentsError,
              style: const TextStyle(color: kGrey600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (_recommendedAgents.isEmpty) {
      return const SizedBox(
        height: 250,
        child: Center(child: Text('No recommended agents found.')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: ListView.builder(
            key: ValueKey('agents_${_recommendedAgents.length}'),
            controller: _agentsController,
            scrollDirection: Axis.horizontal,
            itemCount: _recommendedAgents.length,
            padding: kPaddingH16,
            itemBuilder: (context, i) {
              // Bounds checking
              if (i < 0 || i >= _recommendedAgents.length) {
                return const SizedBox.shrink();
              }

              final agent = _recommendedAgents[i];

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () {
                    if (!mounted) return;
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      isDismissible: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => AgentProfileBottomSheet(agent: agent),
                    );
                  },
                  child: SizedBox(
                    width: 160,
                    child: AgentCard(
                      key: ValueKey('agent_${agent.id}'),
                      agent: agent,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: kSizedBoxH16),
        if (_recommendedAgents.length > 1)
          DotsIndicator(
            itemCount: _recommendedAgents.length,
            activeIndex: _agentsPage,
            activeColor: kPrimaryColorDark,
            inactiveColor: kGrey300,
          ),
      ],
    );
  }

  Widget _recommendedPropertiesWidget() {
    const itemWidth = 220.0;
    const itemHeight = 230.0;
    const itemSpacing = 12.0;

    if (_loadingRecommendedProperties) {
      return SizedBox(
        height: itemHeight,
        child: ListView.builder(
          key: const ValueKey('properties_loading'),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          padding: kPaddingH16,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(right: itemSpacing),
            child: SizedBox(
                width: itemWidth, child: PropertySummaryCardSkeleton()),
          ),
        ),
      );
    }

    if (_recommendedPropertiesError != null) {
      return SizedBox(
        height: itemHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 48,
              color: kGrey500,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to Load Properties',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kDarkTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              getErrorMessage(_recommendedPropertiesError),
              style: const TextStyle(color: kGrey600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final properties = _recommendedProperties.take(8).toList();
    if (properties.isEmpty) {
      return const SizedBox(
        height: itemHeight,
        child: Center(child: Text('No recommended properties found.')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: itemHeight,
          child: ListView.builder(
            key: ValueKey('properties_${properties.length}'),
            controller: _recommendedPropertiesController,
            scrollDirection: Axis.horizontal,
            itemCount: properties.length,
            padding: kPaddingH16,
            itemBuilder: (context, i) {
              // Bounds checking
              if (i < 0 || i >= properties.length) {
                return const SizedBox.shrink();
              }

              final property = properties[i];

              return Padding(
                padding: const EdgeInsets.only(right: itemSpacing),
                child: SizedBox(
                  width: itemWidth,
                  child: PropertySummaryCard(
                    key: ValueKey('property_${property.id}'),
                    property: property,
                    onRemove: (p1) {},
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: kSizedBoxH16),
        if (properties.length > 1)
          DotsIndicator(
            itemCount: properties.length,
            activeIndex: _recommendedPage,
            activeColor: kPrimaryColorDark,
            inactiveColor: kGrey300,
          ),
      ],
    );
  }

  Widget _newListingsWidget() {
    const itemWidth = 300.0;
    const itemHeight = 160.0;
    const itemSpacing = 12.0;

    if (_loadingNewListings) {
      return SizedBox(
        height: itemHeight,
        child: ListView.builder(
          key: const ValueKey('listings_loading'),
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          padding: kPaddingH16,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(right: itemSpacing),
            child:
                SizedBox(width: itemWidth, child: PropertyListItemSkeleton()),
          ),
        ),
      );
    }

    if (_newListingsError != null) {
      return SizedBox(
        height: itemHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.new_releases_outlined,
              size: 48,
              color: kGrey500,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to Load New Listings',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: kDarkTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              getErrorMessage(_newListingsError),
              style: const TextStyle(color: kGrey600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final listings = _newListings.take(8).toList();
    if (listings.isEmpty) {
      return const SizedBox(
        height: itemHeight,
        child: Center(child: Text('No new listings found.')),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: itemHeight,
          child: ListView.builder(
            key: ValueKey('listings_${listings.length}'),
            controller: _newListingsController,
            scrollDirection: Axis.horizontal,
            itemCount: listings.length,
            padding: kPaddingH16,
            itemBuilder: (context, i) {
              // Bounds checking
              if (i < 0 || i >= listings.length) {
                return const SizedBox.shrink();
              }

              final listing = listings[i];
              final isBookmarked = _bookmarkStates[listing.propertyId] ?? false;

              return Padding(
                padding: const EdgeInsets.only(right: itemSpacing),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PropertyDetailsScreen(property: listing),
                    ),
                  ),
                  child: SizedBox(
                    width: itemWidth,
                    child: PropertyListItem(
                      key: ValueKey('listing_${listing.id}'),
                      property: ListedProperty.fromProperty(listing,
                          isBookmarked: isBookmarked),
                      onBookmarkTap: () => _toggleBookmark(listing.propertyId),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: kSizedBoxH16),
        if (listings.length > 1)
          DotsIndicator(
            itemCount: listings.length,
            activeIndex: _newListingsPage,
            activeColor: kPrimaryColorDark,
            inactiveColor: kGrey300,
          ),
      ],
    );
  }
}

class DotsIndicator extends StatelessWidget {
  final int itemCount;
  final int activeIndex;
  final Color activeColor;
  final Color inactiveColor;

  const DotsIndicator({
    super.key,
    required this.itemCount,
    required this.activeIndex,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure activeIndex is within valid bounds
    if (itemCount == 0) return const SizedBox.shrink();
    final safeActiveIndex = activeIndex.clamp(0, itemCount - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(itemCount, (i) {
        final active = i == safeActiveIndex;
        return AnimatedContainer(
          duration: kDuration200ms,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          decoration: BoxDecoration(
            color: active ? activeColor : inactiveColor,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
