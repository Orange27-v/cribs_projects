// lib/screen/user/user_widgets/quick_search_tags_widget.dart
import 'package:flutter/material.dart';
import '../../../constants.dart'; // Adjust path as necessary
import 'package:cribs_arena/services/quick_search_service.dart';
import 'package:cribs_arena/models/property.dart';
import 'package:cribs_arena/screens/property/property_details_screen.dart';
import 'package:cribs_arena/widgets/widgets.dart';

class QuickSearchTagsWidget extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final int maxTags;

  const QuickSearchTagsWidget(
      {super.key, this.latitude, this.longitude, this.maxTags = 10});

  @override
  State<QuickSearchTagsWidget> createState() => _QuickSearchTagsWidgetState();
}

class _QuickSearchTagsWidgetState extends State<QuickSearchTagsWidget> {
  late final QuickSearchService _service;
  List<Property> _properties = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service = QuickSearchService();
    _loadProps();
  }

  @override
  void didUpdateWidget(covariant QuickSearchTagsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final latChanged = oldWidget.latitude != widget.latitude;
    final lonChanged = oldWidget.longitude != widget.longitude;
    if (latChanged || lonChanged) {
      _loadProps();
    }
  }

  Future<void> _loadProps() async {
    setState(() => _loading = true);
    try {
      final props = await _service.getTagProperties(
        latitude: widget.latitude,
        longitude: widget.longitude,
        max: widget.maxTags,
      );
      if (!mounted) return;
      setState(() {
        _properties = props;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _properties = const [];
        _loading = false;
      });
    }
  }

  String _labelFor(Property p) {
    String baseLabel;

    if (p.title.isNotEmpty && p.location.isNotEmpty) {
      baseLabel =
          '${p.title.split(',').first.trim()}, ${p.location.split(',').first.trim()}';
    } else if (p.type.isNotEmpty && p.location.isNotEmpty) {
      baseLabel = '${p.type}, ${p.location.split(',').first.trim()}';
    } else if (p.location.isNotEmpty) {
      baseLabel = p.location.split(',').first.trim();
    } else {
      baseLabel = p.title.isNotEmpty ? p.title : 'Property';
    }

    // Add distance if available
    if (p.distanceKm != null && p.distanceKm! > 0) {
      final distance = p.distanceKm! < 1
          ? '${(p.distanceKm! * 1000).toStringAsFixed(0)}m'
          : '${p.distanceKm!.toStringAsFixed(1)}km';
      return '$baseLabel • $distance';
    }

    return baseLabel;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const SizedBox(
        height: 20,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: kPaddingH16,
            child: SizedBox(
              height: 12,
              width: 12,
              child: CustomLoadingIndicator(strokeWidth: 2, size: 16),
            ),
          ),
        ),
      );
    }

    if (_properties.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 32,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: kPaddingH16,
        itemCount: _properties.length,
        itemBuilder: (context, index) {
          final p = _properties[index];
          final label = _labelFor(p);
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyDetailsScreen(property: p),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kPrimaryColor, width: 1),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}
