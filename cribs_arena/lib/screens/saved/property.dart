import 'package:flutter/material.dart';
import 'package:cribs_arena/models/property.dart'; // Import Property model
import 'package:cribs_arena/screens/property/widgets/property_summary_card.dart'; // Import PropertySummaryCard
import 'package:cribs_arena/screens/property/property_details_screen.dart'; // Import PropertyDetailsScreen

import '../../constants.dart';
import '../../widgets/widgets.dart';

class PropertyTab extends StatelessWidget {
  final List<Property> properties;
  final bool isLoading;
  final String error;
  final Function(Property) onRemove;
  final VoidCallback onRefresh;

  const PropertyTab({
    super.key,
    required this.properties,
    required this.isLoading,
    required this.error,
    required this.onRemove,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CustomLoadingIndicator());
    }

    if (error.isNotEmpty) {
      return NetworkErrorWidget(
        errorMessage: error,
        onRefresh: onRefresh,
      );
    }

    if (properties.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 150),
          const CircleImageContainer(
            imagePath: 'assets/images/magnifier.png',
            size: 100,
          ),
          const SizedBox(height: 20),
          const Text(
            'No saved properties yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Start exploring properties and save\nyour favorites here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: kGrey,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to property exploration screen
            },
            icon: const Icon(Icons.search, color: kWhite),
            label: const Text(
              'Explore',
              style: TextStyle(color: kWhite),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 15,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: properties.length,
      itemBuilder: (context, index) {
        final property = properties[index];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PropertyDetailsScreen(property: property),
              ),
            );
            onRefresh();
          },
          child: PropertySummaryCard(
              property: property, onRemove: onRemove, showRemoveIcon: true),
        );
      },
    );
  }
}
