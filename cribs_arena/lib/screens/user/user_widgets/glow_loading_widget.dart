import 'package:flutter/material.dart';

class LocationPulseWidget extends StatefulWidget {
  final bool isVisible;
  final Color pulseColor;
  final double size;

  const LocationPulseWidget({
    super.key,
    required this.isVisible,
    this.pulseColor = Colors.lightBlue,
    this.size = 200.0, // overall radius
  });

  @override
  _LocationPulseWidgetState createState() => _LocationPulseWidgetState();
}

class _LocationPulseWidgetState extends State<LocationPulseWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Expanding glow circles
            for (int i = 3; i >= 1; i--)
              _buildRippleCircle(
                scale: (1 - (_controller.value + i * 0.3) % 1),
              ),
            // Central pin
            child!,
          ],
        );
      },
      // Central marker like in your image
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRippleCircle({required double scale}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.pulseColor.withValues(alpha: 0.9 * (1 - scale)),
          border: Border.all(
            color: widget.pulseColor.withValues(alpha: 0.9),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
