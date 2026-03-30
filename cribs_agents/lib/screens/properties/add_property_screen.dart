import 'dart:io';
import 'package:cribs_agents/widgets/custom_pill_switch.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cribs_agents/constants.dart';
import 'package:cribs_agents/services/property_service.dart';
import 'package:cribs_agents/services/plan_service.dart';
import 'package:cribs_agents/screens/plans/plans_screen.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/screens/agents/user_widgets/map_controls.dart';
import 'package:geolocator/geolocator.dart';

class AddPropertyScreen extends StatefulWidget {
  const AddPropertyScreen({super.key});

  @override
  State<AddPropertyScreen> createState() => _AddPropertyScreenState();
}

class _AddPropertyScreenState extends State<AddPropertyScreen> {
  String _selectedPropertyType = 'House';
  int _bedrooms = 0;
  int _bathrooms = 0;
  int _kitchens = 0;
  int _toilets = 0;
  int _livingRooms = 0;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  GoogleMapController? _mapController;
  static const LatLng _initialPosition =
      LatLng(6.5244, 3.3792); // Lagos fallback

  int _descriptionWordCount = 0;

  final List<bool> _listingTypeSelection = [
    true,
    false,
  ]; // [For Sale, For Rent]
  final Set<String> _selectedAmenities = {};
  final List<String> _amenities = [
    'Swimming Pool',
    'Gym',
    'Parking Space',
    'Air Conditioning',
    'Balcony',
    'Security',
    'Furnished',
    'Wifi',
    'Elevator',
    'Constant Power',
    'Water',
    'Good Roads',
    'Accessible to Town',
    'Near Market',
    'Near Hospital',
    'Near Police Station',
    'Near Church',
    'Near RCCG Church',
    'Near Express Road',
  ];

  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _propertySizeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.addListener(_updateWordCount);
    _getCurrentLocation();
    _checkSubscriptionStatus();
  }

  /// Check if agent has active subscription and available uploads
  Future<void> _checkSubscriptionStatus() async {
    final planService = PlanService();
    final subscription = await planService.getCurrentSubscription();

    if (!mounted) return;

    // No active subscription
    if (subscription == null || subscription['status'] != 'Active') {
      _showSubscriptionRequiredDialog();
      return;
    }

    // Check if subscription has expired
    final endDateStr = subscription['end_date'];
    if (endDateStr != null) {
      try {
        final endDate = DateTime.parse(endDateStr);
        if (DateTime.now().isAfter(endDate)) {
          _showSubscriptionRequiredDialog();
          return;
        }
      } catch (e) {
        debugPrint('Error parsing subscription end date: $e');
      }
    }

    // Check upload limit
    final uploadCount = subscription['upload_count'] ?? 0;
    final propertyLimit = subscription['property_limit'] ?? 5;

    if (uploadCount >= propertyLimit) {
      _showUpgradePlanDialog(uploadCount, propertyLimit);
    }
  }

  void _showSubscriptionRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CustomAlertDialog(
        title: Row(
          children: [
            Icon(Icons.subscriptions_outlined, color: kPrimaryColor),
            const SizedBox(width: 12),
            const Expanded(child: Text('Subscription Required')),
          ],
        ),
        content: const Text(
          'You need an active subscription to upload properties. Please subscribe to a plan to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Go back from add property screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PlansScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kWhite,
            ),
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }

  void _showUpgradePlanDialog(int currentCount, int limit) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => CustomAlertDialog(
        title: Row(
          children: [
            Icon(Icons.upgrade_outlined, color: Colors.orange),
            const SizedBox(width: 12),
            const Expanded(child: Text('Upload Limit Reached')),
          ],
        ),
        content: Text(
          'You have used all $limit property uploads for your current plan. Upgrade to a higher plan to list more properties.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // Go back from add property screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const PlansScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimaryColor,
              foregroundColor: kWhite,
            ),
            child: const Text('Upgrade Plan'),
          ),
        ],
      ),
    );
  }

  void _updateWordCount() {
    final text = _descriptionController.text.trim();
    setState(() {
      _descriptionWordCount =
          text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: kRed,
              ),
            );
          }
          setState(() {
            _selectedLocation = _initialPosition;
            _currentLocation = _initialPosition;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
              backgroundColor: kRed,
            ),
          );
        }
        setState(() {
          _selectedLocation = _initialPosition;
          _currentLocation = _initialPosition;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _selectedLocation = _currentLocation;
        });

        // Move camera to current location
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _currentLocation!,
              zoom: 14.0,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _selectedLocation = _initialPosition;
          _currentLocation = _initialPosition;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _propertySizeController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _recenterMap() {
    final target = _currentLocation ?? _initialPosition;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 14.0),
      ),
    );
  }

  final PropertyService _propertyService = PropertyService();
  bool _isLoading = false;

  Future<void> _submitPropertyDetails() async {
    // Helper function for Sentence Case
    String toSentenceCase(String text) {
      if (text.isEmpty) return text;
      final trimmed = text.trim();
      if (trimmed.isEmpty) return trimmed;
      if (trimmed.length == 1) return trimmed.toUpperCase();
      return trimmed[0].toUpperCase() + trimmed.substring(1);
    }

    // Validate required fields
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a property title'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    if (_addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a property address'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a property price'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    if (_propertySizeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the property size'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    // Strict Integer Validation for Price
    final priceText = _priceController.text.replaceAll(',', '').trim();
    final priceInt = int.tryParse(priceText);
    if (priceInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price must be a valid whole number (no decimals)'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    // Strict Integer Validation for Property Size
    final sizeText = _propertySizeController.text.replaceAll(',', '').trim();
    final sizeInt = int.tryParse(sizeText);
    if (sizeInt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Property size must be a valid whole number'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    // Word Count Validation
    if (_descriptionWordCount > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Description cannot exceed 200 words (Current: $_descriptionWordCount)'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final listingType = _listingTypeSelection[0] ? 'For Sale' : 'For Rent';

      // Apply Sentence Case
      final title = toSentenceCase(_titleController.text);
      final address = toSentenceCase(_addressController.text);
      final description = toSentenceCase(_descriptionController.text);
      final location = address.split(',').first.trim();

      final result = await _propertyService.addProperty(
        title: title,
        type: _selectedPropertyType,
        location: location,
        listingType: listingType,
        price: priceInt.toDouble(),
        beds: _bedrooms,
        baths: _bathrooms,
        sqft: sizeInt.toString(),
        description: description,
        address: address,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
        amenities: _selectedAmenities.toList(),
        propertyImages: _selectedImages,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Property added successfully!'),
              backgroundColor: kPrimaryColor,
            ),
          );
          // Navigate back to properties list
          Navigator.of(context).pop(true);
        } else {
          // Check for subscription-related errors from backend
          if (result['requires_subscription'] == true) {
            _showSubscriptionRequiredDialog();
            return;
          }

          if (result['limit_reached'] == true) {
            final currentCount = result['current_count'] ?? 0;
            final limit = result['limit'] ?? 5;
            _showUpgradePlanDialog(currentCount, limit);
            return;
          }

          String mainMessage = result['message'] ?? 'Failed to add property';
          String detailedErrors = '';

          if (result['errors'] != null) {
            debugPrint('Raw Validation Errors: ${result['errors']}');
            final errors = result['errors'] as Map<String, dynamic>;

            // Create a clean list of errors
            final List<String> errorMessages = [];
            errors.forEach((field, messages) {
              String messageStr = '';
              if (messages is List) {
                // Usually the first error is the most relevant one
                messageStr = messages.first.toString();
              } else {
                messageStr = messages.toString();
              }
              errorMessages.add('• $messageStr');
            });

            detailedErrors = errorMessages.join('\n');
          }

          final String finalMessage = detailedErrors.isNotEmpty
              ? 'Please fix the following errors:\n$detailedErrors'
              : mainMessage;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                finalMessage,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
              backgroundColor: kRed,
              duration: const Duration(seconds: 8),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error adding property: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: kRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kGrey100,
      appBar: const PrimaryAppBar(
        title: Text('LIST PROPERTY'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: kPaddingAll12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListingDetailsSection(),
              const SizedBox(height: kSizedBoxH24),
              _buildPropertyDetailsSection(),
              const SizedBox(height: kSizedBoxH24),
              _buildFeaturesSection(),
              const SizedBox(height: kSizedBoxH24),
              _buildAmenitiesSection(),
              const SizedBox(height: kSizedBoxH24),
              _buildImageUploadSection(),
              const SizedBox(height: kSizedBoxH32),
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: kPrimaryColor),
                    )
                  : PrimaryButton(
                      text: 'List Property',
                      onPressed: _submitPropertyDetails,
                    ),
              const SizedBox(height: kSizedBoxH24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyDetailsSection() {
    return Container(
      padding: kPaddingAll12,
      decoration: const BoxDecoration(color: kWhite, borderRadius: kRadius12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPropertyTypeSelector(),
          const SizedBox(height: kSizedBoxH24),
          LabeledTextField(
            label: 'Property Title',
            hintText: 'Enter Property name',
            controller: _titleController,
          ),
          const SizedBox(height: kSizedBoxH24),
          LabeledTextField(
            label: 'Address',
            hintText: 'Enter Property address',
            controller: _addressController,
          ),
          const SizedBox(height: kSizedBoxH24),
          _buildEmbeddedMapPicker(),
          const SizedBox(height: kSizedBoxH24),
          LabeledTextField(
            label: 'Description',
            hintText: 'Describe your property',
            controller: _descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Word count: $_descriptionWordCount/200',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: _descriptionWordCount > 200 ? kRed : kGrey600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingDetailsSection() {
    return Container(
      padding: kPaddingAll12,
      decoration: const BoxDecoration(color: kWhite, borderRadius: kRadius12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listing Details', style: _headerStyle()),
          const SizedBox(height: kSizedBoxH16),
          CustomPillSwitch(
            selectedIndex: _listingTypeSelection[0] ? 0 : 1,
            labels: const ['For Sale', 'For Rent'],
            icons: const [Icons.sell_outlined, Icons.receipt_long_outlined],
            onTabSelected: (index) {
              setState(() {
                for (int i = 0; i < _listingTypeSelection.length; i++) {
                  _listingTypeSelection[i] = i == index;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    return Container(
      padding: kPaddingAll12,
      decoration: const BoxDecoration(color: kWhite, borderRadius: kRadius12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Features', style: _headerStyle()),
          const SizedBox(height: kSizedBoxH16),
          _buildFeatureSelectors(),
          const SizedBox(height: kSizedBoxH24),
          LabeledTextField(
            label: 'Property Size (Sq. ft)',
            hintText: 'Enter total area',
            controller: _propertySizeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: kSizedBoxH24),
          LabeledTextField(
            label: 'Price',
            hintText: 'Enter property price',
            controller: _priceController,
            keyboardType: TextInputType.number,
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Container(
      padding: kPaddingAll12,
      decoration: const BoxDecoration(color: kWhite, borderRadius: kRadius12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amenities', style: _headerStyle()),
          const SizedBox(height: kSizedBoxH16),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: _amenities.map((amenity) {
                    final isSelected = _selectedAmenities.contains(amenity);
                    return _buildAmenityChip(
                      amenity,
                      isSelected,
                      () {
                        setState(() {
                          if (isSelected) {
                            _selectedAmenities.remove(amenity);
                          } else {
                            _selectedAmenities.add(amenity);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(
      String label, bool isSelected, VoidCallback onToggle) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor.withValues(alpha: 0.08) : kWhite,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? kPrimaryColor : kGrey300,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kPrimaryColor.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 16, color: kPrimaryColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: isSelected ? kPrimaryColor : kGrey700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Container(
      padding: kPaddingAll12,
      decoration: const BoxDecoration(color: kWhite, borderRadius: kRadius12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload images of property', style: _headerStyle()),
          const SizedBox(height: kSizedBoxH16),
          _buildImageUploaders(),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return GoogleFonts.roboto(
      fontSize: kFontSize16,
      fontWeight: FontWeight.w500,
      color: kBlack87,
    );
  }

  Widget _buildPropertyTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Select property type', style: _headerStyle()),
        Container(
          padding: kPaddingH12,
          decoration: BoxDecoration(
            color: kWhite,
            border: Border.all(color: kGrey.withValues(alpha: 0.5)),
            borderRadius: kRadius12,
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: kWhite,
              value: _selectedPropertyType,
              icon: const Icon(Icons.keyboard_arrow_down, color: kBlack),
              items: [
                'House',
                'Apartment',
                'Duplex',
                'Mansion',
                'Bungalow',
                'Complex',
                'Rentals',
                'Others'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: GoogleFonts.roboto(fontSize: kFontSize14),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedPropertyType = newValue!;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureSelectors() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildCounterCard(
          'Bedrooms',
          _bedrooms,
          (val) => setState(() => _bedrooms = val),
          Icons.bed,
        ),
        _buildCounterCard(
          'Bathrooms',
          _bathrooms,
          (val) => setState(() => _bathrooms = val),
          Icons.bathtub,
        ),
        _buildCounterCard(
          'Kitchens',
          _kitchens,
          (val) => setState(() => _kitchens = val),
          Icons.kitchen,
        ),
        _buildCounterCard(
          'Toilets',
          _toilets,
          (val) => setState(() => _toilets = val),
          Icons.wc,
        ),
        _buildCounterCard(
          'Living Rooms',
          _livingRooms,
          (val) => setState(() => _livingRooms = val),
          Icons.chair,
        ),
      ],
    );
  }

  Widget _buildCounterCard(
    String label,
    int value,
    ValueChanged<int> onChanged,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kGrey200),
        boxShadow: [
          BoxShadow(
            color: kBlack.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: kGrey600),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: kGrey700,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => onChanged(value > 0 ? value - 1 : 0),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: kGrey100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.remove, size: 16, color: kBlack87),
                ),
              ),
              Text(
                '$value',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kPrimaryColor,
                ),
              ),
              InkWell(
                onTap: () => onChanged(value + 1),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: kPrimaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: kWhite),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can only upload up to 5 images.'),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 80,
      );

      if (pickedFiles.isNotEmpty) {
        final int remainingSlots = 5 - _selectedImages.length;
        List<XFile> filesToProcess = pickedFiles;

        if (pickedFiles.length > remainingSlots) {
          filesToProcess = pickedFiles.take(remainingSlots).toList();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Selection restricted to maximum 5 images.'),
                backgroundColor: kPrimaryColor,
              ),
            );
          }
        }

        final List<File> validImages = [];
        bool hasInvalidFiles = false;

        for (var file in filesToProcess) {
          final extension = file.path.split('.').last.toLowerCase();
          if (['jpg', 'jpeg', 'png'].contains(extension)) {
            validImages.add(File(file.path));
          } else {
            hasInvalidFiles = true;
          }
        }

        setState(() {
          _selectedImages.addAll(validImages);
        });

        if (hasInvalidFiles && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Some files were rejected. Only JPG, JPEG, and PNG are allowed.'),
              backgroundColor: kRed,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: kRed,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildImageUploaders() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: _selectedImages.length + (_selectedImages.length < 5 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _selectedImages.length) {
          return _buildImagePlaceholder();
        }
        return _buildImageItem(index);
      },
    );
  }

  Widget _buildImageItem(int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: kRadius12,
            border: Border.all(color: kGrey400),
            image: DecorationImage(
              image: FileImage(_selectedImages[index]),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: kRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 16,
                color: kWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return GestureDetector(
      onTap: _pickImages,
      child: Container(
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: kRadius12,
          border: Border.all(color: kGrey400),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'assets/icons/upload_cloud.svg',
                height: 24,
                width: 24,
                colorFilter:
                    const ColorFilter.mode(kPrimaryColor, BlendMode.srcIn),
              ),
              const SizedBox(height: 8),
              Text(
                'Upload Image',
                style: GoogleFonts.roboto(
                  fontSize: kFontSize12,
                  color: kPrimaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmbeddedMapPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location on Map', style: _headerStyle()),
        const SizedBox(height: kSizedBoxH8),
        Container(
          height: 350,
          decoration: BoxDecoration(
            borderRadius: kRadius12,
            border: Border.all(color: kGrey400),
          ),
          child: ClipRRect(
            borderRadius: kRadius12,
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? _initialPosition,
                    zoom: 14.0,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onCameraMove: (position) {
                    setState(() {
                      _selectedLocation = position.target;
                    });
                  },
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: true,
                  gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                    Factory<EagerGestureRecognizer>(
                      () => EagerGestureRecognizer(),
                    ),
                  },
                ),
                const Center(
                  child: Padding(
                    padding: kPaddingOnlyBottom40,
                    child: Icon(
                      Icons.location_pin,
                      color: kRed,
                      size: kFontSize40,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MapIconButton(
                        icon: Icons.my_location,
                        onPressed: _recenterMap,
                      ),
                      const SizedBox(height: 8),
                      MapZoomControls(
                        onZoomIn: () {
                          _mapController?.animateCamera(CameraUpdate.zoomIn());
                        },
                        onZoomOut: () {
                          _mapController?.animateCamera(CameraUpdate.zoomOut());
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedLocation != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Text(
                'Lat: ${_selectedLocation!.latitude.toStringAsFixed(5)}, Lon: ${_selectedLocation!.longitude.toStringAsFixed(5)}',
                style: GoogleFonts.roboto(color: kGrey, fontSize: kFontSize12),
              ),
            ),
          ),
      ],
    );
  }
}
