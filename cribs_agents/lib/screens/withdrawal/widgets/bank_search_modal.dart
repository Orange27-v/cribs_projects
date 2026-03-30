import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/services/withdrawal_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BankSearchModal extends StatefulWidget {
  final List<Bank> banks;
  final ValueChanged<Bank> onSelect;

  const BankSearchModal({
    super.key,
    required this.banks,
    required this.onSelect,
  });

  @override
  State<BankSearchModal> createState() => _BankSearchModalState();
}

class _BankSearchModalState extends State<BankSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  List<Bank> _filteredBanks = [];

  @override
  void initState() {
    super.initState();
    _filteredBanks = widget.banks;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBanks = widget.banks.where((bank) {
        return bank.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: kGrey.shade200),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Select Bank',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: kBlack87,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: kGrey,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for your bank...',
                hintStyle: GoogleFonts.roboto(color: kGrey400),
                prefixIcon: const Icon(Icons.search, color: kGrey400),
                filled: true,
                fillColor: kGrey.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _filteredBanks.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: kGrey.shade100,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                final bank = _filteredBanks[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: kPrimaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        bank.name.isNotEmpty ? bank.name[0] : '?',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kPrimaryColor,
                        ),
                      ),
                    ),
                  ),
                  title: Text(
                    bank.name,
                    style: GoogleFonts.roboto(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: kBlack87,
                    ),
                  ),
                  onTap: () {
                    widget.onSelect(bank);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
