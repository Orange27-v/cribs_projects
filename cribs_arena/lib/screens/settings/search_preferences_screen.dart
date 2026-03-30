import 'package:flutter/material.dart';

class SearchPreferencesScreen extends StatelessWidget {
  const SearchPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Preferences'),
      ),
      body: const Center(
        child: Text('Search Preferences Screen'),
      ),
    );
  }
}
