import 'package:cribs_agents/screens/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import '../../constants.dart';
import '../components/app_header_content.dart';
import 'package:cribs_agents/screens/schedule/schedule_screen.dart';
import 'map_home_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'dashboard_tabs.dart';

class HomeScreen extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;

  const HomeScreen({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [const MapHomeScreen(), const DashboardScreen()];
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: kWhite,
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: _screens),
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                color: kWhite,
                child: SafeArea(
                  bottom: false,
                  child: AppHeaderContent(
                    horizontalPadding: 0.0,
                    verticalPadding: kPaddingV10.vertical,
                    onNotificationPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationScreen(),
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
                ),
              ),
              SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DashboardTabs(
                      selectedIndex: _selectedIndex,
                      onTabSelected: _onTabSelected,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
