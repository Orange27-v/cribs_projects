import 'package:cribs_arena/models/agent.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../constants.dart';
import 'map_screen.dart';
import 'dart:io' show Platform;

class MapSectionWidget extends StatelessWidget {
  final MapController? controller;
  final List<Agent> agents;
  final Function(Agent agent)? onAgentSelected;
  final Function(LatLng)? onMapMoved;
  final LatLng initialCenter;

  const MapSectionWidget({
    super.key,
    this.controller,
    this.agents = const [],
    this.onAgentSelected,
    this.onMapMoved,
    required this.initialCenter,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate height with platform considerations
    final double mapHeight =
        MediaQuery.of(context).size.height * kMapHeightMultiplier;
    final double minHeight =
        Platform.isAndroid ? kAndroidMinMapHeight : kIOSMinMapHeight;
    final double finalHeight = mapHeight < minHeight ? minHeight : mapHeight;

    return Container(
      margin: kPaddingAll16,
      height: finalHeight,
      decoration: BoxDecoration(
        color: kMapBackgroundColor,
        borderRadius: kRadius12,
        border: Border.all(color: kGrey400, width: kSizedBoxH1),
      ),
      child: ClipRRect(
        borderRadius: kRadius12,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Provide exact dimensions to MapScreen
            return SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: MapScreen(
                controller: controller,
                agents: agents,
                onAgentSelected: onAgentSelected,
                onMapMoved: onMapMoved,
                initialCenter: initialCenter,
              ),
            );
          },
        ),
      ),
    );
  }
}
