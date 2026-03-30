import 'package:cribs_agents/screens/chat/chat_list_screen.dart';
import 'package:cribs_agents/screens/components/bottom_navigation_bar.dart';
import 'package:cribs_agents/screens/profile/profile_screen.dart';
import 'package:cribs_agents/screens/agents/home_screen.dart';
import 'package:cribs_agents/screens/leads/leads_screen.dart';
import 'package:cribs_agents/screens/properties/properties_screen.dart';
import 'package:cribs_agents/provider/agent_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  final double userLatitude;
  final double userLongitude;

  const MainLayout({
    super.key,
    required this.userLatitude,
    required this.userLongitude,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProvider>().fetchAgentProfile();
    });
    _screens = [
      HomeScreen(
        userLatitude: widget.userLatitude,
        userLongitude: widget.userLongitude,
      ),
      const LeadsScreen(),
      const PropertiesScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
