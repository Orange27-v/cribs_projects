import 'package:cribs_arena/utils/snackbar_helper.dart';
import 'package:flash/flash.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_arena/constants.dart';
import 'package:cribs_arena/models/agent.dart';
import 'package:cribs_arena/screens/components/custom_app_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_arena/services/report_service.dart';
import 'package:cribs_arena/utils/error_handler.dart';
import 'package:cribs_arena/services/user_service.dart';
import 'package:cribs_arena/widgets/widgets.dart';

// ============================================================================
// CONSTANTS
// ============================================================================

const List<String> _kReportIssues = [
  'No response or Ghosting',
  'Rude or unprofessional behavior',
  'Requests for additional payment',
  'Sexual harassment or Inappropriate behavior',
  'Inflated fees',
  'Bribery',
  'Bait-and-switch (property shown is different from the one listed)',
];

// ============================================================================
// MAIN SCREEN
// ============================================================================

class ReportScreen extends StatefulWidget {
  final String agentId;

  const ReportScreen({
    super.key,
    required this.agentId,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  final UserService _userService = UserService();

  late Future<Agent> _agentFuture;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _agentFuture = _fetchAgentDetails();
  }

  @override
  void dispose() {
    _userService.dispose();
    super.dispose();
  }

  Future<Agent> _fetchAgentDetails() async {
    try {
      final agentData = await _userService.fetchAgentDetails(widget.agentId);
      return Agent.fromJson(agentData['data']);
    } catch (e) {
      debugPrint('Error fetching agent details: $e');
      rethrow;
    }
  }

  Future<void> _submitReport(String issue, {String? details}) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    final navigator = Navigator.of(context);

    try {
      final response = await _reportService.submitReport(
        agentId: int.parse(widget.agentId),
        issue: issue,
        details: details,
      );

      if (!mounted) return;

      if (response.statusCode == 201 || response.statusCode == 200) {
        SnackbarHelper.showSuccess(
          context,
          'Report submitted successfully.',
          position: FlashPosition.bottom,
        );
        navigator.pop();
      } else {
        SnackbarHelper.showError(
          context,
          'Failed to submit report: ${response.body}',
          position: FlashPosition.bottom,
        );
      }
    } catch (e) {
      if (!mounted) return;
      SnackbarHelper.showError(
        context,
        ErrorHandler.getErrorMessage(e),
        position: FlashPosition.bottom,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showOtherIssuesDialog() {
    showDialog(
      context: context,
      builder: (context) => _OtherIssueDialog(
        onSubmit: (details) => _submitReport('Other issues', details: details),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const CustomAppBar(
        title: 'Report Issue',
        showBackButton: true,
        actions: [],
      ),
      body: FutureBuilder<Agent>(
        future: _agentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator());
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('Agent not found.'));
          }

          return _buildContent(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Text(
        ErrorHandler.getErrorMessage(error),
        style: GoogleFonts.roboto(
          color: kRed,
          fontSize: kFontSize14,
        ),
      ),
    );
  }

  Widget _buildContent(Agent agent) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AgentInfoHeader(agent: agent),
              const SizedBox(height: 24),
              _buildSectionTitle(),
              const SizedBox(height: 24),
              _buildIssuesList(),
              const SizedBox(height: 16),
              _buildOtherIssuesTile(),
            ],
          ),
        ),
        if (_isSubmitting)
          const SimpleLoadingOverlay(message: 'Submitting report...'),
      ],
    );
  }

  Widget _buildSectionTitle() {
    return Text(
      'Something is wrong? Choose an issue',
      style: GoogleFonts.roboto(
        fontSize: kFontSize16,
        fontWeight: FontWeight.bold,
        color: kBlack,
      ),
    );
  }

  Widget _buildIssuesList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _kReportIssues.length,
      itemBuilder: (context, index) {
        return _IssueTile(
          title: _kReportIssues[index],
          onTap: () => _submitReport(_kReportIssues[index]),
        );
      },
      separatorBuilder: (context, index) => const SizedBox(height: 16),
    );
  }

  Widget _buildOtherIssuesTile() {
    return _IssueTile(
      title: 'Other issues',
      onTap: _showOtherIssuesDialog,
    );
  }
}

// ============================================================================
// AGENT INFO HEADER
// ============================================================================

class _AgentInfoHeader extends StatelessWidget {
  final Agent agent;

  const _AgentInfoHeader({required this.agent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: kPaddingH16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            agent.fullName,
            style: GoogleFonts.roboto(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: kFontSize16,
            ),
          ),
          const SizedBox(height: 4),
          _buildRatingRow(),
        ],
      ),
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        const Icon(
          Icons.star,
          color: Colors.amber,
          size: kIconSize12,
        ),
        const SizedBox(width: kSizedBoxW4),
        Text(
          agent.averageRating?.toStringAsFixed(1) ?? 'N/A',
          style: GoogleFonts.roboto(
            color: kBlack87,
            fontWeight: FontWeight.w500,
            fontSize: kFontSize12,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '• ${agent.totalReviews ?? 0} reviews',
          style: GoogleFonts.roboto(
            color: kGrey,
            fontSize: kFontSize12,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ISSUE TILE
// ============================================================================

class _IssueTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const _IssueTile({
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: kRadius8,
      child: Padding(
        padding: kPaddingAll8,
        child: Row(
          children: [
            SvgPicture.asset(
              'assets/icons/block.svg',
              colorFilter: const ColorFilter.mode(
                kPrimaryColor,
                BlendMode.srcIn,
              ),
              height: kIconSize24,
              width: kIconSize24,
            ),
            const SizedBox(width: kSizedBoxW16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: kFontSize14,
                  color: kBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: kGrey.withAlpha(128),
              size: kIconSize20,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// OTHER ISSUE DIALOG
// ============================================================================

class _OtherIssueDialog extends StatefulWidget {
  final Function(String) onSubmit;

  const _OtherIssueDialog({required this.onSubmit});

  @override
  State<_OtherIssueDialog> createState() => _OtherIssueDialogState();
}

class _OtherIssueDialogState extends State<_OtherIssueDialog> {
  final TextEditingController _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_detailsController.text.trim().isEmpty) {
      return;
    }

    Navigator.of(context).pop();
    widget.onSubmit(_detailsController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return CustomAlertDialog(
      title: Text(
        'Other Issue',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.bold,
          fontSize: kFontSize16,
        ),
      ),
      content: TextField(
        controller: _detailsController,
        decoration: InputDecoration(
          hintText: 'Please describe the issue',
          hintStyle: GoogleFonts.roboto(
            color: kGrey,
            fontSize: kFontSize14,
          ),
          border: OutlineInputBorder(
            borderRadius: kRadius8,
            borderSide: const BorderSide(color: kGrey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: kRadius8,
            borderSide: const BorderSide(color: kPrimaryColor, width: 2),
          ),
        ),
        maxLines: 4,
        maxLength: 500,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.roboto(
              color: kGrey,
              fontSize: kFontSize14,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: kRadius8,
            ),
            padding: kPaddingH20V12,
          ),
          child: Text(
            'Submit',
            style: GoogleFonts.roboto(
              color: kWhite,
              fontSize: kFontSize14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
