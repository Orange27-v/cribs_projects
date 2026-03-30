import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cribs_arena/constants.dart';

class PropertyListItemSkeleton extends StatelessWidget {
  const PropertyListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        height: kSizedBoxH120,
        decoration: const BoxDecoration(
          color: kGrey100Opacity09,
          borderRadius: kRadius8,
          boxShadow: [
            BoxShadow(
              color: kBlackOpacity001,
              blurRadius: kBlurRadius16,
              offset: kOffset04,
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // LEFT IMAGE
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: kRadius8,
                child: Skeleton.replace(
                  width: double.infinity,
                  height: double.infinity,
                  child: Container(color: Colors.grey[300]),
                ),
              ),
            ),

            // RIGHT CONTENT
            Expanded(
              flex: 3,
              child: Padding(
                padding: kPaddingAll12,

                /// FIX: let the column expand to full width
                child: Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Skeleton.leaf(
                            child: Container(
                              width: 60,
                              height: 20,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                borderRadius: kRadius20,
                              ),
                            ),
                          ),
                          Skeleton.leaf(
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: const BoxDecoration(
                                color: Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: kSizedBoxH8),

                      // TITLE
                      Text(
                        'Property Title Placeholder',
                        style: const TextStyle(
                            fontSize: kFontSize14, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: kSizedBoxH4),

                      // LOCATION
                      Text(
                        'Location Placeholder',
                        style: const TextStyle(
                            fontSize: kFontSize12, fontWeight: FontWeight.w400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: kSizedBoxH8),

                      // BOTTOM ROW
                      Row(
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Skeleton.leaf(
                                  child: Container(
                                    width: 40,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: kRadius8,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: kSizedBoxW12),
                                Skeleton.leaf(
                                  child: Container(
                                    width: 40,
                                    height: 16,
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      borderRadius: kRadius8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '₦000K',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: kFontSize16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
