import 'dart:async';
import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:cribs_arena/services/chat_service.dart';
import 'package:cribs_arena/exceptions/network_exception.dart';
import 'package:cribs_arena/utils/error_handler.dart';
import 'package:intl/intl.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/models/review.dart';
import 'package:cribs_arena/screens/chat/conversation.dart';
import 'package:cribs_arena/screens/review/review_screen.dart';
import 'package:cribs_arena/screens/property/widgets/featured_property_card.dart';
import 'package:cribs_arena/services/review_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:cribs_arena/provider/user_provider.dart';

import '../../constants.dart';
import '../../models/property.dart';
import 'package:cribs_arena/screens/property/property_list_screen.dart';
import 'package:cribs_arena/services/property_service.dart';
import 'package:cribs_arena/services/saved_agent_service.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/helpers/chat_helper.dart';

const String kDefaultProfileImage = 'assets/images/default_profile.jpg';
const int kReviewMaxCharsForSummary = 100;

class AgentProfileViewModel extends ChangeNotifier {
  final Agent agent;
  final UserProvider userProvider;

  // Services
  final _propertyService = PropertyService();
  final _savedAgentService = SavedAgentService();
  final _chatService = ChatService();
  final _reviewService = ReviewService();

  // State
  List<Property> _agentProperties = [];
  List<Property> get agentProperties => _agentProperties;

  List<Review> _reviews = [];
  List<Review> get reviews => _reviews;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _propertiesError;
  String? get propertiesError => _propertiesError;

  String? _reviewsError;
  String? get reviewsError => _reviewsError;

  bool _isSavedAgent = false;
  bool get isSavedAgent => _isSavedAgent;

  bool _saving = false;
  bool get saving => _saving;

  bool _isCreatingChat = false;
  bool get isCreatingChat => _isCreatingChat;

  // Memoized values
  late final String memberSinceYear;
  late final List<String> activeAreas;

  AgentProfileViewModel({required this.agent, required this.userProvider}) {
    memberSinceYear = _formatMemberSince(agent.memberSince);
    activeAreas = _parseActiveAreas(agent.activeAreas);
  }

  void init() {
    // Schedule the fetch for the next frame to avoid build-time notification errors
    Future.microtask(() async {
      _isLoading = true;
      notifyListeners();

      await Future.wait([
        _fetchAgentProperties(),
        _fetchReviews(),
        _initSavedStatus(),
      ]);

      _isLoading = false;
      notifyListeners();
    });
  }

  void _handleError(Object e, Function(String) setError) {
    final msg = e is NetworkException
        ? (e.isConnectionError ? 'No internet connection' : e.message)
        : e.toString();
    setError(msg);
    notifyListeners();
  }

  Future<void> _fetchAgentProperties() async {
    if (agent.agentId.isEmpty) {
      _propertiesError = 'Agent ID is missing, cannot load properties.';
      notifyListeners();
      return;
    }

    try {
      final properties = await _propertyService
          .getPropertiesByAgentId(agent.agentId)
          .timeout(const Duration(seconds: 15));
      _agentProperties = properties;
      _propertiesError = null;
    } catch (e) {
      debugPrint('Error fetching agent properties: $e');
      _handleError(
          e, (msg) => _propertiesError = 'Failed to load properties: $msg');
    }
  }

  Future<void> _fetchReviews() async {
    try {
      final reviewsData = await _reviewService.getAgentReviews(agent.id);
      _reviews = reviewsData.map((data) => Review.fromJson(data)).toList();
      _reviewsError = null;
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
      _handleError(e, (msg) => _reviewsError = 'Failed to load reviews: $msg');
    }
  }

  Future<void> _initSavedStatus() async {
    try {
      _isSavedAgent = await _savedAgentService.isAgentSaved(agent.agentId);
    } catch (e) {
      debugPrint('Error initializing saved status: $e');
    }
  }

  Future<void> toggleSaveAgent(BuildContext context) async {
    if (_saving) return;

    _saving = true;
    notifyListeners();

    try {
      if (_isSavedAgent) {
        await _savedAgentService.unsaveAgent(agent.agentId);
        _isSavedAgent = false;
        if (context.mounted) {
          SnackbarHelper.showInfo(context, 'Agent unsaved',
              position: FlashPosition.bottom);
        }
      } else {
        await _savedAgentService.saveAgent(agent.agentId);
        _isSavedAgent = true;
        if (context.mounted) {
          SnackbarHelper.showInfo(context, 'Agent saved',
              position: FlashPosition.bottom);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
            position: FlashPosition.bottom);
      }
      debugPrint('Error toggling save agent: $e');
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<void> startChat(BuildContext context) async {
    if (_isCreatingChat) return;

    _isCreatingChat = true;
    notifyListeners();

    try {
      final rawUserId = userProvider.user?['user_id']?.toString();
      if (rawUserId == null) {
        debugPrint('❌ Error: user_id is null in currentUser');
        throw Exception('User not logged in.');
      }

      final userId = 'user_$rawUserId'; // Add user_ prefix for MongoDB format
      final agentId = 'agent_${agent.agentId}';

      debugPrint(
          '💬 Starting chat from agent profile: userId=$userId, agentId=$agentId');

      final userAvatarUrl = ChatHelper.getFullImageUrl(
          userProvider.user?['profile_picture_url']?.toString());
      final agentAvatarUrl = ChatHelper.getFullImageUrl(agent.profileImage);

      debugPrint('👤 User avatar URL: $userAvatarUrl');
      debugPrint('👨‍💼 Agent avatar URL: $agentAvatarUrl');

      final conversationId = await _chatService.findOrCreateConversation(
        userId: userId,
        agentId: agentId,
        userName: userProvider.user?['name']?.toString() ?? 'User',
        userAvatar: userAvatarUrl,
        agentName: agent.fullName,
        agentAvatar: agentAvatarUrl,
        tags: ['Profile Inquiry'],
      );

      if (context.mounted) {
        debugPrint(
            '✅ Conversation created from agent profile: $conversationId');

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversationId: conversationId,
              otherParticipantId: agentId,
              agentName: agent.fullName,
              agentImageUrl: agentAvatarUrl,
              initialMessage:
                  'Hi ${agent.firstName}! I would like to know more about your services.',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error starting chat from agent profile: $e');
      if (context.mounted) {
        SnackbarHelper.showError(context, ErrorHandler.getErrorMessage(e),
            position: FlashPosition.bottom);
      }
    } finally {
      _isCreatingChat = false;
      notifyListeners();
    }
  }

  String _formatMemberSince(String? memberSince) {
    if (memberSince == null || memberSince.isEmpty) return 'N/A';
    try {
      return DateTime.parse(memberSince).year.toString();
    } catch (_) {
      return 'N/A';
    }
  }

  List<String> _parseActiveAreas(List<String>? activeAreas) {
    if (activeAreas == null || activeAreas.isEmpty) return [];
    return activeAreas.where((e) => e.trim().isNotEmpty).toList();
  }

  @override
  void dispose() {
    _propertyService.dispose();
    _savedAgentService.dispose();
    _reviewService.dispose();
    super.dispose();
  }
}

class AgentProfileBottomSheet extends StatelessWidget {
  final Agent agent;

  const AgentProfileBottomSheet({super.key, required this.agent});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AgentProfileViewModel(
        agent: agent,
        userProvider: Provider.of<UserProvider>(context, listen: false),
      )..init(),
      child: const _AgentProfileView(),
    );
  }
}

class _AgentProfileView extends StatelessWidget {
  const _AgentProfileView();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AgentProfileViewModel>(context);
    final agent = viewModel.agent;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            const _DragHandle(),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.symmetric(
                  horizontal: kSizedBoxW12,
                  vertical: kSizedBoxH0,
                ).copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
                children: [
                  _Header(agent: agent),
                  const SizedBox(height: kSizedBoxH16),
                  _AgentStats(
                      agent: agent, memberSinceYear: viewModel.memberSinceYear),
                  const SizedBox(height: kSizedBoxH16),
                  const _SectionTitle('About this Agent'),
                  const SizedBox(height: kSizedBoxH2),
                  _Bio(agent: agent),
                  const SizedBox(height: kSizedBoxH8),
                  _SectionTitle(
                    'Testimonials',
                    onSeeAllPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReviewScreen(
                          agentId: agent.id.toString(),
                          agentName: agent.fullName,
                        ),
                      ),
                    ),
                    seeAllText: 'Write a review',
                  ),
                  const SizedBox(height: kSizedBoxH2),
                  const _Testimonials(),
                  const SizedBox(height: kSizedBoxH8),
                  const _SectionTitle('Active Areas'),
                  const SizedBox(height: kSizedBoxH8),
                  _ActiveAreas(activeAreas: viewModel.activeAreas),
                  const SizedBox(height: kSizedBoxH8),
                  _SectionTitle(
                    'Available properties',
                    onSeeAllPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyListScreen(
                          agentId: agent.agentId,
                          agentName: agent.fullName,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: kSizedBoxH8),
                  const _ListedProperties(),
                  const SizedBox(height: kSizedBoxH16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: kWhite,
      padding: kPaddingV12,
      child: Center(
        child: Container(
          width: kSizedBoxW40,
          height: kSizedBoxH4,
          decoration:
              const BoxDecoration(color: kGrey400, borderRadius: kRadius2),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final Agent agent;
  const _Header({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kPaddingAll20,
      decoration: const BoxDecoration(
        color: kLightBlue,
        borderRadius: kRadius12,
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileImage(
                  agent: agent, isOnline: (agent.loginStatus ?? 0) == 1),
              const SizedBox(width: kSizedBoxW16),
              _AgentInfo(agent: agent),
            ],
          ),
          const SizedBox(height: kSizedBoxH20),
          _ActionButtons(agent: agent),
        ],
      ),
    );
  }
}

class _ProfileImage extends StatelessWidget {
  final Agent agent;
  final bool isOnline;

  const _ProfileImage({required this.agent, required this.isOnline});

  ImageProvider _getAgentImageProvider() {
    final String profilePicturePath = agent.profileImage;

    if (profilePicturePath.isEmpty) {
      return const AssetImage('assets/images/default_profile.jpg');
    }

    if (profilePicturePath.startsWith('http')) {
      return NetworkImage(profilePicturePath);
    }

    // Clean the path
    String agentImagePath = profilePicturePath;

    // Remove leading slash if present
    if (agentImagePath.startsWith('/')) {
      agentImagePath = agentImagePath.substring(1);
    }

    // If it's already a full storage path (e.g., "storage/agent_pictures/1.jpg")
    if (agentImagePath.startsWith('storage/')) {
      final String fullImageUrl = '$kMainBaseUrl$agentImagePath';
      return NetworkImage(fullImageUrl);
    }

    // If it's a relative path like "agent_pictures/1.jpg" or "profile_pictures/xxx.jpg"
    if (agentImagePath.contains('agent_pictures/') ||
        agentImagePath.contains('profile_pictures/')) {
      final String fullImageUrl = '${kMainBaseUrl}storage/$agentImagePath';
      return NetworkImage(fullImageUrl);
    }

    // If it's just a filename, try agent_pictures first
    if (!agentImagePath.contains('/')) {
      final String fullImageUrl =
          '${kMainBaseUrl}storage/agent_pictures/$agentImagePath';
      return NetworkImage(fullImageUrl);
    }

    // Default fallback
    final String fullImageUrl = '${kMainBaseUrl}storage/$agentImagePath';
    return NetworkImage(fullImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 70,
          height: 70,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: kGrey200,
          ),
          clipBehavior: Clip.hardEdge,
          child: Image(
            image: _getAgentImageProvider(),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset('assets/images/default_profile.jpg',
                  fit: BoxFit.cover);
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2.0,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(kPrimaryColor),
                ),
              );
            },
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 15,
              height: 15,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: kWhite, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _AgentInfo extends StatelessWidget {
  final Agent agent;

  const _AgentInfo({required this.agent});

  @override
  Widget build(BuildContext context) {
    final String experienceText =
        '${agent.experienceYears?.toString() ?? '0'} Yrs Exp';

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            agent.fullName,
            style: const TextStyle(
                fontSize: kFontSize12,
                fontWeight: FontWeight.bold,
                color: kPrimaryColor),
          ),
          const SizedBox(height: kSizedBoxH12),
          Wrap(
            spacing: kSizedBoxW8,
            runSpacing: kSizedBoxH8,
            children: [
              _InfoChip(icon: Icons.person, text: agent.role ?? 'Agent'),
              if (agent.isLicensed ?? false)
                const _InfoChip(
                    icon: Icons.verified_user_outlined, text: 'Licensed'),
              _InfoChip(icon: Icons.work_outline, text: experienceText),
            ],
          ),
          const SizedBox(height: kSizedBoxH12),
          Row(
            children: [
              const Icon(Icons.location_on,
                  color: kPrimaryColor, size: kIconSize16),
              const SizedBox(width: kSizedBoxW6),
              Flexible(
                child: Text(
                  agent.area ?? 'Location not specified',
                  style: const TextStyle(
                      color: kPrimaryColor, fontSize: kFontSize10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final Agent agent;

  const _ActionButtons({required this.agent});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AgentProfileViewModel>(context);

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: viewModel.isCreatingChat
                ? null
                : () => viewModel.startChat(context),
            icon: viewModel.isCreatingChat
                ? const CustomLoadingIndicator(
                    size: 24,
                    strokeWidth: 2,
                    color: kPrimaryColor,
                    backgroundColor: Colors.transparent,
                  )
                : SvgPicture.asset(
                    'assets/icons/chat.svg',
                    colorFilter:
                        const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
                    width: kIconSize24,
                    height: kIconSize24,
                  ),
            label: Text(viewModel.isCreatingChat ? 'Loading...' : 'Chat',
                style: const TextStyle(fontSize: kFontSize14)),
            style: ElevatedButton.styleFrom(
              foregroundColor: kPrimaryColor,
              backgroundColor: kWhite,
              shape: const RoundedRectangleBorder(borderRadius: kRadius8),
              elevation: 0,
              shadowColor: Colors.transparent,
              minimumSize: const Size(0, kSizedBoxH48),
            ),
          ),
        ),
        const SizedBox(width: kSizedBoxW12),
        SizedBox(
          width: kSizedBoxH48,
          height: kSizedBoxH48,
          child: ElevatedButton(
            onPressed: viewModel.saving
                ? null
                : () => viewModel.toggleSaveAgent(context),
            style: ElevatedButton.styleFrom(
              foregroundColor: kPrimaryColor,
              backgroundColor: kWhite,
              shape: const RoundedRectangleBorder(borderRadius: kRadius8),
              elevation: 0,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.zero,
            ),
            child: viewModel.saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomLoadingIndicator(strokeWidth: 2, size: 24),
                  )
                : Icon(viewModel.isSavedAgent
                    ? Icons.bookmark
                    : Icons.bookmark_border),
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: kPrimaryColor, size: kIconSize14),
        const SizedBox(width: kSizedBoxW4),
        Text(
          text,
          style: const TextStyle(
            color: kPrimaryColor,
            fontSize: kFontSize10,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAllPressed;
  final String seeAllText;

  const _SectionTitle(this.title,
      {this.onSeeAllPressed, this.seeAllText = kSeeAllText});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: kFontSize12,
            fontWeight: FontWeight.bold,
            color: kPrimaryColor,
          ),
        ),
        if (onSeeAllPressed != null)
          TextButton(
            onPressed: onSeeAllPressed,
            child: Text(
              seeAllText,
              style: const TextStyle(
                color: kPrimaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

class _AgentStats extends StatelessWidget {
  final Agent agent;
  final String memberSinceYear;

  const _AgentStats({required this.agent, required this.memberSinceYear});
  @override
  Widget build(BuildContext context) {
    final totalSales = agent.totalSales?.toString() ?? '0';
    final averageRating = agent.averageRating?.toStringAsFixed(1) ?? '0.0';
    final totalReviews = agent.totalReviews ?? 0;

    return Container(
      padding: kPaddingV12,
      decoration: const BoxDecoration(
        color: kLightBlueOpacity05,
        borderRadius: kRadius20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(
              icon: Icons.sell_outlined,
              value: totalSales,
              label: 'Total Sales'),
          _Stat(
            icon: Icons.star_border_outlined,
            value: averageRating,
            label: '$totalReviews Reviews',
          ),
          _Stat(
            icon: Icons.calendar_today_outlined,
            value: memberSinceYear,
            label: 'Member Since',
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: kPaddingAll6,
          decoration: const BoxDecoration(
            color: kWhite,
            borderRadius: kRadius12,
          ),
          child: Icon(icon, color: kPrimaryColor, size: kIconSize20),
        ),
        const SizedBox(width: kSizedBoxW8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: kFontSize8,
                color: kPrimaryColor,
              ),
            ),
            const SizedBox(height: kSizedBoxH2),
            Text(
              label,
              style: const TextStyle(
                color: kPrimaryColorOpacity08,
                fontSize: kFontSize8,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoContainer extends StatelessWidget {
  final Widget child;
  const _InfoContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: kPaddingAll2,
      width: double.infinity,
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: kRadius12,
      ),
      child: child,
    );
  }
}

class _Bio extends StatelessWidget {
  final Agent agent;
  const _Bio({required this.agent});

  @override
  Widget build(BuildContext context) {
    final bio = agent.bio?.trim() ?? '';
    if (bio.isEmpty) {
      return const _InfoContainer(
        child: Text(
          'No bio provided.',
          style: TextStyle(color: kGrey700),
        ),
      );
    }
    return _InfoContainer(
      child: Text(
        bio,
        style: const TextStyle(color: kGrey700, height: 1.6),
      ),
    );
  }
}

class _Testimonials extends StatefulWidget {
  const _Testimonials();

  @override
  State<_Testimonials> createState() => _TestimonialsState();
}

class _TestimonialsState extends State<_Testimonials> {
  final Set<int> _expandedReviews = {};
  bool _showAllReviews = false;

  void _toggleExpanded(int reviewId) {
    setState(() {
      if (_expandedReviews.contains(reviewId)) {
        _expandedReviews.remove(reviewId);
      } else {
        _expandedReviews.add(reviewId);
      }
    });
  }

  void _toggleShowAll() {
    setState(() {
      _showAllReviews = !_showAllReviews;
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AgentProfileViewModel>(context);

    if (viewModel.isLoading) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (viewModel.reviewsError != null) {
      return Center(
        child: Column(
          children: [
            Text(viewModel.reviewsError ?? 'Error loading reviews'),
            TextButton(
              onPressed: () => viewModel._fetchReviews(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (viewModel.reviews.isEmpty) {
      return const _InfoContainer(
        child: Text(
          'Be the first to review this agent',
          style: TextStyle(color: kGrey700, height: 1.6),
        ),
      );
    }

    final reviewsToShow = _showAllReviews
        ? viewModel.reviews
        : viewModel.reviews.take(3).toList();
    final hasMoreReviews = viewModel.reviews.length > 3;

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviewsToShow.length,
          itemBuilder: (context, index) {
            final review = reviewsToShow[index];
            final isLast = index == reviewsToShow.length - 1;

            return _ReviewItem(
              review: review,
              isExpanded: _expandedReviews.contains(review.id),
              onToggle: () => _toggleExpanded(review.id),
              margin: (isLast && hasMoreReviews && !_showAllReviews)
                  ? const EdgeInsets.only(bottom: 4)
                  : null,
            );
          },
        ),
        if (hasMoreReviews)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: _toggleShowAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(_showAllReviews
                  ? 'Show Less'
                  : 'See All Reviews (${viewModel.reviews.length})'),
            ),
          ),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final Review review;
  final bool isExpanded;
  final VoidCallback onToggle;
  final EdgeInsetsGeometry? margin;

  const _ReviewItem({
    required this.review,
    required this.isExpanded,
    required this.onToggle,
    this.margin,
  });

  String _formatDate(String dateString) {
    try {
      final DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return dateString;
    }
  }

  ImageProvider _getUserImageProvider() {
    final String photoUrl = review.userPhotoUrl;

    if (photoUrl.isEmpty) {
      return const AssetImage('assets/images/default_profile.jpg');
    }

    if (photoUrl.startsWith('http')) {
      return NetworkImage(photoUrl);
    }

    // Clean the path
    String imagePath = photoUrl;

    // Remove leading slash if present
    if (imagePath.startsWith('/')) {
      imagePath = imagePath.substring(1);
    }

    // If it's already a full storage path
    if (imagePath.startsWith('storage/')) {
      final String fullImageUrl = '$kMainBaseUrl$imagePath';
      return NetworkImage(fullImageUrl);
    }

    // If it's a relative path like "user_pictures/xxx.jpg" or "profile_pictures/xxx.jpg"
    if (imagePath.contains('user_pictures/') ||
        imagePath.contains('profile_pictures/')) {
      final String fullImageUrl = '${kMainBaseUrl}storage/$imagePath';
      return NetworkImage(fullImageUrl);
    }

    // If it's just a filename, try user_pictures first
    if (!imagePath.contains('/')) {
      final String fullImageUrl =
          '${kMainBaseUrl}storage/user_pictures/$imagePath';
      return NetworkImage(fullImageUrl);
    }

    // Default fallback
    final String fullImageUrl = '${kMainBaseUrl}storage/$imagePath';
    return NetworkImage(fullImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final reviewText = review.reviewText;
    // Check if text exceeds character limit OR has enough newlines to be truncated by maxLines: 2
    final isLongText = reviewText.length > kReviewMaxCharsForSummary ||
        reviewText.split('\n').length > 2;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kGrey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kGrey300,
            ),
            clipBehavior: Clip.hardEdge,
            child: Image(
              image: _getUserImageProvider(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset('assets/images/default_profile.jpg',
                    fit: BoxFit.cover);
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        color: kGrey600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: kBlack87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: kOrange,
                      size: 12,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  reviewText,
                  maxLines: isExpanded ? null : 2,
                  overflow:
                      isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kGrey600,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                if (isLongText)
                  GestureDetector(
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        isExpanded ? 'Read less' : 'Read more',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveAreas extends StatelessWidget {
  final List<String> activeAreas;
  const _ActiveAreas({required this.activeAreas});
  @override
  Widget build(BuildContext context) {
    if (activeAreas.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No active areas specified',
          style: TextStyle(color: kGrey600, fontSize: kFontSize12),
        ),
      );
    }

    return Wrap(
      spacing: kSizedBoxW8,
      runSpacing: kSizedBoxH10,
      children: activeAreas.map((area) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: kLightBlueOpacity05,
            borderRadius: kRadius20,
          ),
          child: Text(
            area,
            style: const TextStyle(
              color: kPrimaryColor,
              fontSize: kFontSize11,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ListedProperties extends StatelessWidget {
  const _ListedProperties();

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<AgentProfileViewModel>(context);

    if (viewModel.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CustomLoadingIndicator(),
        ),
      );
    }

    if (viewModel.propertiesError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                viewModel.propertiesError ?? 'Error loading properties',
                style: const TextStyle(color: kGrey600),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => viewModel._fetchAgentProperties(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (viewModel.agentProperties.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Text(
            'No properties listed by this agent yet.',
            style: TextStyle(color: kGrey600),
          ),
        ),
      );
    }

    return SizedBox(
      height: 240, // Slightly increased height for card fitting
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: viewModel.agentProperties.length,
        itemBuilder: (_, index) => SizedBox(
          width: 350, // Fixed width for horizontal cards
          child: FeaturedPropertyCard(
            property: viewModel.agentProperties[index],
          ),
        ),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
      ),
    );
  }
}
