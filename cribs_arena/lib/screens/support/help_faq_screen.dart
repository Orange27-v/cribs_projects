import 'package:flutter/material.dart';

class HelpFaqScreen extends StatelessWidget {
  const HelpFaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help and FAQ'),
      ),
      body: const Center(
        child: Text('Help and FAQ Screen'),
      ),
    );
  }
}
