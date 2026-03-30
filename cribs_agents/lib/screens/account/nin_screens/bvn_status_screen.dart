import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/services/bvn_service.dart';
import 'package:cribs_agents/screens/account/widgets/pending_status_widget.dart';
import 'package:cribs_agents/screens/account/widgets/bvn_status_widget.dart';
import 'package:cribs_agents/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:cribs_agents/provider/agent_provider.dart';
import 'package:cribs_agents/services/auth_service.dart';
import 'package:pusher_channels_flutter/pusher_channels_flutter.dart';
import 'package:http/http.dart' as http;

class BvnStatusScreen extends StatefulWidget {
  final String verificationId;

  const BvnStatusScreen({super.key, required this.verificationId});

  @override
  State<BvnStatusScreen> createState() => _BvnStatusScreenState();
}

class _BvnStatusScreenState extends State<BvnStatusScreen> {
  Map<String, dynamic>? _verificationStatus;
  bool _isLoading = true;
  String? _errorMessage;
  final PusherChannelsFlutter _pusher = PusherChannelsFlutter.getInstance();
  int? _agentId; // To store the current agent's ID
  Timer? _pollingTimer; // Timer for polling status updates
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initPusher(); // Initialize Pusher for real-time updates
  }

  @override
  void dispose() {
    _pollingTimer?.cancel(); // Cancel polling timer
    if (_agentId != null) {
      _pusher.unsubscribe(channelName: 'private-agent.$_agentId');
    }
    _pusher.disconnect();
    super.dispose();
  }

  Future<void> _refreshUserProfile() async {
    try {
      debugPrint("Refreshing agent profile after BVN verification...");
      await Provider.of<AgentProvider>(context, listen: false).refreshProfile();
      if (mounted) {
        debugPrint("Agent profile refreshed.");
      }
    } catch (e) {
      debugPrint("Failed to refresh agent profile: $e");
    }
  }

  Future<void> _initPusher() async {
    final agentProvider = Provider.of<AgentProvider>(context, listen: false);
    _agentId = agentProvider.agent?.id;

    if (_agentId == null) {
      if (mounted) {
        SnackbarHelper.showError(
            context, 'Agent not logged in. Cannot listen for updates.',
            position: FlashPosition.bottom);
        setState(() {
          _isLoading = false;
          _errorMessage = 'Agent not logged in.';
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
                // Optional: show minimal feedback or handle retry silently
              }
            }
          },
          onError: (message, code, e) {
            if (mounted) {
              debugPrint('Pusher connection error: $message');
            }
          });

      await _pusher.subscribe(
          channelName: 'private-agent.$_agentId',
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
                      _pusher.unsubscribe(
                          channelName: 'private-agent.$_agentId');
                      _pusher.disconnect();

                      if (verification['status'] == 'verified') {
                        _refreshUserProfile();
                      }
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
      final bvnService = BvnService(); // Renamed from _bvnService
      final status = await bvnService.getBvnStatus(widget.verificationId);
      if (mounted) {
        setState(() {
          _verificationStatus = status;
          _isLoading = false;
          _errorMessage = null;
        });

        if (status['status'] != 'pending') {
          // Stop polling if we have a final status
          _pollingTimer?.cancel();

          if (_agentId != null) {
            _pusher.unsubscribe(channelName: 'private-agent.$_agentId');
          }
          _pusher.disconnect();

          if (status['status'] == 'verified') {
            _refreshUserProfile();
          }
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
    // Navigate back to the verification entry screen
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('BVN VERIFICATION STATUS'),
      ),
      body: Padding(
        padding: kPaddingAll16,
        child: _isLoading || _verificationStatus == null
            ? PendingStatusWidget(
                message: _errorMessage ?? 'Checking BVN verification status...')
            : BvnStatusWidget(
                responsePayload: _verificationStatus!,
                onRetry: _handleRetry,
              ),
      ),
    );
  }
}
