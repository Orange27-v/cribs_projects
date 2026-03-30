import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cribs_arena/constants.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class PropertyDetailsScreenSkeleton extends StatelessWidget {
  const PropertyDetailsScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Scaffold(
        backgroundColor: kWhite,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: kSizedBoxH4),
              _buildImageSlider(),
              const SizedBox(height: kSizedBoxH12),
              _buildPageIndicator(),
              _buildContent(),
            ],
          ),
        ),
        bottomNavigationBar: _buildBottomButtons(),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: kPaddingFromLTRB16_16_16_12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton.leaf(
            child: Container(
              width: 80,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: kRadius8,
              ),
            ),
          ),
          const SizedBox(height: kSizedBoxH16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Skeleton.leaf(
                child: Container(
                  width: 200,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: kRadius8,
                  ),
                ),
              ),
              Skeleton.leaf(
                child: Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: kRadius8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSlider() {
    return Skeleton.replace(
      width: double.infinity,
      height: kSizedBoxH250,
      child: Container(
        margin: kPaddingH16,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: kRadius16,
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Center(
      child: SmoothPageIndicator(
        controller: PageController(),
        count: 5,
        effect: const WormEffect(
            dotHeight: kSizedBoxH8,
            dotWidth: kSizedBoxW8,
            activeDotColor: kPrimaryColor,
            dotColor: kBlack12),
      ),
    );
  }

  Widget _buildContent() {
    return Expanded(
      child: Padding(
        padding: kPaddingH16,
        child: ListView(
          children: [
            const SizedBox(height: kSizedBoxH12),
            _buildTitleAndActions(),
            const SizedBox(height: kSizedBoxH12),
            _buildStats(),
            const SizedBox(height: kSizedBoxH12),
            _buildAddress(),
            const SizedBox(height: kSizedBoxH12),
            _buildDescription(),
            const SizedBox(height: kSizedBoxH12),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton.leaf(
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 200),
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: kRadius8,
                  ),
                ),
              ),
              const SizedBox(height: kSizedBoxH8),
              Skeleton.leaf(
                child: Container(
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: kRadius8,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: kSizedBoxW12),
        Row(children: [
          Skeleton.leaf(
            child: Container(
              width: 40, // Slightly smaller
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: kSizedBoxW8), // Slightly smaller gap
          Skeleton.leaf(
            child: Container(
              width: 40, // Slightly smaller
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildStats() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          _StatItemSkeleton(),
          const SizedBox(width: 10),
          _StatItemSkeleton(),
          const SizedBox(width: 10),
          _StatItemSkeleton(),
        ],
      ),
    );
  }

  Widget _buildAddress() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton.leaf(
          child: Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: kRadius8,
            ),
          ),
        ),
        const SizedBox(height: kSizedBoxH8),
        Skeleton.leaf(
          child: Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: kRadius8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Skeleton.leaf(
          child: Container(
            width: 150,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: kRadius8,
            ),
          ),
        ),
        const SizedBox(height: kSizedBoxH12),
        Skeleton.leaf(
          child: Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: kRadius8,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Skeleton.leaf(
          child: Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: kRadius8,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Skeleton.leaf(
          child: Container(
            width: 200,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: kRadius8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    return SafeArea(
      child: Padding(
        padding: kPaddingFromLTRB16_8_16_16,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Skeleton.leaf(
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: kRadius30,
                ),
              ),
            ),
            const SizedBox(height: kSizedBoxH12),
            Skeleton.leaf(
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: kRadius30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItemSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Skeleton.leaf(
          child: Container(
            width: 50,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: kRadius8,
            ),
          ),
        ),
        const SizedBox(width: kSizedBoxW6),
        Skeleton.leaf(
          child: Container(
            width: 30,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: kRadius8,
            ),
          ),
        ),
      ],
    );
  }
}
