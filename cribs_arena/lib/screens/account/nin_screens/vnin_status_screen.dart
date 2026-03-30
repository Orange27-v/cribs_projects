import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/widgets/widgets.dart';
import 'package:cribs_arena/services/vnin_service.dart';
import 'package:cribs_arena/screens/account/widgets/pending_status_widget.dart';
import 'package:cribs_arena/screens/account/widgets/vnin_status_widget.dart';
import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:cribs_arena/provider/user_provider.dart';
import 'package:cribs_arena/services/auth_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;

class VninStatusScreen extends StatefulWidget {
  final String verificationId;

  const VninStatusScreen({super.key, required this.verificationId});

  @override
  State<VninStatusScreen> createState() => _VninStatusScreenState();
}

class _VninStatusScreenState extends State<VninStatusScreen> {
  Map<String, dynamic>? _verificationStatus;
  bool _isLoading = true;
  String? _errorMessage;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  int? _userId; // To store the current user's ID
  Timer? _pollingTimer; // Timer for polling status updates
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initPusher();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Cancel polling timer
    if (_userId != null) {
      _pusher.unsubscribe(channelName: 'private-user.$_userId');
    }
    _pusher.disconnect();
    super.dispose();
  }

  Future<void> _initPusher() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _userId = userProvider.user?['id'];

    if (_userId == null) {
      if (mounted) {
        SnackbarHelper.showError(
            context, 'User not logged in. Cannot listen for updates.',
            position: FlashPosition.bottom);
        setState(() {
          _isLoading = false;
          _errorMessage = 'User not logged in.';
        });
      }
      return;
    }

    // Start with initial fetch
    await _fetchInitialStatus();

    // Start polling for status updates (every 3 seconds)
    _startPolling();

    // Optional: Still try to connect Pusher for real-time updates
    _initPusherConnection();
  }

  void _startPolling() {
    // Poll every 3 seconds while status is pending
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // Only poll if status is still pending
      if (_verificationStatus?['status'] == 'pending') {
        await _fetchInitialStatus();
      } else {
        // Stop polling once we have a final status
        timer.cancel();
      }
    });
  }

  Future<void> _initPusherConnection() async {
    try {
      await _pusher.init(
          apiKey: dotenv.env['PUSHER_APP_KEY']!,
          cluster: dotenv.env['PUSHER_APP_CLUSTER']!,
          onAuthorizer:
              (String channelName, String socketId, dynamic options) async {
            final token = await _authService.getToken();
            final response = await http.post(
              Uri.parse('${dotenv.env['APP_URL']}/broadcasting/auth'),
              headers: {
                'Content-Type': 'application/x-www-form-urlencoded',
                'Authorization': 'Bearer $token',
              },
              body: {
                'socket_id': socketId,
                'channel_name': channelName,
              },
            );
            if (response.statusCode == 200) {
              return jsonDecode(response.body);
            } else {
              throw Exception("Failed to authorize: ${response.statusCode}");
            }
          },
          onConnectionStateChange: (currentState, previousState) {
            debugPrint("Connection state: $currentState");
            if (currentState == 'DISCONNECTED') {
              if (mounted) {
                SnackbarHelper.showError(
                    context, 'Disconnected from real-time updates.',
                    position: FlashPosition.bottom);
              }
            }
          },
          onError: (message, code, e) {
            debugPrint('Pusher connection error: $message');
          });

      await _pusher.subscribe(
          channelName: 'private-user.$_userId',
          onEvent: (event) {
            if (event.eventName == 'verification.updated') {
              if (event.data != null) {
                dynamic decodedData;
                if (event.data is String) {
                  decodedData = jsonDecode(event.data);
                } else {
                  decodedData = event.data;
                }

                final verification = decodedData['verification'];
                if (verification != null &&
                    verification['verification_id'] == widget.verificationId) {
                  if (mounted) {
                    setState(() {
                      _verificationStatus = verification;
                      _isLoading = false;
                      _errorMessage = null;
                    });

                    // Stop polling since we got real-time update
                    _pollingTimer?.cancel();

                    if (verification['status'] != 'pending') {
                      _pusher.unsubscribe(channelName: 'private-user.$_userId');
                      _pusher.disconnect();
                    }
                    SnackbarHelper.showSuccess(context,
                        'Verification status updated to: ${verification['status']}',
                        position: FlashPosition.bottom);
                  }
                }
              }
            }
          });

      await _pusher.connect();
    } catch (e) {
      debugPrint('Pusher initialization failed: $e');
      // Continue with polling even if Pusher fails
    }
  }

  Future<void> _fetchInitialStatus() async {
    try {
      final vninService = VninService(); // Renamed from _vninService
      final status = await vninService.getVninStatus(widget.verificationId);
      if (mounted) {
        setState(() {
          _verificationStatus = status;
          _isLoading = false;
          _errorMessage = null;
        });

        if (status['status'] != 'pending') {
          // Stop polling if we have a final status
          _pollingTimer?.cancel();

          if (_userId != null) {
            _pusher.unsubscribe(channelName: 'private-user.$_userId');
          }
          _pusher.disconnect();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        SnackbarHelper.showError(context, _errorMessage!,
            position: FlashPosition.bottom);
      }
    }
  }

  void _handleRetry() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verificationStatus = null;
    });
    _initPusher(); // Re-initialize Pusher and fetch status
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('VNIN VERIFICATION STATUS'),
      ),
      body: Padding(
        padding: kPaddingAll16,
        child: _isLoading || _verificationStatus == null
            ? PendingStatusWidget(
                message:
                    _errorMessage ?? 'Checking vNIN verification status...')
            : VninStatusWidget(
                responsePayload: _verificationStatus!,
                onRetry: _handleRetry,
              ),
      ),
    );
  }
}
