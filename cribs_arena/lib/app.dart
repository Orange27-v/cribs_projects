import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/screens/chat/chat_list_screen.dart';
import 'package:cribs_arena/screens/splash/splash_screen.dart';
import 'package:cribs_arena/screens/no_internet/no_internet_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/screens/notification/notifications_screen.dart'; // Import NotificationsScreen
import 'package:cribs_arena/main.dart'
    as app_main; // Import for routeObserver access

class CribsArenaApp extends StatelessWidget {
  final GlobalKey<NavigatorState>
      navigatorKey; // Accept navigatorKey as a parameter

  const CribsArenaApp(
      {super.key, required this.navigatorKey}); // Update constructor

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // Use the passed navigatorKey
          navigatorObservers: [app_main.routeObserver], // Add RouteObserver
          title: 'Cribs Arena',
          debugShowCheckedModeBanner: true,
          theme: ThemeData(
            primarySwatch: Colors.indigo,
            scaffoldBackgroundColor: kGrey100,
            textTheme: GoogleFonts.robotoTextTheme(
              Theme.of(context).textTheme,
            ),
          ),
          builder: (context, child) {
            // Wrap the app in a Builder to ensure proper context for plugins
            return child ?? const SizedBox.shrink();
          },
          home: const SplashScreen(),
          routes: {
            '/chat': (context) => const ChatListScreen(),
            '/notifications': (context) =>
                const NotificationsScreen(), // New route
            '/no-internet': (context) => const NoInternetScreen(),
            // Placeholder routes for deep linking
            '/booking_details': (context) =>
                const PlaceholderScreen(title: 'Booking Details'),
            '/inspection_details': (context) =>
                const PlaceholderScreen(title: 'Inspection Details'),
            '/property_details': (context) =>
                const PlaceholderScreen(title: 'Property Details'),
            '/transaction_details': (context) =>
                const PlaceholderScreen(title: 'Transaction Details'),
          },
        );
      },
    );
  }
}

// Placeholder screen for demonstration
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('This is the $title screen.'),
      ),
    );
  }
}
