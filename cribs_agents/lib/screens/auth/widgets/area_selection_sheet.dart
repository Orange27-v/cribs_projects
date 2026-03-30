import 'package:flutter/material.dart';
import '../../../constants.dart';
import '../../../widgets/widgets.dart';

class AreaSelectionBottomSheetContent extends StatefulWidget {
  final ScrollController scrollController;

  const AreaSelectionBottomSheetContent(
      {super.key, required this.scrollController});

  @override
  State<AreaSelectionBottomSheetContent> createState() =>
      _AreaSelectionBottomSheetContentState();
}

class _AreaSelectionBottomSheetContentState
    extends State<AreaSelectionBottomSheetContent> {
  late TextEditingController _searchController;
  List<Map<String, String>> _filteredStates = [];
  String? _currentSelectedArea;

  final List<Map<String, String>> _nigerianStates = [
    {'title': 'Lagos', 'subtitle': 'Ikeja'},
    {'title': 'Abuja', 'subtitle': 'FCT'},
    {'title': 'Delta', 'subtitle': 'Asaba'},
    {'title': 'Rivers', 'subtitle': 'Port Harcourt'},
    {'title': 'Abia', 'subtitle': 'Umuahia'},
    {'title': 'Adamawa', 'subtitle': 'Yola'},
    {'title': 'Akwa Ibom', 'subtitle': 'Uyo'},
    {'title': 'Anambra', 'subtitle': 'Awka'},
    {'title': 'Bauchi', 'subtitle': 'Bauchi'},
    {'title': 'Bayelsa', 'subtitle': 'Yenagoa'},
    {'title': 'Benue', 'subtitle': 'Makurdi'},
    {'title': 'Borno', 'subtitle': 'Maiduguri'},
    {'title': 'Cross River', 'subtitle': 'Calabar'},
    {'title': 'Ebonyi', 'subtitle': 'Abakaliki'},
    {'title': 'Edo', 'subtitle': 'Benin City'},
    {'title': 'Ekiti', 'subtitle': 'Ado Ekiti'},
    {'title': 'Enugu', 'subtitle': 'Enugu'},
    {'title': 'Gombe', 'subtitle': 'Gombe'},
    {'title': 'Imo', 'subtitle': 'Owerri'},
    {'title': 'Jigawa', 'subtitle': 'Dutse'},
    {'title': 'Kaduna', 'subtitle': 'Kaduna'},
    {'title': 'Kano', 'subtitle': 'Kano'},
    {'title': 'Katsina', 'subtitle': 'Katsina'},
    {'title': 'Kebbi', 'subtitle': 'Birnin Kebbi'},
    {'title': 'Kogi', 'subtitle': 'Lokoja'},
    {'title': 'Kwara', 'subtitle': 'Ilorin'},
    {'title': 'Nasarawa', 'subtitle': 'Lafia'},
    {'title': 'Niger', 'subtitle': 'Minna'},
    {'title': 'Ogun', 'subtitle': 'Abeokuta'},
    {'title': 'Ondo', 'subtitle': 'Akure'},
    {'title': 'Osun', 'subtitle': 'Oshogbo'},
    {'title': 'Oyo', 'subtitle': 'Ibadan'},
    {'title': 'Plateau', 'subtitle': 'Jos'},
    {'title': 'Sokoto', 'subtitle': 'Sokoto'},
    {'title': 'Taraba', 'subtitle': 'Jalingo'},
    {'title': 'Yobe', 'subtitle': 'Damaturu'},
    {'title': 'Zamfara', 'subtitle': 'Gusau'},
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filterStates('');
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterStates(_searchController.text);
  }

  void _filterStates(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStates = List.from(_nigerianStates);
      } else {
        _filteredStates = _nigerianStates.where((state) {
          final titleLower = state['title']!.toLowerCase();
          final subtitleLower = state['subtitle']!.toLowerCase();
          final queryLower = query.toLowerCase();
          return titleLower.contains(queryLower) ||
              subtitleLower.contains(queryLower);
        }).toList();
      }
    });
  }

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
                    image: AssetImage('assets/images/map_pin.png'),
                    width: 80,
                    height: 80,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    kSelectYourAreaTitle,
                    textAlign: TextAlign.center,
                    style: kDialogTitleStyle,
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    kSelectAreaText,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kBlack54, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 20),
                CustomTextField(
                  controller: _searchController,
                  labelText: kSearchAreaHint,
                  hintText: kSearchAreaExampleHint,
                  prefixIcon: Icons.search,
                ),
                const SizedBox(height: 16),
                ..._filteredStates.map(
                  (state) => Column(
                    children: [
                      AreaItem(
                        title: state['title']!,
                        subtitle: state['subtitle']!,
                        selected: _currentSelectedArea == state['title'],
                        onTap: () {
                          setState(() {
                            _currentSelectedArea = state['title'];
                          });
                        },
                      ),
                      const Divider(height: 1, color: kGrey),
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
              onPressed: _currentSelectedArea != null
                  ? () {
                      Navigator.pop(context, _currentSelectedArea);
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

class AreaItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const AreaItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.location_city,
        color: selected ? kPrimaryColor : kBlack54,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: selected ? kPrimaryColor : kBlack,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: selected ? kPrimaryColor : kBlack54,
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
