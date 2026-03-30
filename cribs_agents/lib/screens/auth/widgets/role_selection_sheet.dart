import 'package:flutter/material.dart';
import '../../../constants.dart';

class RoleSelectionBottomSheetContent extends StatefulWidget {
  final ScrollController scrollController;

  const RoleSelectionBottomSheetContent(
      {super.key, required this.scrollController});

  @override
  State<RoleSelectionBottomSheetContent> createState() =>
      _RoleSelectionBottomSheetContentState();
}

class _RoleSelectionBottomSheetContentState
    extends State<RoleSelectionBottomSheetContent> {
  String? _currentSelectedRole;

  final List<Map<String, dynamic>> _roles = [
    {'title': 'Agent', 'icon': Icons.person_search_rounded},
    {'title': 'Landlord', 'icon': Icons.person},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: kPaddingAll24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: ListView(
              controller: widget.scrollController,
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: kGrey.shade300,
                      borderRadius: kRadius10,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Image(
                    image: AssetImage('assets/images/avatar_person.png'),
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Select Your Role',
                    textAlign: TextAlign.center,
                    style: kDialogTitleStyle,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Please select if you are an Agent or a Landlord',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kBlack54, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                ..._roles.map(
                  (role) => Column(
                    children: [
                      RoleItem(
                        title: role['title']!,
                        icon: role['icon']!,
                        selected: _currentSelectedRole == role['title'],
                        onTap: () {
                          setState(() {
                            _currentSelectedRole = role['title'];
                          });
                        },
                      ),
                      const Divider(height: 4, color: kGrey),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _currentSelectedRole != null
                  ? () {
                      Navigator.pop(context, _currentSelectedRole);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: kPaddingV16,
                shape: const RoundedRectangleBorder(borderRadius: kRadius30),
                elevation: 0,
              ),
              child: Text(kContinueText, style: kDialogButtonTextStyle),
            ),
          ),
        ],
      ),
    );
  }
}

class RoleItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const RoleItem({
    super.key,
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: selected ? kPrimaryColor : kBlack54),
      title: Text(
        title,
        style: TextStyle(
          color: selected ? kPrimaryColor : kBlack,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.radio_button_checked, color: kPrimaryColor)
          : const Icon(Icons.radio_button_off, color: kBlack54),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: kRadius10,
        side: selected
            ? const BorderSide(color: kPrimaryColor, width: 1.5)
            : BorderSide.none,
      ),
      selected: selected,
      selectedTileColor: const Color(0xFFE3F0FB),
    );
  }
}
