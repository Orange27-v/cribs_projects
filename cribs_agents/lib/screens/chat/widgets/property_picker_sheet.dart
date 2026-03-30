import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/models/property.dart';
import 'package:cribs_agents/services/property_service.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class PropertyPickerSheet extends StatefulWidget {
  final PropertyService propertyService;
  final Function(Property) onPropertySelected;

  const PropertyPickerSheet({
    super.key,
    required this.propertyService,
    required this.onPropertySelected,
  });

  @override
  State<PropertyPickerSheet> createState() => _PropertyPickerSheetState();
}

class _PropertyPickerSheetState extends State<PropertyPickerSheet> {
  List<Property> _properties = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.propertyService.getAgentProperties(
        status: 'Active',
        perPage: 50,
      );

      if (result['success'] == true) {
        setState(() {
          _properties = result['properties'] as List<Property>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load properties';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading properties: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: kGrey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kBlue50,
                    borderRadius: kRadius8,
                  ),
                  child: const Icon(Icons.share_rounded,
                      color: kPrimaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Share a Property',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: kBlack87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select a listing to share',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          color: kGrey600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: kGrey600),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: kGrey200),
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CustomLoadingIndicator(size: 30))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  size: 48, color: kRed.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                style: GoogleFonts.roboto(
                                    color: kGrey700, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _loadProperties,
                                style: TextButton.styleFrom(
                                  backgroundColor: kGrey100,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: kRadius8),
                                ),
                                child: Text('Retry',
                                    style: GoogleFonts.roboto(color: kBlack87)),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _properties.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: kGrey100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.home_work_outlined,
                                      size: 40, color: kGrey400),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No Active Listings',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: kBlack87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You have no active properties to share.',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: kGrey600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(20),
                            itemCount: _properties.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final property = _properties[index];
                              return PropertyPickerCard(
                                property: property,
                                onTap: () =>
                                    widget.onPropertySelected(property),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}

class PropertyPickerCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const PropertyPickerCard({
    super.key,
    required this.property,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        property.images?.isNotEmpty == true ? property.images!.first : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: kRadius8,
        child: Container(
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: kRadius8,
            border: Border.all(color: kGrey200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Property image
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  color: kGrey100,
                  child: imageUrl != null
                      ? Image.network(
                          getResolvedImageUrl(imageUrl, isProperty: true),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.image_not_supported_outlined,
                            size: 32,
                            color: kGrey400,
                          ),
                        )
                      : const Icon(
                          Icons.image_outlined,
                          size: 32,
                          color: kGrey400,
                        ),
                ),
              ),
              // Property details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        property.title,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kBlack87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 14, color: kGrey500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              property.location,
                              style: GoogleFonts.roboto(
                                fontSize: 13,
                                color: kGrey600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kBlue50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              property.listingType.toUpperCase(),
                              style: GoogleFonts.roboto(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ),
                          Text(
                            '₦${NumberFormat('#,###').format(property.price)}',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: kBlack87,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Share Icon Action
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: kGrey400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
