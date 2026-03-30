import 'package:cribs_arena/screens/notification/notifications_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import '../../constants.dart';
import '../components/app_header_content.dart';
import 'package:cribs_arena/screens/schedule/schedule_screen.dart';
import 'user_widgets/navigation_tabs_widget.dart';
import 'user_widgets/verification_banner.dart';
import 'map_home_screen.dart';
import 'my_feed_screen.dart';
import 'package:cribs_arena/widgets/widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentTabIndex = 0;
  final GlobalKey _tabBarKey = GlobalKey();
  double _indicatorWidth = 0.0;
  double _indicatorLeft = 0.0;
  late PageController _pageController;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _determinePosition();
    // We need to wait for the first frame to be rendered to calculate the
    // indicator position.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorPosition();
    });
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _error = 'Location services are disabled.';
        _isLoading = false;
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permissions are denied';
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _error =
            'Location permissions are permanently denied, we cannot request permissions.';
        _isLoading = false;
      });
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _currentPosition = position;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to get current location: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Calculates the position and width of the tab indicator based on the
  /// size of the TabBar.
  void _updateIndicatorPosition() {
    if (_tabBarKey.currentContext != null) {
      final RenderBox tabBarRenderBox =
          _tabBarKey.currentContext!.findRenderObject() as RenderBox;
      final double tabBarWidth = tabBarRenderBox.size.width;
      final double singleTabWidth = tabBarWidth / 2;

      // Update the state to trigger a rebuild with the new indicator dimensions.
      setState(() {
        _indicatorWidth = singleTabWidth;
        _indicatorLeft = _currentTabIndex * singleTabWidth;
      });
    }
  }

  /// Handles tab changes and updates the indicator position.
  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });

    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: kDuration300ms,
      curve: Curves.easeInOut,
    );

    // Update indicator position after animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorPosition();
    });
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentTabIndex = index;
    });
    // Update indicator position when page changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicatorPosition();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final area = userProvider.user?['area'] as String?;

    // The Scaffold provides the basic structure of the visual interface.
    return Scaffold(
      backgroundColor: kWhite,
      body: SafeArea(
        // The Column lays out the header, tabs, and content vertically.
        child: Column(
          children: [
            // The AppHeaderContent is placed here so it remains persistent
            // and is shared across both the Search and My Feed screens.
            AppHeaderContent(
              area: area,
              horizontalPadding: kPaddingH24V16.horizontal / 1,
              verticalPadding: kSizedBoxH10,
              onNotificationPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              onCalendarPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MyScheduleScreen(),
                  ),
                );
              },
            ),
            const SizedBox(
              height: 2,
            ),
            // Verification Banner - shows if NIN or BVN is not verified
            const VerificationBanner(),
            // The NavigationTabsWidget controls which screen is shown below.
            // Tab 0: Search (shows MapHomeScreen)
            // Tab 1: My Feed (shows MyFeedScreen)
            NavigationTabsWidget(
              currentTabIndex: _currentTabIndex,
              tabBarKey: _tabBarKey,
              indicatorLeft: _indicatorLeft,
              indicatorWidth: _indicatorWidth,
              onTabChanged: _onTabChanged,
            ),
            // The Expanded widget ensures that the content view fills the
            // remaining available space.

            Expanded(
              // PageView is used to create a scrollable list of pages
              // with animated transitions.
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                physics:
                    const NeverScrollableScrollPhysics(), // Disable swipe gesture
                children: [
                  // Index 0: Search tab shows MapHomeScreen
                  const MapHomeScreen(),
                  // Index 1: My Feed tab shows MyFeedScreen
                  if (_isLoading)
                    const Center(child: CustomLoadingIndicator())
                  else if (_error != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else if (_currentPosition != null)
                    const MyFeedScreen()
                  else
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Something went wrong. Please try again.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
