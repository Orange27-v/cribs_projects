import 'package:flutter/material.dart';
import '../../../../constants.dart';

class MapIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const MapIconButton({super.key, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kWhite,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, color: kPrimaryColor, size: 18),
        ),
      ),
    );
  }
}

class MapZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapZoomControls(
      {super.key, required this.onZoomIn, required this.onZoomOut});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kWhite,
      borderRadius: kRadius20,
      elevation: 3,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            borderRadius: kRadius20Top,
            onTap: onZoomIn,
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.add, color: kPrimaryColor, size: 18),
            ),
          ),
          Container(height: 1, width: 20, color: kGrey400),
          InkWell(
            borderRadius: kRadius20Bottom,
            onTap: onZoomOut,
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.remove, color: kPrimaryColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}
