import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cribs_arena/constants.dart';

class FeaturedPropertyCardSkeleton extends StatelessWidget {
  const FeaturedPropertyCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        width: 320,
        margin: kPaddingOnlyRight16,
        decoration: BoxDecoration(
          borderRadius: kRadius16,
          color: Colors.grey[300],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: kPaddingAll16,
              decoration: const BoxDecoration(
                color: kBlackOpacity03,
                borderRadius: kRadius16Bottom,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Skeleton.leaf(
                          child: Container(
                            width: 200,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: kRadius8,
                            ),
                          ),
                        ),
                        const SizedBox(height: kSizedBoxH4),
                        Skeleton.leaf(
                          child: Container(
                            width: 150,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: kRadius8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Skeleton.leaf(
                    child: Container(
                      width: 80,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: kRadius20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
