// lib/screens/user/user_widgets/agent_marker.dart
import 'dart:async';
import 'package:cribs_arena/helpers/chat_helper.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../constants.dart';

class AgentMarker extends StatefulWidget {
  final List<Agent> agents;
  final bool visible;
  final GoogleMapController? mapController;
  final Function(Agent)? onSelected;

  const AgentMarker({
    super.key,
    required this.agents,
    required this.visible,
    this.mapController,
    this.onSelected,
  });

  @override
  AgentMarkerState createState() => AgentMarkerState();
}

class AgentMarkerState extends State<AgentMarker>
    with SingleTickerProviderStateMixin {
  List<Agent> _agents = [];
  final Map<String, Offset> _positions = {};
  final Map<String, Agent> _agentCache = {};
  bool _visible = false;
  bool _positioned = false;
  late AnimationController _pulseController;
  late Animation<double> _pulse;
  bool _isUpdating = false;
  int _updateGeneration = 0; // Track update generations

  @override
  void initState() {
    super.initState();
    _agents = widget.agents;
    _visible = widget.visible;
    _buildAgentCache();
    _pulseController =
        AnimationController(vsync: this, duration: kDuration1500ms)
          ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: kPulseAnimationEnd).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _buildAgentCache() {
    _agentCache.clear();
    for (final agent in _agents) {
      final id = agent.id.toString();
      if (id.isNotEmpty) {
        _agentCache[id] = agent;
      }
    }
  }

  Future<void> setAgents(List<Agent> agents) async {
    if (!mounted) return;

    _agents = agents;
    _buildAgentCache();

    // Remove positions for agents that no longer exist
    _positions.removeWhere((key, value) => !_agentCache.containsKey(key));

    if (mounted) setState(() {});
  }

  void setVisibility(bool visible) {
    if (_visible == visible || !mounted) return;
    _visible = visible;
    if (mounted) setState(() {});
  }

  // Smooth update that transitions positions
  Future<void> updatePositionsSmooth(GoogleMapController controller) async {
    if (!mounted || _isUpdating) return;

    _isUpdating = true;
    _updateGeneration++;
    final currentGen = _updateGeneration;

    try {
      final Map<String, Offset> newPositions = {};

      // Calculate all positions in parallel
      final results = await Future.wait(
        _agents.map((agent) async {
          try {
            final pos = await _calcPosition(controller, agent);
            return MapEntry(agent.id.toString(), pos);
          } catch (e) {
            return MapEntry(agent.id.toString(), null);
          }
        }),
      );

      // Check if a newer update started
      if (!mounted || currentGen != _updateGeneration) return;

      // Collect valid positions
      for (final entry in results) {
        final value = entry.value;
        if (value != null && entry.key.isNotEmpty) {
          newPositions[entry.key] = value;
        }
      }

      // Update positions smoothly (keep existing, add/update new ones)
      if (mounted && currentGen == _updateGeneration) {
        for (final entry in newPositions.entries) {
          _positions[entry.key] = entry.value;
        }

        _positioned = _positions.isNotEmpty;

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Smooth update error: $e');
    } finally {
      if (currentGen == _updateGeneration) {
        _isUpdating = false;
      }
    }
  }

  // Full position update (used for initial setup)
  Future<void> updatePositions(GoogleMapController controller) async {
    if (!mounted || _isUpdating) return;

    _isUpdating = true;
    _updateGeneration++;
    final currentGen = _updateGeneration;

    try {
      final Map<String, Offset> newPositions = {};

      // Calculate all positions in parallel
      final results = await Future.wait(
        _agents.map((agent) async {
          try {
            final pos = await _calcPosition(controller, agent);
            return MapEntry(agent.id.toString(), pos);
          } catch (e) {
            return MapEntry(agent.id.toString(), null);
          }
        }),
      );

      // Check if a newer update started
      if (!mounted || currentGen != _updateGeneration) return;

      // Collect valid positions
      for (final entry in results) {
        final value = entry.value;
        if (value != null && entry.key.isNotEmpty) {
          newPositions[entry.key] = value;
        }
      }

      // Replace all positions
      if (mounted && currentGen == _updateGeneration) {
        _positions.clear();
        _positions.addAll(newPositions);
        _positioned = _positions.isNotEmpty;

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Position update error: $e');
    } finally {
      if (currentGen == _updateGeneration) {
        _isUpdating = false;
      }
    }
  }

  Future<Offset?> _calcPosition(
      GoogleMapController controller, Agent agent) async {
    final lat = agent.latitude;
    final lon = agent.longitude;
    if (lat == null || lon == null) return null;

    try {
      final screen = await controller.getScreenCoordinate(LatLng(lat, lon));
      return Offset(
        screen.x.toDouble() - 30.0, // kSize60 / 2 = 30
        screen.y.toDouble() - 30.0,
      );
    } catch (e) {
      return null;
    }
  }

  void _onTap(String id) {
    final agent = _agentCache[id];
    if (agent != null) {
      widget.onSelected?.call(agent);
    }
  }

  Widget _buildAgentMarker(String id, Offset pos) {
    final agent = _agentCache[id];
    if (agent == null) return const SizedBox.shrink();

    final totalSales = agent.totalSales ?? 0;
    final isOnline = agent.loginStatus == 1;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      width: kSize60,
      height: kSize60,
      child: GestureDetector(
        onTap: () => _onTap(id),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar with pulse animation
            Positioned(
              child: ScaleTransition(
                scale: _pulse,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kPrimaryColor,
                      width: 2.0,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: kRadius27,
                    backgroundColor: kWhite,
                    child: ClipOval(
                      child: Image(
                        image: _getAgentImageProvider(agent),
                        fit: BoxFit.cover,
                        width: kSize60,
                        height: kSize60,
                        errorBuilder: (context, error, stackTrace) {
                          // Show placeholder on error
                          return Image.asset(
                            'assets/images/default_profile.jpg',
                            fit: BoxFit.cover,
                            width: kSize60,
                            height: kSize60,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              strokeWidth: 2.0,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  kPrimaryColor),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Sales badge - only show if totalSales > 0
            if (totalSales > 0)
              Positioned(
                top: kPaddingTopNeg2,
                right: kPaddingRightNeg2,
                child: Container(
                  width: kSize24,
                  height: kSize24,
                  decoration: BoxDecoration(
                    color: kWhite,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: kPrimaryColor, width: kStrokeWidth1_5),
                    boxShadow: const [
                      BoxShadow(
                          color: kBlack26,
                          blurRadius: kBlurRadius4,
                          offset: kOffset02)
                    ],
                  ),
                  child: Center(
                    child: Text(
                      totalSales.toString(),
                      style: const TextStyle(
                          color: kPrimaryColor,
                          fontSize: kFontSize11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            // Online indicator - moved to top left
            if (isOnline)
              Positioned(
                top: kPaddingTopNeg2,
                left: kPaddingRightNeg2,
                child: Container(
                  width: kSize12,
                  height: kSize12,
                  decoration: BoxDecoration(
                    color: kGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: kWhite, width: kSizedBoxW2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getAgentImageProvider(Agent agent) {
    if (agent.profileImage.isEmpty) {
      debugPrint('Agent ${agent.id}: No profile image, using placeholder');
      return const AssetImage('assets/images/default_profile.jpg');
    }

    final fullUrl = ChatHelper.getFullImageUrl(agent.profileImage);
    debugPrint('Agent ${agent.id}: Resolved URL: $fullUrl');
    return NetworkImage(fullUrl);
  }

  @override
  Widget build(BuildContext context) {
    // Only render when we have positions and should be visible
    if (!_positioned || !_visible || !mounted) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: _positions.entries
          .map((entry) => _buildAgentMarker(entry.key, entry.value))
          .toList(),
    );
  }
}
