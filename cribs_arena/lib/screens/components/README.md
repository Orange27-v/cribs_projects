# Reusable Components

This directory contains reusable UI components that can be used across different screens in the Cribs Arena app.

## Components

### AppHeader
A customizable app header component that displays the app logo, name, location, and optional actions.

**Features:**
- Customizable app name and location
- Optional notification bell with tap callback
- Custom leading widget support
- Custom actions list support
- Logo tap callback
- Consistent styling with the app design system

### CustomBottomNavigationBar
A reusable bottom navigation bar component with four main sections.

**Features:**
- Four navigation items: Discover, Saved, Chat, Profile
- Visual selection indicators
- Customizable icons and labels
- Smooth animations and transitions

## Usage

### Importing Components

You can import components individually or use the index file:

```dart
// Individual imports
import 'screens/components/app_header.dart';
import 'screens/components/bottom_navigation_bar.dart';

// Or use the index file (recommended)
import 'screens/components/index.dart';
```

### Example Usage

```dart
import 'package:flutter/material.dart';
import 'screens/components/index.dart';

class MyScreen extends StatefulWidget {
  @override
  _MyScreenState createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          AppHeader(
            appName: 'My App',
            location: 'New York, NY',
            onNotificationTap: () => print('Notification tapped'),
          ),
          Expanded(
            child: YourContent(),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
```

## Design System

All components follow the app's design system defined in `lib/constants.dart`:

- **Primary Color**: `#006BC2` (Blue)
- **Background**: White
- **Text Colors**: Black, Black54 for secondary text
- **Border Radius**: Various predefined values (4, 12, 16, 24, 32)
- **Shadows**: Subtle shadows for depth and elevation

## Adding New Components

When adding new reusable components:

1. Create the component file in this directory
2. Add the export to `index.dart`
3. Update this README with documentation
4. Follow the existing naming conventions and design patterns 