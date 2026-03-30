enum TransactionType { incoming, outgoing }

class Transaction {
  final int? id;
  final String title;
  final String date;
  final double amount;
  final TransactionType type;
  final String status;
  final String? reference;
  final String? description;

  Transaction({
    this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.type,
    required this.status,
    this.reference,
    this.description,
  });

  /// Create from wallet transaction API response
  factory Transaction.fromWalletTransaction(Map<String, dynamic> json) {
    final txType = json['transaction_type'] ?? json['type'] ?? '';
    final isCredit = json['is_credit'] == true ||
        txType == 'deposit' ||
        txType == 'refund' ||
        txType == 'escrow_release';

    return Transaction(
      id: json['id'],
      title: json['description'] ?? _getTitleFromType(txType),
      date: _formatDate(json['created_at']),
      amount: (json['amount'] ?? 0).toDouble(),
      type: isCredit ? TransactionType.incoming : TransactionType.outgoing,
      status: json['status'] ?? 'pending',
      reference: json['reference'],
      description: json['description'],
    );
  }

  static String _getTitleFromType(String type) {
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

  static String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      final hour =
          date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final amPm = date.hour >= 12 ? 'PM' : 'AM';
      final minute = date.minute.toString().padLeft(2, '0');
      return '${months[date.month - 1]} ${date.day} - $hour:$minute $amPm';
    } catch (e) {
      return dateStr;
    }
  }
}
