import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cribs_arena/models/review.dart';
import 'package:cribs_arena/constants.dart';

// Constants for review display
const int kReviewMaxCharsForSummary = 150;
const String kDefaultProfileImage = 'assets/images/default_profile.jpg';

// ... existing widgets ...

/// Review Card Widget - Reusable review display component
class ReviewCard extends StatelessWidget {
  final Review review;
  final bool isExpanded;
  final VoidCallback onToggle;
  final EdgeInsetsGeometry? margin;

  const ReviewCard({
    super.key,
    required this.review,
    required this.isExpanded,
    required this.onToggle,
    this.margin,
  });

  String _formatDate(String dateString) {
    try {
      final DateTime parsedDate = DateTime.parse(dateString);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewText = review.reviewText;
    final isLongText = reviewText.length > kReviewMaxCharsForSummary ||
        reviewText.split('\n').length > 2;

    return Container(
      padding: const EdgeInsets.all(16),
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kGrey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Avatar
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kGrey300,
            ),
            clipBehavior: Clip.hardEdge,
            child: review.userPhotoUrl.isNotEmpty
                ? Image.network(
                    review.userPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Image.asset(kDefaultProfileImage, fit: BoxFit.cover),
                  )
                : Image.asset(kDefaultProfileImage, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          // Review Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(review.createdAt),
                      style: const TextStyle(
                        color: kGrey600,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // User Name
                Text(
                  review.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: kBlack87,
                  ),
                ),
                const SizedBox(height: 4),
                // Star Rating
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: kOrange,
                      size: 12,
                    );
                  }),
                ),
                const SizedBox(height: 8),
                // Review Text
                Text(
                  reviewText,
                  maxLines: isExpanded ? null : 2,
                  overflow:
                      isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: kGrey600,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                // Read More/Less Button
                if (isLongText)
                  GestureDetector(
                    onTap: onToggle,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        isExpanded ? 'Read less' : 'Read more',
                        style: const TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Review Card Skeleton - Loading placeholder for reviews
class ReviewCardSkeleton extends StatefulWidget {
  final EdgeInsetsGeometry? margin;

  const ReviewCardSkeleton({
    super.key,
    this.margin,
  });

  @override
  State<ReviewCardSkeleton> createState() => _ReviewCardSkeletonState();
}

class _ReviewCardSkeletonState extends State<ReviewCardSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: widget.margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kGrey100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: 0.3 + (_controller.value * 0.4),
            child: child,
          );
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Skeleton
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: kGrey300,
              ),
            ),
            const SizedBox(width: 12),
            // Content Skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Skeleton
                  Container(
                    width: 80,
                    height: 10,
                    decoration: BoxDecoration(
                      color: kGrey300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Name Skeleton
                  Container(
                    width: 120,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kGrey300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Stars Skeleton
                  Row(
                    children: List.generate(
                      5,
                      (index) => Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: kGrey300,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Review Text Skeleton (2 lines)
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kGrey300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity * 0.7,
                    height: 12,
                    decoration: BoxDecoration(
                      color: kGrey300,
                      borderRadius: BorderRadius.circular(4),
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

/// Reviews List with Loading State
class ReviewsList extends StatelessWidget {
  final List<Review>? reviews;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final Set<int> expandedReviews;
  final Function(int) onToggleExpand;
  final int? maxReviews;
  final VoidCallback? onSeeAll;

  const ReviewsList({
    super.key,
    required this.reviews,
    required this.isLoading,
    this.error,
    this.onRetry,
    required this.expandedReviews,
    required this.onToggleExpand,
    this.maxReviews,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    // Loading State
    if (isLoading) {
      return Column(
        children: List.generate(
          3,
          (index) => ReviewCardSkeleton(
            margin: EdgeInsets.only(
              bottom: index == 2 ? 0 : 12,
            ),
          ),
        ),
      );
    }

    // Error State
    if (error != null) {
      return Center(
        child: Column(
          children: [
            Text(
              error!,
              style: const TextStyle(color: kGrey600),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      );
    }

    // Empty State
    if (reviews == null || reviews!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        width: double.infinity,
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderGrey),
        ),
        child: const Text(
          'Be the first to review this agent',
          style: TextStyle(color: kGrey700, height: 1.6),
        ),
      );
    }

    // Reviews List
    final reviewsToShow =
        maxReviews != null ? reviews!.take(maxReviews!).toList() : reviews!;
    final hasMore = maxReviews != null && reviews!.length > maxReviews!;

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: reviewsToShow.length,
          itemBuilder: (context, index) {
            final review = reviewsToShow[index];
            final isLast = index == reviewsToShow.length - 1;

            return ReviewCard(
              review: review,
              isExpanded: expandedReviews.contains(review.id),
              onToggle: () => onToggleExpand(review.id),
              margin:
                  (isLast && hasMore) ? const EdgeInsets.only(bottom: 4) : null,
            );
          },
        ),
        if (hasMore && onSeeAll != null)
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('See All Reviews'),
            ),
          ),
      ],
    );
  }
}
