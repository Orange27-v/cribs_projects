import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:cribs_agents/services/wallet_service.dart';
import 'package:cribs_agents/services/withdrawal_service.dart';
import 'package:intl/intl.dart';

// Widgets
import 'widgets/balance_card.dart';
import 'widgets/withdrawal_amount_input.dart';
import 'widgets/bank_account_list.dart';
import 'widgets/withdraw_button.dart';
import 'widgets/add_bank_view.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen>
    with SingleTickerProviderStateMixin {
  final WalletService _walletService = WalletService();
  final WithdrawalService _withdrawalService = WithdrawalService();
  final TextEditingController _amountController = TextEditingController();

  // State
  bool _isLoading = true;
  bool _isWithdrawing = false;
  String? _errorMessage;
  double _platformFee = 0.0;
  bool _isVerified = false;
  int _currentStep = 0; // 0: Bank Selection, 1: Amount Input
  double _amount = 0.0;

  // Wallet data
  double _availableBalance = 0.0;
  double _pendingBalance = 0.0;

  // Bank accounts
  List<BankAccount> _bankAccounts = [];
  BankAccount? _selectedAccount;

  // Add bank flow
  bool _showAddBankFlow = false;
  List<Bank> _banks = [];
  Bank? _selectedBank;
  final TextEditingController _accountNumberController =
      TextEditingController();
  String? _verifiedAccountName;
  bool _isVerifying = false;
  bool _isSavingBank = false;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _amountController.addListener(_onAmountChanged);
    _loadData();
  }

  @override
  void dispose() {
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _accountNumberController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final text = _amountController.text.replaceAll(',', '');
    setState(() {
      _amount = double.tryParse(text) ?? 0.0;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _walletService.getWallet(),
        _withdrawalService.getBankAccounts(),
        _walletService.getPlatformFee(),
      ]);

      final walletResult = results[0] as Map<String, dynamic>;
      final bankResult = results[1] as Map<String, dynamic>;
      final feeResult = results[2] as double;

      if (mounted) {
        setState(() {
          _isLoading = false;
          _platformFee = feeResult;

          if (walletResult['success'] == true) {
            final wallet = walletResult['wallet'];
            _availableBalance = (wallet?['available_balance'] ?? 0).toDouble();
            _pendingBalance = (wallet?['pending_balance'] ?? 0).toDouble();

            final agent = walletResult['agent'];
            _isVerified = (agent?['nin_verification'] == 1 &&
                agent?['bvn_verification'] == 1);
          } else {
            _errorMessage = walletResult['message'];
          }

          if (bankResult['success'] == true) {
            _bankAccounts = bankResult['bank_accounts'] as List<BankAccount>;
            // Auto-select default or first account
            _selectedAccount = _bankAccounts.isNotEmpty
                ? _bankAccounts.firstWhere(
                    (a) => a.isDefault,
                    orElse: () => _bankAccounts.first,
                  )
                : null;
          }
        });
        _animationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadBanks() async {
    final result = await _withdrawalService.getBanks();
    if (result['success'] == true && mounted) {
      setState(() {
        _banks = result['banks'] as List<Bank>;
      });
    }
  }

  Future<void> _verifyAccount() async {
    if (_selectedBank == null || _accountNumberController.text.length != 10) {
      _showSnackBar('Please select a bank and enter 10-digit account number',
          isError: true);
      return;
    }

    setState(() {
      _isVerifying = true;
      _verifiedAccountName = null;
    });

    final result = await _withdrawalService.verifyBankAccount(
      accountNumber: _accountNumberController.text,
      bankCode: _selectedBank!.code,
    );

    if (mounted) {
      setState(() {
        _isVerifying = false;
        if (result['success'] == true) {
          _verifiedAccountName = result['account_name'];
        } else {
          _showSnackBar(result['message'] ?? 'Verification failed',
              isError: true);
        }
      });
    }
  }

  Future<void> _saveBankAccount() async {
    if (_selectedBank == null || _verifiedAccountName == null) {
      return;
    }

    setState(() {
      _isSavingBank = true;
    });

    final result = await _withdrawalService.saveBankAccount(
      accountNumber: _accountNumberController.text,
      bankCode: _selectedBank!.code,
      bankName: _selectedBank!.name,
      accountName: _verifiedAccountName!,
    );

    if (mounted) {
      setState(() {
        _isSavingBank = false;
      });

      if (result['success'] == true) {
        _showSnackBar('Bank account saved successfully!', isError: false);
        _resetAddBankFlow();
        _loadData(); // Reload to see new account
      } else {
        _showSnackBar(result['message'] ?? 'Failed to save bank account',
            isError: true);
      }
    }
  }

  void _resetAddBankFlow() {
    setState(() {
      _showAddBankFlow = false;
      _selectedBank = null;
      _accountNumberController.clear();
      _verifiedAccountName = null;
    });
  }

  Future<void> _initiateWithdrawal() async {
    if (!_isVerified) {
      _showSnackBar('Please verify your NIN and BVN to complete withdrawal',
          isError: true);
      return;
    }

    if (_amount == 0 || (_amount - _platformFee) < 1000) {
      _showSnackBar(
          'Minimum withdrawal amount after fee must be at least ₦1,000',
          isError: true);
      return;
    }

    if (_amount > _availableBalance) {
      _showSnackBar('Insufficient balance', isError: true);
      return;
    }

    if (_selectedAccount == null) {
      _showSnackBar('Please select a bank account', isError: true);
      return;
    }

    // Confirmation Dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: kWhite,
        shape: RoundedRectangleBorder(borderRadius: kRadius16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kPrimaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: kPrimaryColor,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Confirm Withdrawal',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kGrey100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Requested Amount',
                            style: GoogleFonts.roboto(color: kGrey600)),
                        Text(
                          _formatCurrency(_amount),
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600, color: kBlack87),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Platform Fee',
                            style: GoogleFonts.roboto(color: kGrey600)),
                        Text(
                          '- ${_formatCurrency(_platformFee)}',
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade600),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('You\'ll Receive',
                            style: GoogleFonts.roboto(
                                color: kPrimaryColor,
                                fontWeight: FontWeight.bold)),
                        Text(
                          _formatCurrency(_amount - _platformFee),
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: kPrimaryColor),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: kGrey.shade300),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.roboto(
                              color: kGrey600, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: kPrimaryColor,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Confirm',
                          style: GoogleFonts.roboto(
                              color: kWhite, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isWithdrawing = true;
    });

    final result = await _withdrawalService.withdraw(
      amount: _amount,
      recipientId: _selectedAccount!.id,
    );

    if (mounted) {
      setState(() {
        _isWithdrawing = false;
      });

      if (result['success'] == true) {
        _showSnackBar('Withdrawal initiated successfully!', isError: false);
        _amountController.clear();
        Navigator.pop(context); // Go back to dashboard on success
      } else {
        _showSnackBar(result['message'] ?? 'Withdrawal failed', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            isError
                ? const Icon(
                    Icons.error_outline,
                    color: kWhite,
                  )
                : SvgPicture.asset(
                    'assets/icons/success.svg',
                    height: 24,
                    width: 24,
                  ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.roboto(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'en_NG',
      symbol: '₦',
      decimalDigits: 2,
    ).format(amount);
  }

  void _handleBack() {
    if (_showAddBankFlow) {
      _resetAddBankFlow();
    } else if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.pop(context);
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
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: _handleBack,
          color: kPrimaryColor,
        ),
        title: Text(
          _showAddBankFlow
              ? 'Add Bank Account'
              : (_currentStep == 0 ? 'Select Account' : 'Enter Amount'),
          style: GoogleFonts.roboto(
            color: kPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : _errorMessage != null
              ? _buildErrorState()
              : _showAddBankFlow
                  ? AddBankView(
                      banks: _banks,
                      selectedBank: _selectedBank,
                      onBankChanged: (bank) {
                        setState(() {
                          _selectedBank = bank;
                          _verifiedAccountName = null;
                        });
                      },
                      accountNumberController: _accountNumberController,
                      onAccountNumberChanged: (value) {
                        if (value.length == 10 && _selectedBank != null) {
                          _verifyAccount();
                        } else {
                          setState(() {
                            _verifiedAccountName = null;
                          });
                        }
                      },
                      isVerifying: _isVerifying,
                      verifiedAccountName: _verifiedAccountName,
                      isSavingBank: _isSavingBank,
                      onSave: _verifiedAccountName != null && !_isSavingBank
                          ? _saveBankAccount
                          : null,
                      onBack: _resetAddBankFlow,
                    )
                  : _buildCurrentStep(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: NetworkErrorWidget(
          errorMessage: _errorMessage,
          onRefresh: _loadData,
          title: 'Error Loading Wallet',
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BalanceCard(
              availableBalance: _availableBalance,
              pendingBalance: _pendingBalance,
            ),
            const SizedBox(height: 24),
            if (_currentStep == 0)
              _buildBankSelectionStep()
            else
              _buildAmountInputStep(),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSelectionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BankAccountList(
          bankAccounts: _bankAccounts,
          selectedAccount: _selectedAccount,
          onAccountSelected: (account) {
            setState(() {
              _selectedAccount = account;
            });
          },
          onAddAccount: () {
            _loadBanks();
            setState(() {
              _showAddBankFlow = true;
            });
          },
        ),
        const SizedBox(height: 32),
        PrimaryButton(
          text: 'Proceed',
          onPressed: _selectedAccount != null
              ? () {
                  setState(() {
                    _currentStep = 1;
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildAmountInputStep() {
    final netReceivable = _amount > _platformFee ? _amount - _platformFee : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected Account Summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kGrey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kGrey.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_rounded,
                  color: kGrey.shade400,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedAccount?.bankName ?? '',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: kBlack87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _selectedAccount?.accountName ?? '',
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: kGrey600,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text('•',
                              style: GoogleFonts.roboto(
                                  fontSize: 10, color: kGrey400)),
                        ),
                        Text(
                          _selectedAccount?.accountNumber ?? '',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: kGrey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 0;
                  });
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Change',
                  style: GoogleFonts.roboto(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        WithdrawalAmountInput(controller: _amountController),
        const SizedBox(height: 24),

        // Fee Breakdown (Reusing requested UI)
        if (_amount > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kPrimaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: kPrimaryColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                _buildBreakdownRow(
                    'Withdrawal Amount', '₦ ${_amount.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _buildBreakdownRow(
                    'Platform Fee', '- ₦ ${_platformFee.toStringAsFixed(2)}',
                    isNegative: true),
                const Divider(height: 24),
                _buildBreakdownRow(
                  'Estimated Wallet Debit',
                  '₦ ${netReceivable.toStringAsFixed(2)}',
                  isTotal: true,
                ),
              ],
            ),
          ),

        const SizedBox(height: 32),
        WithdrawButton(
          onPressed:
              !_isWithdrawing && _amount > 0 ? _initiateWithdrawal : null,
          isWithdrawing: _isWithdrawing,
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
