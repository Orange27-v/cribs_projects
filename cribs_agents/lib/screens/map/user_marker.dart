import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../constants.dart';

/// Efficient marker widget that manages ALL user markers in a single widget
class UserMarker extends StatefulWidget {
  final List<Map<String, dynamic>> users;
  final bool visible;
  final GoogleMapController? mapController;
  final Function(Map<String, dynamic>)? onSelected;

  const UserMarker({
    super.key,
    required this.users,
    required this.visible,
    this.mapController,
    this.onSelected,
  });

  @override
  UserMarkerState createState() => UserMarkerState();
}

class UserMarkerState extends State<UserMarker>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _users = [];
  final Map<String, Offset> _positions = {};
  final Map<String, Map<String, dynamic>> _userCache = {};
  bool _visible = false;
  bool _positioned = false;
  late AnimationController _pulseController;
  late Animation<double> _pulse;
  bool _isUpdating = false;
  int _updateGeneration = 0;

  @override
  void initState() {
    super.initState();
    _users = widget.users;
    _visible = widget.visible;
    _buildUserCache();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 1.0, end: 1.08).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    if (kDebugMode) {
      debugPrint(
          'USER_MARKER: Initialized with ${_users.length} users, visible: $_visible');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _buildUserCache() {
    _userCache.clear();
    for (final user in _users) {
      final id = user['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        _userCache[id] = user;
      }
    }
    if (kDebugMode) {
      debugPrint('USER_MARKER: Built cache with ${_userCache.length} users');
    }
  }

  Future<void> setUsers(List<Map<String, dynamic>> users) async {
    if (!mounted) return;
    if (kDebugMode) {
      debugPrint('USER_MARKER: setUsers called with ${users.length} users');
    }

    setState(() {
      _users = users;
      _buildUserCache();
      // Remove positions for users that no longer exist
      _positions.removeWhere((key, value) => !_userCache.containsKey(key));
    });
  }

  void setVisibility(bool visible) {
    if (_visible == visible || !mounted) return;
    if (kDebugMode) {
      debugPrint('USER_MARKER: Visibility changed from $_visible to $visible');
    }
    setState(() {
      _visible = visible;
    });
  }

  /// Smooth update that transitions positions (for camera moves)
  Future<void> updatePositionsSmooth(GoogleMapController controller) async {
    if (!mounted || _isUpdating || !_visible) return;

    _isUpdating = true;
    _updateGeneration++;
    final currentGen = _updateGeneration;

    try {
      final Map<String, Offset> newPositions = {};

      // Calculate all positions in parallel
      final results = await Future.wait(
        _users.map((user) async {
          try {
            final pos = await _calcPosition(controller, user);
            return MapEntry(user['id']?.toString() ?? '', pos);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  'Error calculating position for user ${user['id']}: $e');
            }
            return MapEntry(user['id']?.toString() ?? '', null);
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

      if (kDebugMode) {
        debugPrint(
            'USER_MARKER: Smooth update calculated ${newPositions.length} valid positions');
      }

      // Update positions smoothly
      if (mounted && currentGen == _updateGeneration) {
        setState(() {
          for (final entry in newPositions.entries) {
            _positions[entry.key] = entry.value;
          }
          _positioned = _positions.isNotEmpty;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Smooth update error: $e');
      }
    } finally {
      if (currentGen == _updateGeneration) {
        _isUpdating = false;
      }
    }
  }

  /// Full position update (used for initial setup)
  Future<void> updatePositions(GoogleMapController controller) async {
    if (!mounted || _isUpdating) return;
    if (kDebugMode) {
      debugPrint(
          'USER_MARKER: updatePositions (Full) called for ${_users.length} users');
    }

    _isUpdating = true;
    _updateGeneration++;
    final currentGen = _updateGeneration;

    try {
      final Map<String, Offset> newPositions = {};

      // Calculate all positions in parallel
      final results = await Future.wait(
        _users.map((user) async {
          try {
            final pos = await _calcPosition(controller, user);
            return MapEntry(user['id']?.toString() ?? '', pos);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                  'Error calculating position for user ${user['id']}: $e');
            }
            return MapEntry(user['id']?.toString() ?? '', null);
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
        setState(() {
          _positions.clear();
          _positions.addAll(newPositions);
          _positioned = _positions.isNotEmpty;
        });

        if (kDebugMode) {
          debugPrint(
              'USER_MARKER: Positions updated. Total: ${_positions.length}, Positioned: $_positioned, Visible: $_visible');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Position update error: $e');
      }
    } finally {
      if (currentGen == _updateGeneration) {
        _isUpdating = false;
      }
    }
  }

  Future<Offset?> _calcPosition(
      GoogleMapController controller, Map<String, dynamic> user) async {
    final lat = user['lat'];
    final lon = user['lon'];

    if (lat == null || lon == null) {
      if (kDebugMode) {
        debugPrint('USER_MARKER: Missing lat/lon for user ${user['id']}');
      }
      return null;
    }

    try {
      final latDouble =
          (lat is num) ? lat.toDouble() : double.tryParse(lat.toString());
      final lonDouble =
          (lon is num) ? lon.toDouble() : double.tryParse(lon.toString());

      if (latDouble == null || lonDouble == null) {
        if (kDebugMode) {
          debugPrint(
              'USER_MARKER: Invalid lat/lon values for user ${user['id']}');
        }
        return null;
      }

      final screen =
          await controller.getScreenCoordinate(LatLng(latDouble, lonDouble));

      // Simple calculation without platform-specific adjustments
      // The marker is 50x50, so subtract 25 to center it
      final offset = Offset(
        screen.x.toDouble() - 25.0,
        screen.y.toDouble() - 25.0,
      );

      if (kDebugMode) {
        debugPrint(
            'USER_MARKER: Position for ${user['name']}: screen(${screen.x}, ${screen.y}) -> offset(${offset.dx}, ${offset.dy})');
      }

      return offset;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error converting coordinates for user ${user['name']}: $e');
      }
      return null;
    }
  }

  void _onTap(String id) {
    final user = _userCache[id];
    if (user != null) {
      if (kDebugMode) {
        debugPrint('USER_MARKER: User tapped: ${user['name']}');
      }
      widget.onSelected?.call(user);
    }
  }

  Widget _buildUserMarker(String id, Offset pos) {
    final user = _userCache[id];
    if (user == null) return const SizedBox.shrink();

    final isOnline = user['isOnline'] == true;

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () => _onTap(id),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar with pulse animation for online users
            ScaleTransition(
              scale: isOnline ? _pulse : const AlwaysStoppedAnimation(1.0),
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOnline ? Colors.green : Colors.blue,
                    width: 2.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isOnline ? Colors.green : Colors.blue)
                          .withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 23,
                  backgroundImage: _getUserImageProvider(user),
                  backgroundColor: kWhite,
                  onBackgroundImageError: (exception, stackTrace) {
                    if (kDebugMode) {
                      debugPrint(
                          'USER_MARKER: Failed to load image for ${user['name']}: $exception');
                    }
                  },
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
            // Online indicator
            if (isOnline)
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: kWhite, width: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  ImageProvider _getUserImageProvider(Map<String, dynamic> user) {
    final String? imagePath = user['image']?.toString();

    if (imagePath == null || imagePath.isEmpty) {
      return const AssetImage('assets/images/default_profile.jpg');
    }

    // If it's already a full HTTP/HTTPS URL, use it directly
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return NetworkImage(imagePath);
    }

    // For relative paths, construct full URL
    String fullImageUrl;
    if (imagePath.startsWith('storage/')) {
      fullImageUrl = '$kMainBaseUrl$imagePath';
    } else if (imagePath.startsWith('profile_pictures/')) {
      fullImageUrl = '$kMainBaseUrl/storage/$imagePath';
    } else if (imagePath.startsWith('/')) {
      fullImageUrl = '$kMainBaseUrl${imagePath.substring(1)}';
    } else {
      fullImageUrl = '$kMainBaseUrl/storage/$imagePath';
    }

    if (kDebugMode) {
      debugPrint('USER_MARKER: Image URL for ${user['name']}: $fullImageUrl');
    }
    return NetworkImage(fullImageUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      debugPrint(
          'USER_MARKER: build() - positioned: $_positioned, visible: $_visible, users: ${_users.length}, positions: ${_positions.length}');
    }

    // Only render when we have positions and should be visible
    if (!_positioned || !_visible || _positions.isEmpty) {
      if (kDebugMode) {
        debugPrint(
            'USER_MARKER: Not rendering. positioned: $_positioned, visible: $_visible, positions: ${_positions.length}');
      }
      return const SizedBox.shrink();
    }

    if (kDebugMode) {
      debugPrint('USER_MARKER: Rendering ${_positions.length} markers');
    }

    return Stack(
      children: _positions.entries
          .map((entry) => _buildUserMarker(entry.key, entry.value))
          .toList(),
    );
  }
}
