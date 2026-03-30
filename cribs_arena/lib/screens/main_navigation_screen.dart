import 'package:flutter/material.dart';
import 'package:cribs_arena/screens/user/home_screen.dart';
import 'package:cribs_arena/screens/saved/saved_property_screen.dart';
import 'package:cribs_arena/screens/chat/chat_list_screen.dart';
import 'package:cribs_arena/screens/profile/profile_screen.dart';
import 'package:cribs_arena/screens/components/bottom_navigation_bar.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const SavedPropertyScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
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
        onTap: _onItemTapped,
      ),
    );
  }
}
