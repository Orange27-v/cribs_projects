import '../properties/properties_screen.dart';
import '../../constants.dart';
import '../clients/clients_screen.dart';
import '../schedule/schedule_screen.dart';
import '../leads/leads_screen.dart';
import '../../models/transaction.dart';
import '../../services/wallet_service.dart';
import '../../services/agent_stats_service.dart';
import '../review/review_screen.dart';
import '../set_active_areas/set_active_areas_screen.dart';
import '../set_rate/set_rate_screen.dart';
import '../transactions/transactions_screen.dart';
import '../transactions/transaction_details_screen.dart';
import '../withdrawal/withdrawal_screen.dart';
import '../../widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'earnings_card.dart';
import '../deposit/deposit_screen.dart';
import '../plans/subscription_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();

  List<Transaction> _transactions = [];
  bool _isLoadingTransactions = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  int _earningsRefreshKey = 0;

  // Agent stats
  AgentStats? _stats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadTransactions();
    _loadStats();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoadingTransactions = true;
    });

    final result = await _walletService.getTransactions(perPage: 6);

    if (mounted) {
      setState(() {
        _isLoadingTransactions = false;
        if (result['success'] == true) {
          final txList = result['transactions'] as List? ?? [];
          _transactions = txList
              .map((tx) =>
                  Transaction.fromWalletTransaction(tx as Map<String, dynamic>))
              .toList();
        }
      });
    }
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    final result = await AgentStatsService.getAgentStats();
    if (mounted) {
      setState(() {
        _isLoadingStats = false;
        if (result['success'] == true) {
          _stats = result['data'] as AgentStats;
        }
      });
    }
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _earningsRefreshKey++;
    });
    await Future.wait([_loadTransactions(), _loadStats()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      body: SafeArea(
        child: CustomRefreshIndicator(
          onRefresh: _refreshDashboard,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 90),
                EarningsCard(key: ValueKey(_earningsRefreshKey)),
                const SizedBox(height: 20),
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildQuickSettings(),
                const SizedBox(height: 24),
                _buildStatsGrid(),
                const SizedBox(height: 24),
                _buildRecentTransactions(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            text: 'Add Funds',
            icon: const Icon(Icons.add_rounded, color: kWhite, size: 20),
            backgroundColor: kPrimaryColor,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DepositScreen()),
              );
              _refreshDashboard();
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: PrimaryButton(
            text: 'Withdraw',
            icon:
                const Icon(Icons.arrow_upward_rounded, color: kWhite, size: 20),
            backgroundColor: kPrimaryColor,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WithdrawScreen()),
              );
              _refreshDashboard();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kGrey700,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionItem(
                title: 'Set Rate',
                icon: Icons.price_change_rounded,
                color: Colors.green,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SetRateScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionItem(
                title: 'Active Areas',
                icon: Icons.location_on_rounded,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SetActiveAreasScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionItem(
                title: 'Sub History',
                icon: Icons.history_edu_rounded,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            const SubscriptionHistoryScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionItem({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: kWhite,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kBlack87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: kBlack,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // Calculate a responsive aspect ratio
            double crossAxisCount = 3;
            double spacing = 10;
            double itemWidth =
                (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                    crossAxisCount;

            // On very small devices, we need more height relative to width
            // Target height for content is around 100-110 units
            double targetHeight = 105.0;
            double aspectRatio = itemWidth / targetHeight;

            return GridView.count(
              crossAxisCount: crossAxisCount.toInt(),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: aspectRatio,
              children: [
                _buildStatCard(
                  icon: Icons.star_rounded,
                  label: 'Rating',
                  value: _isLoadingStats ? '-' : _stats?.averageRating ?? '0.0',
                  bgColor: Colors.orange.shade50,
                  iconColor: Colors.orange.shade600,
                  accentColor: Colors.orange.shade100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ReviewScreen()),
                    );
                  },
                ),
                _buildStatCard(
                  icon: Icons.people_rounded,
                  label: 'Clients',
                  value: _isLoadingStats ? '-' : '${_stats?.totalClients ?? 0}',
                  bgColor: Colors.blue.shade50,
                  iconColor: Colors.blue.shade600,
                  accentColor: Colors.blue.shade100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ClientsScreen()),
                    );
                  },
                ),
                _buildStatCard(
                  iconWidget: SvgPicture.asset(
                    'assets/icons/success.svg',
                    height: 12,
                    width: 12,
                  ),
                  label: 'Closed Deals',
                  value: _isLoadingStats ? '-' : '${_stats?.closedDeals ?? 0}',
                  bgColor: Colors.green.shade50,
                  iconColor: Colors.green.shade600,
                  accentColor: Colors.green.shade100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyScheduleScreen(
                                initialTabIndex: 2,
                                initialFilterStatus: 'Completed',
                              )),
                    );
                  },
                ),
                _buildStatCard(
                  icon: Icons.home_rounded,
                  label: 'Listings',
                  value:
                      _isLoadingStats ? '-' : '${_stats?.totalListings ?? 0}',
                  bgColor: Colors.purple.shade50,
                  iconColor: Colors.purple.shade600,
                  accentColor: Colors.purple.shade100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const PropertiesScreen()),
                    );
                  },
                ),
                _buildStatCard(
                  icon: Icons.group_rounded,
                  label: 'Leads',
                  value: _isLoadingStats ? '-' : '${_stats?.totalLeads ?? 0}',
                  bgColor: Colors.teal.shade50,
                  iconColor: Colors.teal.shade600,
                  accentColor: Colors.teal.shade100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LeadsScreen()),
                    );
                  },
                ),
                _buildStatCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Appointments',
                  value: _isLoadingStats
                      ? '-'
                      : '${_stats?.totalAppointments ?? 0}',
                  bgColor: Colors.red.shade50,
                  iconColor: Colors.red.shade600,
                  accentColor: Colors.red.shade100,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyScheduleScreen(),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required String value,
    required Color bgColor,
    required Color iconColor,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10), // Slightly reduced from 12
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: kGrey.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6), // Reduced from 8
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(8), // Reduced from 10
                    ),
                    child: iconWidget ??
                        Icon(icon,
                            color: iconColor, size: 14), // Increased from 12
                  ),
                  if (onTap != null)
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: kGrey.shade300,
                    ),
                ],
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: kBlack87,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 1), // Reduced from 2
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: kGrey600,
                  fontSize: 10.5, // Slightly reduced from 11
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: kGrey700,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TransactionsScreen()),
                  );
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('See all'),
                style: TextButton.styleFrom(
                  foregroundColor: kPrimaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_isLoadingTransactions)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: CircularProgressIndicator(color: kPrimaryColor),
            ),
          )
        else if (_transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(8),
              border:
                  Border.all(color: kGrey.shade200, style: BorderStyle.solid),
            ),
            child: const EmptyStateWidget(
              message:
                  'No transactions yet\nYour transaction history will appear here',
              icon: Icons.receipt_long_outlined,
            ),
          )
        else
          CardContainer(
            padding: EdgeInsets.zero,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _transactions.length > 6 ? 6 : _transactions.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: kGrey.shade200,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return TransactionListItem(
                  transaction: transaction,
                  onTap: () {
                    if (transaction.id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TransactionDetailsScreen(
                            transactionId: transaction.id!,
                            transactionTitle: transaction.title,
                          ),
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
