import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:cribs_arena/constants.dart';

// ============================================================================
// AGENT CARD SKELETON
// ============================================================================

/// Skeleton loader for agent cards displayed in grid views.
/// Designed to fit within GridView constraints with childAspectRatio: 0.8
class AgentCardSkeleton extends StatelessWidget {
  const AgentCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: kLightCyan,
          borderRadius: kRadius8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatarSkeleton(),
            const SizedBox(height: 8),
            _buildNameSkeleton(),
            const SizedBox(height: 4),
            _buildLicenseSkeleton(),
            const SizedBox(height: 8),
            _buildRatingSkeleton(),
            const SizedBox(height: 8),
            _buildActionButtonSkeleton(),
          ],
        ),
      ),
    );
  }

  /// Avatar circle skeleton
  Widget _buildAvatarSkeleton() {
    return Container(
      width: kRadius35 * 2,
      height: kRadius35 * 2,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }

  /// Agent name skeleton
  Widget _buildNameSkeleton() {
    return Container(
      width: 120,
      height: 14,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// License text skeleton
  Widget _buildLicenseSkeleton() {
    return Container(
      width: 100,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Rating row skeleton with stars and review count
  Widget _buildRatingSkeleton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStarsSkeleton(),
        const SizedBox(width: 6),
        _buildReviewCountSkeleton(),
      ],
    );
  }

  /// Star icons skeleton
  Widget _buildStarsSkeleton() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: kIconSize18,
          height: kIconSize18,
          margin: const EdgeInsets.only(right: 2),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  /// Review count text skeleton
  Widget _buildReviewCountSkeleton() {
    return Container(
      width: 60,
      height: 10,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  /// Action button skeleton
  Widget _buildActionButtonSkeleton() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
      ),
    );
  }
}
