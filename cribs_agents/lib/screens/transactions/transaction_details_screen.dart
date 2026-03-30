import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/services/wallet_service.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class TransactionDetailsScreen extends StatefulWidget {
  final int transactionId;
  final String? transactionTitle;

  const TransactionDetailsScreen({
    super.key,
    required this.transactionId,
    this.transactionTitle,
  });

  @override
  State<TransactionDetailsScreen> createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState extends State<TransactionDetailsScreen> {
  final WalletService _walletService = WalletService();

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _transaction;

  @override
  void initState() {
    super.initState();
    _loadTransactionDetails();
  }

  Future<void> _loadTransactionDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    debugPrint(
        '🔍 Fetching transaction details for ID: ${widget.transactionId}');
    final result =
        await _walletService.getTransactionDetails(widget.transactionId);

    debugPrint('📦 Transaction details result: $result');

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _transaction = result['data'];
          debugPrint('✅ Transaction data loaded: $_transaction');
        } else {
          _errorMessage = result['message'];
          debugPrint('❌ Error: $_errorMessage');
        }
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatCurrency(double? amount) {
    if (amount == null) return '₦0.00';
    return NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 2)
        .format(amount);
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy • h:mm a').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getTransactionTypeLabel(String? type) {
    switch (type) {
      case 'deposit':
        return 'Deposit';
      case 'withdrawal':
        return 'Withdrawal';
      case 'refund':
        return 'Refund';
      case 'escrow_release':
        return 'Escrow Released';
      case 'escrow_hold':
        return 'Escrow Hold';
      case 'platform_fee':
        return 'Platform Fee';
      default:
        return 'Transaction';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'success':
        return kGreen;
      case 'pending':
        return kOrange;
      case 'processing':
        return kBlue;
      case 'failed':
        return kRed;
      default:
        return kGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: PrimaryAppBar(
        title: Text(
          widget.transactionTitle ?? 'Transaction Details',
          style: GoogleFonts.outfit(
            color: kPrimaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: kPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CustomLoadingIndicator(color: kPrimaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: kPaddingAll24,
          child: NetworkErrorWidget(
            errorMessage: _errorMessage,
            onRefresh: _loadTransactionDetails,
            title: 'Error Loading Details',
          ),
        ),
      );
    }

    if (_transaction == null) {
      return const Center(
        child: Text('Transaction not found'),
      );
    }

    final tx = _transaction!;
    final isCredit = tx['is_credit'] == true;
    final type = tx['type']?.toString() ?? '';
    final status = tx['status']?.toString() ?? '';
    final amount = (tx['amount'] ?? 0).toDouble();
    final fee = (tx['fee'] ?? 0).toDouble();
    final netAmount = (tx['net_amount'] ?? 0).toDouble();
    final balanceBefore = (tx['balance_before'] ?? 0).toDouble();
    final balanceAfter = (tx['balance_after'] ?? 0).toDouble();

    return CustomRefreshIndicator(
      onRefresh: _loadTransactionDetails,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: kPaddingAll20,
        child: Column(
          children: [
            // Amount Card
            Container(
              width: double.infinity,
              padding: kPaddingAll24,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCredit
                      ? [kGreen600, kGreen.shade300]
                      : [kRed600, kRed.shade300],
                ),
                borderRadius: kRadius12,
                boxShadow: [
                  BoxShadow(
                    color:
                        (isCredit ? kGreen600 : kRed600).withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Type Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: kWhite.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCredit
                          ? Icons.south_west_rounded
                          : Icons.north_east_rounded,
                      color: kWhite,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Amount
                  Text(
                    '${isCredit ? '+' : '-'} ${_formatCurrency(amount)}',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: kWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Type Label
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: kWhite.withValues(alpha: 0.2),
                      borderRadius: kRadius12,
                    ),
                    child: Text(
                      _getTransactionTypeLabel(type),
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: kWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Details Card
            SectionCard(
              padding: kPaddingAll20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Transaction Details',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kBlack,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status
                  _buildDetailRow(
                    'Status',
                    status.toUpperCase(),
                    valueColor: _getStatusColor(status),
                    isBold: true,
                  ),
                  const Divider(height: 1),

                  // Date
                  _buildDetailRow(
                    'Date',
                    _formatDate(tx['created_at']),
                  ),
                  const Divider(height: 1),

                  // Reference
                  if (tx['reference'] != null) ...[
                    _buildDetailRow(
                      'Reference',
                      tx['reference'],
                      onCopy: () => _copyToClipboard(tx['reference']),
                    ),
                    const Divider(height: 1),
                  ],

                  // Description
                  if (tx['description'] != null &&
                      tx['description'].toString().isNotEmpty) ...[
                    _buildDetailRow(
                      'Description',
                      tx['description'],
                    ),
                    const Divider(height: 1),
                  ],

                  // Fee
                  if (fee > 0) ...[
                    _buildDetailRow(
                      'Fee',
                      _formatCurrency(fee),
                      valueColor: kRed,
                    ),
                    const Divider(height: 1),
                  ],

                  // Net Amount
                  _buildDetailRow(
                    'Net Amount',
                    _formatCurrency(netAmount),
                    valueColor: isCredit ? kGreen : kRed,
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Balance Card
            SectionCard(
              padding: kPaddingAll20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balance Impact',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: kBlack,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                    'Before',
                    _formatCurrency(balanceBefore),
                  ),
                  const Divider(height: 1),
                  _buildDetailRow(
                    'After',
                    _formatCurrency(balanceAfter),
                    valueColor: kPrimaryColor,
                    isBold: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    VoidCallback? onCopy,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: kGrey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                      color: valueColor ?? kBlack87,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                if (onCopy != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onCopy,
                    child: Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: kGrey400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
