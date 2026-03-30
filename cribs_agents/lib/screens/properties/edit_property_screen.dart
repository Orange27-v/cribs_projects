import 'dart:io';
import 'package:cribs_agents/widgets/custom_pill_switch.dart';
import 'package:cribs_agents/constants.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cribs_agents/models/property.dart';
import 'package:cribs_agents/services/property_service.dart';
import 'package:cribs_agents/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cribs_agents/screens/agents/user_widgets/map_controls.dart';
import 'package:geolocator/geolocator.dart';

class EditPropertyScreen extends StatefulWidget {
  final Property property;
  const EditPropertyScreen({super.key, required this.property});

  @override
  State<EditPropertyScreen> createState() => _EditPropertyScreenState();
}

class _EditPropertyScreenState extends State<EditPropertyScreen> {
  late String _selectedPropertyType;
  late int _bedrooms;
  late int _bathrooms;
  late int _kitchens;
  late int _toilets;
  late int _livingRooms;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  GoogleMapController? _mapController;
  static const LatLng _initialPosition =
      LatLng(6.5244, 3.3792); // Lagos fallback

  int _descriptionWordCount = 0;

  late List<bool> _listingTypeSelection;
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

  final PropertyService _propertyService = PropertyService();
  bool _isLoading = false;

  final List<File> _newImages = [];
  List<String> _existingImages = [];
  final List<String> _imagesToDelete = [];
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // ... previous initialization ...
    _selectedPropertyType = widget.property.type;
    _bedrooms = widget.property.beds;
    _bathrooms = widget.property.baths;
    _kitchens = 0;
    _toilets = 0;
    _livingRooms = 0;

    _titleController.text = widget.property.title;
    _addressController.text =
        widget.property.address ?? widget.property.location;
    _descriptionController.text = widget.property.description ?? '';
    _priceController.text = widget.property.price.toString();
    _propertySizeController.text = widget.property.sqft ?? '';

    // Initialize existing images
    if (widget.property.images != null) {
      _existingImages = List<String>.from(widget.property.images!);
    }

    if (widget.property.latitude != null && widget.property.longitude != null) {
      _selectedLocation = LatLng(
        widget.property.latitude!,
        widget.property.longitude!,
      );
    }

    _listingTypeSelection = [
      widget.property.listingType == 'For Sale',
      widget.property.listingType == 'For Rent',
    ];

    _getCurrentLocation();

    if (widget.property.amenities != null) {
      _selectedAmenities.addAll(widget.property.amenities!);
    }

    _descriptionController.addListener(_updateWordCount);
    // Initialize word count
    _updateWordCount();
  }

  void _updateWordCount() {
    final text = _descriptionController.text.trim();
    setState(() {
      _descriptionWordCount =
          text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
    });
  }

  Future<void> _pickImages() async {
    final int currentCount = _existingImages.length + _newImages.length;
    if (currentCount >= 5) {
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
        final int remainingSlots = 5 - currentCount;
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
          _newImages.addAll(validImages);
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

  void _removeExistingImage(int index) {
    setState(() {
      _imagesToDelete.add(_existingImages[index]);
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Widget _buildImageUploaders() {
    final int totalCount = _existingImages.length + _newImages.length;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: totalCount + (totalCount < 5 ? 1 : 0),
      itemBuilder: (context, index) {
        // Build Add Button at the end
        if (index == totalCount) {
          return _buildImagePlaceholder();
        }

        // Build Existing Images
        if (index < _existingImages.length) {
          String imgUrl = _existingImages[index];
          if (!imgUrl.startsWith('http')) {
            imgUrl = '$kMainBaseUrl/storage/$imgUrl';
          }

          return Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: kRadius12,
                  border: Border.all(color: kGrey400),
                  image: DecorationImage(
                    image: NetworkImage(imgUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => _removeExistingImage(index),
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

        // Build New Images
        final newImageIndex = index - _existingImages.length;
        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: kRadius12,
                border: Border.all(color: kGrey400),
                image: DecorationImage(
                  image: FileImage(_newImages[newImageIndex]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _removeNewImage(newImageIndex),
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
      },
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
                'Add Image',
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

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = _initialPosition;
            _selectedLocation ??= _initialPosition;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = _initialPosition;
          _selectedLocation ??= _initialPosition;
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
          _selectedLocation ??= _currentLocation;
        });

        // Move camera to location if no property location was set
        if (widget.property.latitude == null ||
            widget.property.longitude == null) {
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: _currentLocation!,
                zoom: 14.0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _currentLocation = _initialPosition;
          _selectedLocation ??= _initialPosition;
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

  Future<void> _recenterMap() async {
    if (_currentLocation == null) {
      await _getCurrentLocation();
    }
    final target = _currentLocation ?? _selectedLocation ?? _initialPosition;
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 14.0),
      ),
    );
  }

  Future<void> _updatePropertyDetails() async {
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

      final result = await _propertyService.updateProperty(
        propertyId: widget.property.propertyId,
        title: _titleController.text,
        type: _selectedPropertyType,
        location: _addressController.text.split(',').first.trim(),
        listingType: listingType,
        price: double.parse(_priceController.text),
        beds: _bedrooms,
        baths: _bathrooms,
        sqft: _propertySizeController.text.isNotEmpty
            ? _propertySizeController.text
            : null,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        address: _addressController.text,
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
        amenities: _selectedAmenities.toList(),
        newImages: _newImages,
        imagesToDelete: _imagesToDelete,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text(result['message'] ?? 'Property updated successfully!'),
              backgroundColor: kPrimaryColor,
            ),
          );
          // Navigate back to property details
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to update property'),
              backgroundColor: kRed,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error updating property: $e');
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
        title: Text('EDIT PROPERTY'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: kPaddingAll12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPropertyDetailsSection(),
              const SizedBox(height: 24),
              _buildListingDetailsSection(),
              const SizedBox(height: 24),
              _buildFeaturesSection(),
              const SizedBox(height: 24),
              _buildAmenitiesSection(),
              const SizedBox(height: 24),
              _buildImageUploadSection(),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(
                      child: CustomLoadingIndicator(),
                    )
                  : PrimaryButton(
                      text: 'Save Changes',
                      onPressed: _updatePropertyDetails,
                    ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPropertyDetailsSection() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPropertyTypeSelector(),
          const SizedBox(height: 24),
          LabeledTextField(
            label: 'Property Title',
            hintText: 'Enter Property name',
            controller: _titleController,
          ),
          const SizedBox(height: 24),
          LabeledTextField(
            label: 'Address',
            hintText: 'Enter Property address',
            controller: _addressController,
          ),
          const SizedBox(height: 24),
          _buildEmbeddedMapPicker(),
          const SizedBox(height: 24),
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
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Listing Details', style: _headerStyle()),
          const SizedBox(height: 16),
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
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Features', style: _headerStyle()),
          const SizedBox(height: 16),
          _buildFeatureSelectors(),
          const SizedBox(height: 24),
          LabeledTextField(
            label: 'Property Size (Sq. ft)',
            hintText: 'Enter total area',
            controller: _propertySizeController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24),
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
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Amenities', style: _headerStyle()),
          const SizedBox(height: 16),
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
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload images of property', style: _headerStyle()),
          const SizedBox(height: 16),
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
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
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

  Widget _buildEmbeddedMapPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Location on Map', style: _headerStyle()),
        const SizedBox(height: 8),
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
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: Icon(Icons.location_pin, color: kRed, size: 40),
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
