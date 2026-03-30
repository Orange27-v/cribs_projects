import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cribs_arena/constants.dart';

class PropertySummaryCardSkeleton extends StatelessWidget {
  const PropertySummaryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        color: kGrey100Opacity05,
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          // Balanced image height - not too tall, not too small
          final imageHeight = width * 0.52;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // image area
              Skeleton.replace(
                width: double.infinity,
                height: imageHeight,
                child: Container(color: Colors.grey[300]),
              ),

              // details area
              Padding(
                padding: kPaddingAll12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // name
                    Skeleton.leaf(
                      child: Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxWidth: width * 0.8,
                        ),
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: kRadius8,
                        ),
                      ),
                    ),
                    const SizedBox(height: kSizedBoxH6),

                    // location row
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            color: kPrimaryColor, size: kIconSize14),
                        const SizedBox(width: kSizedBoxW6),
                        Expanded(
                          child: Skeleton.leaf(
                            child: Container(
                              height: 16,
                              constraints: BoxConstraints(
                                maxWidth: width * 0.6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: kRadius8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: kSizedBoxH10),

                    // stats - Scrollable Row to prevent overflow on very small devices
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics:
                          const NeverScrollableScrollPhysics(), // Skeleton doesn't need to scroll
                      child: Row(
                        children: [
                          _buildStatItemSkeleton(),
                          const SizedBox(width: kSizedBoxW10),
                          _buildStatItemSkeleton(),
                          const SizedBox(width: kSizedBoxW10),
                          _buildStatItemSkeleton(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatItemSkeleton() {
    return Skeleton.leaf(
      child: Container(
        width: 40,
        height: 16,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: kRadius8,
        ),
      ),
    );
  }
}
