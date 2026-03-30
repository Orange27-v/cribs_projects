import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../constants.dart';
import '../../services/wallet_service.dart';
import '../transactions/transactions_screen.dart';

class EarningsCard extends StatefulWidget {
  const EarningsCard({super.key});

  @override
  State<EarningsCard> createState() => _EarningsCardState();
}

class _EarningsCardState extends State<EarningsCard> {
  final WalletService _walletService = WalletService();

  bool _isBalanceVisible = true;
  bool _isLoading = true;

  // Wallet data
  double _availableBalance = 0.0;
  double _pendingBalance = 0.0;
  double _totalEarned = 0.0;
  final double _monthlyGoal = 100000.0;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _walletService.getWallet();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          final wallet = result['wallet'];
          _availableBalance = (wallet?['available_balance'] ?? 0).toDouble();
          _pendingBalance = (wallet?['pending_balance'] ?? 0).toDouble();
          _totalEarned = (wallet?['total_earned'] ?? 0).toDouble();
        }
      });
    }
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      return '₦${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₦${(amount / 1000).toStringAsFixed(0)}K';
    }
    return _formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    double goalProgress =
        _monthlyGoal > 0 ? (_totalEarned / _monthlyGoal).clamp(0.0, 1.0) : 0.0;

    return GestureDetector(
      onTap: _loadWalletData,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              kPrimaryColor,
              Color.lerp(kPrimaryColor, const Color(0xFF1E3A5F), 0.6)!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: kPrimaryColor.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Label + Visibility Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kWhite.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        'assets/icons/coin-alt.svg',
                        colorFilter:
                            const ColorFilter.mode(kWhite, BlendMode.srcIn),
                        width: 16,
                        height: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Available Balance',
                      style: TextStyle(
                        color: kWhite.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isBalanceVisible = !_isBalanceVisible;
                    });
                  },
                  child: Icon(
                    _isBalanceVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: kWhite.withValues(alpha: 0.7),
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Balance
            _isLoading
                ? SizedBox(
                    height: 48,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: kWhite.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  )
                : Text(
                    _isBalanceVisible
                        ? _formatCurrency(_availableBalance)
                        : '₦ • • • • • •',
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),
            const SizedBox(height: 12),

            // Goal Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Monthly Goal',
                      style: TextStyle(
                        color: kWhite.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${(goalProgress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: kWhite,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: goalProgress,
                    minHeight: 6,
                    backgroundColor: kWhite.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.green.shade400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Footer Stats (Pending & Target)
            Row(
              children: [
                _buildCompactStat(
                  'Pending',
                  _isBalanceVisible
                      ? _formatCurrencyCompact(_pendingBalance)
                      : '***',
                  Icons.hourglass_empty_rounded,
                  Colors.orange.shade200,
                ),
                Container(
                  height: 24,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  color: kWhite.withValues(alpha: 0.15),
                ),
                _buildCompactStat(
                  'Target',
                  _formatCurrencyCompact(_monthlyGoal),
                  Icons.flag_rounded,
                  Colors.blue.shade200,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TransactionsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kWhite.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'History',
                          style: TextStyle(
                            color: kWhite,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 12,
                          color: kWhite,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(
      String label, String value, IconData icon, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: kWhite.withValues(alpha: 0.6),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: kWhite.withValues(alpha: 0.95),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
