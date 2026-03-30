import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cribs_arena/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddTagBottomSheet extends StatefulWidget {
  final String chatIdentifier;
  final List<String> currentTags; // Add this to receive current tags

  const AddTagBottomSheet({
    super.key,
    required this.chatIdentifier,
    this.currentTags = const [], // Add this parameter
  });

  @override
  State<AddTagBottomSheet> createState() => _AddTagBottomSheetState();
}

class _AddTagBottomSheetState extends State<AddTagBottomSheet> {
  final TextEditingController _tagController = TextEditingController();
  List<String> _allTags = [];
  List<String> _userTags = [];

  @override
  void initState() {
    super.initState();
    _userTags = List.from(widget.currentTags); // Initialize with current tags
    _loadTags();
  }

  Future<void> _loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _allTags = prefs.getStringList('all_tags') ?? [];
      // Load user tags from preferences
      final savedUserTags =
          prefs.getStringList('user_tags_${widget.chatIdentifier}') ?? [];
      // Merge with current tags
      _userTags = {..._userTags, ...savedUserTags}.toList();
    });
  }

  Future<void> _addTag() async {
    if (_tagController.text.isEmpty) return;

    final newTag = _tagController.text.trim();

    final prefs = await SharedPreferences.getInstance();

    // Update state first for immediate UI update
    setState(() {
      // Add to all tags if not present
      if (!_allTags.contains(newTag)) {
        _allTags.add(newTag);
      }

      // Add to user tags if not present (auto-select new tag)
      if (!_userTags.contains(newTag)) {
        _userTags.add(newTag);
      }

      // Clear the text field
      _tagController.clear();
    });

    // Save to SharedPreferences after UI update
    await prefs.setStringList('all_tags', _allTags);
    await prefs.setStringList(
      'user_tags_${widget.chatIdentifier}',
      _userTags,
    );
  }

  Future<void> _toggleUserTag(String tag) async {
    setState(() {
      if (_userTags.contains(tag)) {
        _userTags.remove(tag);
      } else {
        _userTags.add(tag);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'user_tags_${widget.chatIdentifier}',
      _userTags,
    );
  }

  void _closeSheet() {
    Navigator.pop(context, _userTags);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Container(
        padding: kPaddingAll20,
        decoration: const BoxDecoration(
          color: kPrimaryColor,
          borderRadius: kRadius15Top,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Tag',
                  style: GoogleFonts.roboto(
                    color: kWhite,
                    fontWeight: FontWeight.bold,
                    fontSize: kFontSize18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: kWhite),
                  onPressed: _closeSheet,
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// INPUT TO CREATE NEW TAG
            TextField(
              controller: _tagController,
              decoration: InputDecoration(
                hintText: 'Enter Tag name',
                hintStyle: GoogleFonts.roboto(
                  color: kWhite.withValues(alpha: 0.7),
                ),
                border: const UnderlineInputBorder(
                  borderSide: BorderSide(color: kWhite),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add, color: kWhite),
                  onPressed: _addTag,
                ),
              ),
              style: const TextStyle(color: kWhite),
              onSubmitted: (_) => _addTag(),
            ),

            const SizedBox(height: 16),

            /// EXISTING TAGS
            if (_allTags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allTags.map((tag) {
                  final isSelected = _userTags.contains(tag);

                  return GestureDetector(
                    onTap: () => _toggleUserTag(tag),
                    child: Chip(
                      label: Text(tag),
                      backgroundColor: kPrimaryColor,
                      labelStyle: TextStyle(
                        color: kWhite,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: const BorderSide(color: kWhite),
                      avatar: isSelected
                          ? const Icon(Icons.check, color: kWhite, size: 16)
                          : SvgPicture.asset(
                              'assets/icons/tag.svg',
                              height: kFontSize16,
                              width: kFontSize16,
                              colorFilter: const ColorFilter.mode(
                                  kWhite, BlendMode.srcIn),
                            ),
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
