import 'package:cribs_arena/screens/chat/chat_list_screen.dart';
import 'package:cribs_arena/screens/components/bottom_navigation_bar.dart';
import 'package:cribs_arena/screens/profile/profile_screen.dart';
import 'package:cribs_arena/screens/saved/saved_property_screen.dart';
import 'package:cribs_arena/screens/user/home_screen.dart';
import 'package:flutter/material.dart';

import 'package:cribs_arena/provider/user_provider.dart';
import 'package:provider/provider.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchUserProfile();
    });
  }

  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SavedPropertyScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

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
