import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../screens/no_internet/no_internet_screen.dart';

/// Service to monitor internet connectivity and automatically navigate
/// to NoInternetScreen when connection is lost
class ConnectivityService {
  final GlobalKey<NavigatorState> navigatorKey;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isOnNoInternetScreen = false;
  bool _hasInternet = true;

  ConnectivityService(this.navigatorKey);

  /// Initialize the connectivity monitoring
  Future<void> initialize() async {
    // Check initial connectivity
    final List<ConnectivityResult> result =
        await _connectivity.checkConnectivity();
    _updateConnectionStatus(result);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        // Handle errors silently
      },
    );
  }

  /// Update connection status and navigate accordingly
  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // Check if any result indicates connectivity
    final bool hasConnection = results.any((result) =>
        result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet);

    if (!hasConnection && !_isOnNoInternetScreen) {
      // No internet and not already on the no internet screen
      _hasInternet = false;
      _navigateToNoInternetScreen();
    } else if (hasConnection && _isOnNoInternetScreen) {
      // Internet restored and currently on no internet screen
      _hasInternet = true;
      _navigateBack();
    } else if (hasConnection) {
      _hasInternet = true;
    }
  }

  /// Navigate to the NoInternetScreen
  void _navigateToNoInternetScreen() {
    _isOnNoInternetScreen = true;

    // Use a slight delay to ensure the navigation context is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      final NavigatorState? navigator = navigatorKey.currentState;
      if (navigator != null && navigator.mounted) {
        // Push the NoInternetScreen and remove all previous routes
        navigator.push(
          MaterialPageRoute(
            builder: (context) => const NoInternetScreen(),
            settings: const RouteSettings(name: '/no-internet'),
          ),
        );
      }
    });
  }

  /// Navigate back from NoInternetScreen when connection is restored
  void _navigateBack() {
    _isOnNoInternetScreen = false;

    Future.delayed(const Duration(milliseconds: 100), () {
      final NavigatorState? navigator = navigatorKey.currentState;
      if (navigator != null && navigator.mounted) {
        // Simply pop the NoInternetScreen to return to the previous state
        navigator.pop();
      }
    });
  }

  /// Check if currently has internet connection
  bool get hasInternet => _hasInternet;

  /// Check if currently on no internet screen
  bool get isOnNoInternetScreen => _isOnNoInternetScreen;

  /// Dispose the service and cancel subscriptions
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
