import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/screens/withdrawal/widgets/bank_search_modal.dart';
import 'package:cribs_agents/services/withdrawal_service.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class AddBankView extends StatelessWidget {
  final List<Bank> banks;
  final Bank? selectedBank;
  final ValueChanged<Bank?> onBankChanged;
  final TextEditingController accountNumberController;
  final ValueChanged<String> onAccountNumberChanged;
  final bool isVerifying;
  final String? verifiedAccountName;
  final bool isSavingBank;
  final VoidCallback? onSave;
  final VoidCallback onBack;

  const AddBankView({
    super.key,
    required this.banks,
    required this.selectedBank,
    required this.onBankChanged,
    required this.accountNumberController,
    required this.onAccountNumberChanged,
    required this.isVerifying,
    required this.verifiedAccountName,
    required this.isSavingBank,
    required this.onSave,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Padding(
                      padding: EdgeInsets.only(left: 6.0),
                      child: Icon(Icons.arrow_back_ios,
                          size: 18, color: kPrimaryColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Add Bank Account',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Bank',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kGrey600,
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => BankSearchModal(
                        banks: banks,
                        onSelect: onBankChanged,
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: kGrey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance,
                          color: selectedBank != null
                              ? kPrimaryColor
                              : kGrey.shade400,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            selectedBank?.name ?? 'Choose your bank',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: selectedBank != null
                                  ? kBlack87
                                  : kGrey.shade400,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: kGrey.shade600,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kWhite,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Number',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kGrey600,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: accountNumberController,
                  enabled: selectedBank != null,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1.2,
                    color: selectedBank != null ? kBlack87 : kGrey400,
                  ),
                  decoration: InputDecoration(
                    hintText: selectedBank != null
                        ? '0000000000'
                        : 'Select bank first',
                    hintStyle: GoogleFonts.roboto(
                      color: kGrey.shade300,
                      letterSpacing: 1.2,
                    ),
                    counterText: '',
                    filled: true,
                    fillColor: selectedBank != null ? kGrey100 : kGrey200,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: kGrey.shade200),
                    ),
                    disabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: kGrey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: kPrimaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.numbers,
                      color: selectedBank == null
                          ? kGrey400
                          : (accountNumberController.text.length == 10
                              ? kPrimaryColor
                              : kGrey.shade400),
                    ),
                  ),
                  onChanged: onAccountNumberChanged,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 12, color: kGrey.shade400),
                    const SizedBox(width: 6),
                    Text(
                      'Enter your 10-digit account number',
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: kGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (isVerifying)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: kPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Verifying account...',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: kGrey600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else if (verifiedAccountName != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: kWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.verified_rounded,
                      color: Colors.green.shade600,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/icons/success.svg',
                              height: 14,
                              width: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Account Verified',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          verifiedAccountName!,
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'Save Bank Account',
            onPressed: onSave,
            isLoading: isSavingBank,
          ),
        ],
      ),
    );
  }
}
