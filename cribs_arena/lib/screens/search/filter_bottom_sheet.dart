import 'package:flutter/material.dart';
import '../../constants.dart'; // Adjust path as necessary for constants.dart
import '../../widgets/widgets.dart'; // Import the common widgets file (assuming PrimaryButton is here)

// Note: flutter_svg is not used directly in this particular file's build method,
// so its import can be removed if not needed elsewhere in this file.
// import 'package:flutter_svg/flutter_svg.dart';

// Define an enum for transaction types for better readability and type safety
enum TransactionType { buying, renting }

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  // State to manage the selected transaction type (Buying/Renting)
  // Defaulting to Renting as it's more common.
  TransactionType _selectedTransactionType = TransactionType.renting;

  // --- Property Type Chips ---
  String? _selectedPropertyType; // Nullable string for selected property type

  // Separate lists for buying and renting property types
  final List<String> _buyingPropertyTypes = [
    'Apartment',
    'House',
    'Land', // Land is typically for buying
    'Commercial Space'
  ];
  final List<String> _rentingPropertyTypes = [
    'Apartment',
    'House',
    'Studio', // Studio is more common for renting
    'Commercial Space'
  ];

  // --- Price Range Chips ---
  String? _selectedPriceRange; // Nullable string for selected price range

  // Updated lists for buying and renting price ranges as per new requirements
  final List<String> _buyingPriceRanges = [
    'Under 50M',
    '50M - 500M',
    '500M - 5B',
    '5B+',
    'Negotiable' // Changed from 'Flexible'
  ];

  final List<String> _rentingPriceRanges = [
    'Under 50K/month', // For very basic or smaller units
    '50K - 250K/month', // Mid-range apartments/houses
    '250K - 750K/month', // Higher-end apartments/houses
    '750K+/month', // Premium or very large residential, or smaller commercial
    'Negotiable'
  ];

  // --- Bedroom/Bathroom Sliders ---
  RangeValues _bedroomCount = const RangeValues(0, 10);
  RangeValues _bathroomCount = const RangeValues(0, 10);

  // --- Renting-Specific: Furnishing Status Chips ---
  String?
      _selectedFurnishingStatus; // Nullable string for selected furnishing status
  final List<String> _furnishingOptions = [
    'Unfurnished',
    'Semi-furnished',
    'Fully-furnished'
  ];

  // Helper to reset selections when transaction type changes
  void _resetFilters() {
    setState(() {
      _selectedPropertyType = null;
      _selectedPriceRange = null;
      _selectedFurnishingStatus = null; // Reset furnishing status too
      _bedroomCount = const RangeValues(0, 10); // Reset sliders to default
      _bathroomCount = const RangeValues(0, 10);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine which property types and price ranges to display
    final List<String> currentPropertyTypes =
        _selectedTransactionType == TransactionType.buying
            ? _buyingPropertyTypes
            : _rentingPropertyTypes;

    final List<String> currentPriceRanges =
        _selectedTransactionType == TransactionType.buying
            ? _buyingPriceRanges
            : _rentingPriceRanges;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * kMinHeight07,
        maxHeight: MediaQuery.of(context).size.height * kMaxHeight09,
      ),
      padding: kPaddingH24V16.copyWith(
        bottom: MediaQuery.of(context).padding.bottom + kPaddingH24V16.bottom,
      ),
      decoration: const BoxDecoration(
        color: kWhite,
        borderRadius: kRadius20Top,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Close button at the top right, inside the sheet
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.close, color: kBlack),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: kSizedBoxH8),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Buying / Renting Toggle Tabs
                  _buildTransactionTypeToggle(),
                  const SizedBox(height: kSizedBoxH24),

                  // --- Property Section with Chips (Dynamic based on transaction type) ---
                  Text(
                    kPropertyText,
                    style: kDialogTitleStyle.copyWith(
                        fontSize: kFontSize18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: kSizedBoxH16),
                  Wrap(
                    spacing: kSizedBoxW8,
                    runSpacing: kSizedBoxH8,
                    children: currentPropertyTypes.map((type) {
                      final isSelected = _selectedPropertyType == type;
                      return FilterChipWidget(
                        label: type,
                        isSelected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPropertyType = selected ? type : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: kSizedBoxH24),

                  // --- Price Range Section with Chips (Dynamic based on transaction type) ---
                  Text(
                    kPriceRangeText,
                    style: kDialogTitleStyle.copyWith(
                        fontSize: kFontSize18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: kSizedBoxH16),
                  Wrap(
                    spacing: kSizedBoxW8,
                    runSpacing: kSizedBoxH8,
                    children: currentPriceRanges.map((range) {
                      final isSelected = _selectedPriceRange == range;
                      return FilterChipWidget(
                        label: range,
                        isSelected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedPriceRange = selected ? range : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: kSizedBoxH24),

                  // --- Bedroom Count Slider ---
                  Text(
                    kBedroomCountText,
                    style: kDialogTitleStyle.copyWith(
                        fontSize: kFontSize18, fontWeight: FontWeight.w500),
                  ),
                  RangeSlider(
                    values: _bedroomCount,
                    min: 0,
                    max: kMaxSliderValue,
                    divisions: kMaxSliderValue.toInt(),
                    labels: RangeLabels(
                      _bedroomCount.start.round().toString(),
                      _bedroomCount.end.round() == kMaxSliderValue
                          ? '${kMaxSliderValue.toInt()}+'
                          : _bedroomCount.end.round().toString(),
                    ),
                    activeColor: kPrimaryColor,
                    inactiveColor: kGrey100,
                    onChanged: (RangeValues values) {
                      setState(() {
                        _bedroomCount = values;
                      });
                    },
                  ),
                  const Padding(
                    padding: kPaddingH16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(kZeroText, style: TextStyle(color: kBlack54)),
                        Text(kFiveText, style: TextStyle(color: kBlack54)),
                        Text(kTenPlusText, style: TextStyle(color: kBlack54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSizedBoxH24),

                  // --- Bathroom Count Slider ---
                  Text(
                    kBathroomCountText,
                    style: kDialogTitleStyle.copyWith(
                        fontSize: kFontSize18, fontWeight: FontWeight.w500),
                  ),
                  RangeSlider(
                    values: _bathroomCount,
                    min: 0,
                    max: kMaxSliderValue,
                    divisions: kMaxSliderValue.toInt(),
                    labels: RangeLabels(
                      _bathroomCount.start.round().toString(),
                      _bathroomCount.end.round() == kMaxSliderValue
                          ? '${kMaxSliderValue.toInt()}+'
                          : _bathroomCount.end.round().toString(),
                    ),
                    activeColor: kPrimaryColor,
                    inactiveColor: kGrey100,
                    onChanged: (RangeValues values) {
                      setState(() {
                        _bathroomCount = values;
                      });
                    },
                  ),
                  const Padding(
                    padding: kPaddingH16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(kZeroText, style: TextStyle(color: kBlack54)),
                        Text(kFiveText, style: TextStyle(color: kBlack54)),
                        Text(kTenPlusText, style: TextStyle(color: kBlack54)),
                      ],
                    ),
                  ),
                  const SizedBox(height: kSizedBoxH32),

                  // --- Renting-Specific: Furnishing Status ---
                  // This section only appears when 'Renting' is selected
                  if (_selectedTransactionType == TransactionType.renting) ...[
                    Text(
                      kFurnishingStatusText,
                      style: kDialogTitleStyle.copyWith(
                          fontSize: kFontSize18, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: kSizedBoxH16),
                    Wrap(
                      spacing: kSizedBoxW8,
                      runSpacing: kSizedBoxH8,
                      children: _furnishingOptions.map((status) {
                        final isSelected = _selectedFurnishingStatus == status;
                        return FilterChipWidget(
                          label: status,
                          isSelected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedFurnishingStatus =
                                  selected ? status : null;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: kSizedBoxH32),
                  ],
                ],
              ),
            ),
          ),

          // Apply Search Button - Fixed at bottom
          PrimaryButton(
            text: 'Apply Search',
            onPressed: () {
              // Create filter data map
              final filterData = {
                'transactionType':
                    _selectedTransactionType == TransactionType.buying
                        ? 'For Sale'
                        : 'For Rent',
                'propertyType': _selectedPropertyType,
                'priceRange': _selectedPriceRange,
                'bedroomMin': _bedroomCount.start.round(),
                'bedroomMax': _bedroomCount.end.round() == kMaxSliderValue
                    ? null
                    : _bedroomCount.end.round(),
                'bathroomMin': _bathroomCount.start.round(),
                'bathroomMax': _bathroomCount.end.round() == kMaxSliderValue
                    ? null
                    : _bathroomCount.end.round(),
                'furnishingStatus': _selectedFurnishingStatus,
              };

              debugPrint('🔍 Applying filters: $filterData');
              Navigator.pop(context, filterData);
            },
          ),
        ],
      ),
    );
  }

  // --- Helper Methods ---

  // Helper to build the Buying/Renting toggle bar
  Widget _buildTransactionTypeToggle() {
    return Container(
      height: kSizedBoxH40,
      decoration: BoxDecoration(
        color: kGrey100,
        borderRadius: kRadius16,
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTransactionType = TransactionType.renting;
                  _resetFilters(); // Reset filters when changing type
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTransactionType == TransactionType.renting
                      ? kPrimaryColorOpacity01
                      : Colors.transparent,
                  borderRadius: kRadius8,
                ),
                child: Text(
                  kRentingText,
                  style: TextStyle(
                    color: _selectedTransactionType == TransactionType.renting
                        ? kPrimaryColor
                        : kBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTransactionType = TransactionType.buying;
                  _resetFilters(); // Reset filters when changing type
                });
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTransactionType == TransactionType.buying
                      ? kPrimaryColorOpacity01
                      : Colors.transparent,
                  borderRadius: kRadius8,
                ),
                child: Text(
                  kBuyingText,
                  style: TextStyle(
                    color: _selectedTransactionType == TransactionType.buying
                        ? kPrimaryColor
                        : kBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable widget for the filter chips (Property Type, Price Range, Furnishing Status).
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const FilterChipWidget({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: kPrimaryColor,
      backgroundColor: kWhite,
      labelStyle: TextStyle(
        color: isSelected ? kWhite : kBlack,
        fontWeight: FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? kPrimaryColor : kGrey400,
        width: kSizedBoxH1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: kRadius8,
      ),
      padding: kPaddingH12V8,
    );
  }
}
