import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/services/withdrawal_service.dart';
import 'package:cribs_agents/widgets/widgets.dart';

class BankAccountList extends StatelessWidget {
  final List<BankAccount> bankAccounts;
  final BankAccount? selectedAccount;
  final Function(BankAccount) onAccountSelected;
  final VoidCallback onAddAccount;

  const BankAccountList({
    super.key,
    required this.bankAccounts,
    required this.selectedAccount,
    required this.onAccountSelected,
    required this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Destination Account',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kGrey600,
                ),
              ),
              InkWell(
                onTap: onAddAccount,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add, size: 16, color: kPrimaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Add New',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: kPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bankAccounts.isEmpty)
            _buildNoBankState()
          else
            ...bankAccounts.map((account) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildBankAccountTile(account),
                )),
        ],
      ),
    );
  }

  Widget _buildNoBankState() {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: EmptyStateWidget(
        message:
            'No bank account added\nAdd a bank account to receive your funds',
        icon: Icons.account_balance_outlined,
      ),
    );
  }

  Widget _buildBankAccountTile(BankAccount account) {
    final isSelected = selectedAccount?.id == account.id;
    return InkWell(
      onTap: () => onAccountSelected(account),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withValues(alpha: 0.04) : kWhite,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kPrimaryColor : kGrey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? kPrimaryColor.withValues(alpha: 0.1)
                    : kGrey.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_rounded,
                color: isSelected ? kPrimaryColor : kGrey.shade400,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.bankName,
                    style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600,
                      fontSize: 13, // Slightly smaller for compactness
                      color: kBlack87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          account.accountName,
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
                        account.accountNumber,
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
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: kPrimaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: kWhite,
                  size: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
