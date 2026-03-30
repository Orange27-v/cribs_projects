import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/models/transaction.dart';
import 'package:cribs_agents/services/wallet_service.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/screens/transactions/transaction_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();

  List<Transaction> _allTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Summary stats
  double _totalIncoming = 0.0;
  double _totalOutgoing = 0.0;

  // Pagination
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoadingMore = false;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChange);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _loadTransactions({bool loadMore = false}) async {
    if (loadMore && _isLoadingMore) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
      }
    });

    final page = loadMore ? _currentPage + 1 : 1;
    final result = await _walletService.getTransactions(
      page: page,
      perPage: 20,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;

        if (result['success'] == true) {
          final txList = result['transactions'] as List? ?? [];
          final newTransactions = txList
              .map((tx) =>
                  Transaction.fromWalletTransaction(tx as Map<String, dynamic>))
              .toList();

          if (loadMore) {
            _allTransactions.addAll(newTransactions);
          } else {
            _allTransactions = newTransactions;
            _calculateSummary();
          }

          final pagination = result['pagination'] as Map<String, dynamic>?;
          if (pagination != null) {
            _currentPage = pagination['current_page'] ?? 1;
            _lastPage = pagination['last_page'] ?? 1;
          }
        } else {
          _errorMessage = result['message'];
        }
      });
    }
  }

  void _calculateSummary() {
    _totalIncoming = 0.0;
    _totalOutgoing = 0.0;

    for (final tx in _allTransactions) {
      if (tx.type == TransactionType.incoming) {
        _totalIncoming += tx.amount;
      } else {
        _totalOutgoing += tx.amount;
      }
    }
  }

  List<Transaction> _getFilteredTransactions() {
    switch (_tabController.index) {
      case 0: // Successful (deposits, escrow releases)
        return _allTransactions
            .where((tx) =>
                tx.status == 'success' && tx.type == TransactionType.incoming)
            .toList();
      case 1: // Pending
        return _allTransactions
            .where((tx) => tx.status == 'pending' || tx.status == 'processing')
            .toList();
      case 2: // Withdrawn
        return _allTransactions
            .where((tx) => tx.type == TransactionType.outgoing)
            .toList();
      default:
        return _allTransactions;
    }
  }

  String _formatCurrencyCompact(double amount) {
    if (amount >= 1000000) {
      return '₦${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '₦${(amount / 1000).toStringAsFixed(0)}K';
    }
    return NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0)
        .format(amount);
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
          'Transactions',
          style: TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: kWhite,
            child: TabBar(
              controller: _tabController,
              indicatorColor: kPrimaryColor,
              labelColor: kPrimaryColor,
              unselectedLabelColor: kGrey,
              tabs: const [
                Tab(text: 'Successful'),
                Tab(text: 'Pending'),
                Tab(text: 'Withdrawn'),
              ],
            ),
          ),
          Padding(
            padding: kPaddingAll16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction History',
                  style: GoogleFonts.roboto(
                    fontSize: kFontSize14,
                    fontWeight: FontWeight.w600,
                    color: kPrimaryColor,
                  ),
                ),
                Text(
                  'In ${_formatCurrencyCompact(_totalIncoming)}  Out ${_formatCurrencyCompact(_totalOutgoing)}',
                  style: GoogleFonts.roboto(
                    color: kGrey,
                    fontSize: kFontSize12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPrimaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NetworkErrorWidget(
            errorMessage: _errorMessage,
            onRefresh: () => _loadTransactions(),
            title: 'Error Loading Transactions',
          ),
        ),
      );
    }

    final filteredTransactions = _getFilteredTransactions();

    if (filteredTransactions.isEmpty) {
      return _buildEmptyState();
    }

    return CustomRefreshIndicator(
      onRefresh: () => _loadTransactions(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        child: CardContainer(
          padding: EdgeInsets.zero,
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredTransactions.length +
                (_currentPage < _lastPage ? 1 : 0),
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: kGrey.shade200,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              if (index == filteredTransactions.length) {
                // Load more button
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: _isLoadingMore
                      ? const Center(
                          child:
                              CircularProgressIndicator(color: kPrimaryColor),
                        )
                      : TextButton(
                          onPressed: () => _loadTransactions(loadMore: true),
                          child: Text(
                            'Load More',
                            style: GoogleFonts.roboto(
                              color: kPrimaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                );
              }

              final transaction = filteredTransactions[index];
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
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (_tabController.index) {
      case 0:
        return CustomRefreshIndicator(
          onRefresh: () => _loadTransactions(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: EmptyStateWidget(
                message:
                    'No Successful Transactions\nYou have no successful transactions yet',
                iconWidget: SvgPicture.asset(
                  'assets/icons/success.svg',
                  height: kSize60,
                  width: kSize60,
                ),
              ),
            ),
          ),
        );
      case 1:
        message = 'No Pending Transactions\nYou have no pending transactions';
        icon = Icons.pending_outlined;
        break;
      case 2:
        message = 'No Withdrawals\nYou have not made any withdrawals yet';
        icon = Icons.account_balance_wallet_outlined;
        break;
      default:
        message = 'No Transactions\nYou have no transactions history';
        icon = Icons.receipt_long_outlined;
    }

    return CustomRefreshIndicator(
      onRefresh: () => _loadTransactions(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: EmptyStateWidget(
            message: message,
            icon: icon,
          ),
        ),
      ),
    );
  }
}
