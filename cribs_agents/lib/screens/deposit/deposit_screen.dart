import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/services/wallet_service.dart';
import 'package:cribs_agents/screens/deposit/widgets/deposit_amount_input.dart';
import 'package:cribs_agents/screens/deposit/deposit_payment_webview.dart';

class DepositScreen extends StatelessWidget {
  const DepositScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: kGrey100,
        appBar: AppBar(
          backgroundColor: kWhite,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Deposit',
            style: GoogleFonts.roboto(
              color: kPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const DepositBody(),
      ),
    );
  }
}

class DepositBody extends StatefulWidget {
  const DepositBody({super.key});

  @override
  State<DepositBody> createState() => _DepositBodyState();
}

class _DepositBodyState extends State<DepositBody> {
  final TextEditingController _amountController = TextEditingController();
  final WalletService _walletService = WalletService();
  bool _isLoading = false;
  double _platformFee = 0.0;
  double _amount = 0.0;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onAmountChanged);
    _fetchPlatformFee();
  }

  Future<void> _fetchPlatformFee() async {
    final fee = await _walletService.getPlatformFee();
    if (mounted) {
      setState(() {
        _platformFee = fee;
      });
    }
  }

  void _onAmountChanged() {
    final text = _amountController.text.trim();
    setState(() {
      _amount = double.tryParse(text) ?? 0.0;
    });
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleDeposit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    final netAmount = amount - _platformFee;
    if (netAmount < 1000) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Estimated credit must be at least ₦1,000. '
            'Minimum deposit required is ₦${(1000 + _platformFee).toInt()}',
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _walletService.initializeDeposit(amount);

      if (!mounted) return;

      if (result['success'] == true) {
        final data = result['data'];
        final authorizationUrl = data['authorization_url'];
        final reference = data['reference'];

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DepositPaymentWebViewScreen(
              authorizationUrl: authorizationUrl,
              reference: reference,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(result['message'] ?? 'Failed to initialize deposit')),
        );
      }
    } catch (e) {
      debugPrint('Deposit error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                DepositAmountInput(controller: _amountController),
                const SizedBox(height: 24),
                if (_amount > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: kPrimaryColor.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        _buildBreakdownRow('Deposit Amount',
                            '₦ ${_amount.toStringAsFixed(2)}'),
                        const SizedBox(height: 12),
                        _buildBreakdownRow('Platform Fee',
                            '- ₦ ${_platformFee.toStringAsFixed(2)}',
                            isNegative: true),
                        const Divider(height: 24),
                        _buildBreakdownRow(
                          'Estimated Wallet Credit',
                          '₦ ${(_amount > _platformFee ? _amount - _platformFee : 0).toStringAsFixed(2)}',
                          isTotal: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Funds will be added to your wallet instantly after successful payment.',
                  style: GoogleFonts.roboto(
                    color: kGrey600,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: kWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: PrimaryButton(
              text: 'Deposit',
              isLoading: _isLoading,
              onPressed: _handleDeposit,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String value,
      {bool isNegative = false, bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w400,
            color: isTotal ? kPrimaryColor : kGrey600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: isTotal ? 14 : 13,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isNegative ? Colors.red : (isTotal ? kPrimaryColor : kBlack),
          ),
        ),
      ],
    );
  }
}
