import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/services/agent_review_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  AgentReviewData? _reviewData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await AgentReviewService.getMyReviews();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _reviewData = result['data'] as AgentReviewData;
        } else {
          _error = result['error'] as String?;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: AppBar(
        backgroundColor: kWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Reviews',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: kGrey.shade400),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Failed to load reviews',
            style: TextStyle(color: kGrey.shade600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadReviews,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final data = _reviewData!;
    final reviews = data.reviews;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadReviews,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildHeader(data),
                const SizedBox(height: 24),
                if (reviews.isEmpty)
                  _buildEmptyState()
                else
                  ...reviews.map((review) => _ReviewListItem(review: review)),
                const SizedBox(height: 34),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: kRadius16,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                spreadRadius: 2,
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: _buildRatingSummary(data),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: EmptyStateWidget(
        message: 'No reviews yet\nYour client reviews will appear here',
        icon: Icons.rate_review_outlined,
      ),
    );
  }

  Widget _buildHeader(AgentReviewData data) {
    // Agent profile pictures - DB stores path like 'agent_pictures/1.jpg'
    String? imageUrl;
    if (data.agentImage != null && data.agentImage!.isNotEmpty) {
      final imagePath = data.agentImage!;
      // If path already includes folder prefix, use it directly
      if (imagePath.startsWith('agent_pictures/') ||
          imagePath.startsWith('profile_pictures/')) {
        imageUrl = '$kMainBaseUrl/storage/$imagePath';
      } else {
        imageUrl = '$kMainBaseUrl/storage/agent_pictures/$imagePath';
      }
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        CircleAvatar(
          radius: 40,
          backgroundColor: kGrey.shade200,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
          child: imageUrl == null
              ? Icon(Icons.person, size: 40, color: kGrey.shade400)
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          data.agentName,
          style: GoogleFonts.roboto(
            fontSize: kFontSize24,
            fontWeight: FontWeight.bold,
            color: kBlack87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          data.agentLocation,
          style: const TextStyle(color: kGrey, fontSize: kFontSize10),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(
              data.averageRating,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: kFontSize10,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.person_outline, color: kGrey, size: 18),
            const SizedBox(width: 4),
            Text(
              '${data.totalReviews}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: kFontSize10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingSummary(AgentReviewData data) {
    final total = data.totalReviews > 0 ? data.totalReviews : 1;
    final breakdown = data.ratingBreakdown;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: kWhite, borderRadius: kRadius16),
      child: Row(
        children: [
          Text(
            data.averageRating,
            style: GoogleFonts.roboto(
              fontSize: kFontSize32,
              fontWeight: FontWeight.bold,
              color: kPrimaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                _buildRatingBar('5', (breakdown['5'] ?? 0) / total,
                    '${breakdown['5'] ?? 0}'),
                _buildRatingBar('4', (breakdown['4'] ?? 0) / total,
                    '${breakdown['4'] ?? 0}'),
                _buildRatingBar('3', (breakdown['3'] ?? 0) / total,
                    '${breakdown['3'] ?? 0}'),
                _buildRatingBar('2', (breakdown['2'] ?? 0) / total,
                    '${breakdown['2'] ?? 0}'),
                _buildRatingBar('1', (breakdown['1'] ?? 0) / total,
                    '${breakdown['1'] ?? 0}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String label, double value, String count) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: kFontSize12, color: kGrey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: kGrey.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(kGreen),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 24,
          child: Text(
            count,
            style: const TextStyle(fontSize: kFontSize12, color: kGrey),
          ),
        ),
      ],
    );
  }
}

class _ReviewListItem extends StatelessWidget {
  final Review review;

  const _ReviewListItem({required this.review});

  @override
  Widget build(BuildContext context) {
    // User profile pictures are stored in profile_pictures folder
    // The path from DB may include 'profile_pictures/' prefix or just filename
    String? imageUrl;
    if (review.reviewerImage != null && review.reviewerImage!.isNotEmpty) {
      final imagePath = review.reviewerImage!;
      if (imagePath.startsWith('profile_pictures/')) {
        imageUrl = '$kMainBaseUrl/storage/$imagePath';
      } else {
        imageUrl = '$kMainBaseUrl/storage/profile_pictures/$imagePath';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: kGrey.shade200,
                backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl) : null,
                child: imageUrl == null
                    ? Icon(Icons.person, size: 20, color: kGrey.shade400)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (review.reviewText != null &&
                        review.reviewText!.isNotEmpty)
                      Text(
                        review.reviewText!,
                        style: const TextStyle(
                          color: kBlack87,
                          height: 1.5,
                          fontSize: kFontSize10,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          review.reviewerName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: kBlack87,
                            fontSize: kFontSize10,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          review.rating.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: kFontSize10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }
}
