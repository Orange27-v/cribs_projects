import 'package:flutter/material.dart';
import '../../constants.dart';
import '../../services/plan_service.dart';
import '../../widgets/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class SubscriptionHistoryScreen extends StatefulWidget {
  const SubscriptionHistoryScreen({super.key});

  @override
  State<SubscriptionHistoryScreen> createState() =>
      _SubscriptionHistoryScreenState();
}

class _SubscriptionHistoryScreenState extends State<SubscriptionHistoryScreen> {
  final PlanService _planService = PlanService();
  late Future<List<Map<String, dynamic>>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = _planService.getSubscriptionHistory();
    });
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: AppBar(
        title: Text(
          'SUBSCRIPTION HISTORY',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: kBlack87,
          ),
        ),
        centerTitle: true,
        backgroundColor: kWhite,
        elevation: 0,
        iconTheme: const IconThemeData(color: kBlack87),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CustomLoadingIndicator(size: 40));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return const Center(
              child: EmptyStateWidget(
                message: 'No subscription history found.',
                icon: Icons.history_rounded,
              ),
            );
          }

          return CustomRefreshIndicator(
            onRefresh: () async => _loadHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final status = item['status']?.toString() ?? 'Unknown';
                final isActive = status.toLowerCase() == 'active';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? kPrimaryColor.withValues(alpha: 0.1)
                            : kGrey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.card_membership_rounded,
                        color: isActive ? kPrimaryColor : kGrey600,
                        size: 24,
                      ),
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item['plan_name'] ?? 'Unknown Plan',
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kBlack87,
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Activated: ${_formatDate(item['start_date'])}',
                          style:
                              GoogleFonts.roboto(fontSize: 13, color: kGrey600),
                        ),
                        Text(
                          'Expires: ${_formatDate(item['end_date'])}',
                          style:
                              GoogleFonts.roboto(fontSize: 13, color: kGrey600),
                        ),
                        if (item['amount_paid'] != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Amount: ₦${NumberFormat('#,###.00').format(double.parse(item['amount_paid'].toString()))}',
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kBlack87,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;

    switch (status.toLowerCase()) {
      case 'active':
        color = kGreen;
        bgColor = kGreen.withValues(alpha: 0.1);
        break;
      case 'expired':
        color = kRed;
        bgColor = kRed.withValues(alpha: 0.1);
        break;
      default:
        color = kGrey600;
        bgColor = kGrey.withValues(alpha: 0.1);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
