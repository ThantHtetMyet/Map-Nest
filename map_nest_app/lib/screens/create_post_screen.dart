import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';
import '../providers/post_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/image_upload_service.dart';
import '../widgets/glass_card.dart';
import 'location_picker_screen.dart';

class CreatePostScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const CreatePostScreen({
    super.key,
    this.initialLocation,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _remarkController = TextEditingController();
  final _priceController = TextEditingController();
  final _entranceWidthController = TextEditingController();
  final _longController = TextEditingController();
  final _townshipController = TextEditingController();
  final _cityController = TextEditingController();
  final _streetController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final LocationService _locationService = LocationService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _imagePicker = ImagePicker();
  final ImageUploadService _imageUploadService = ImageUploadService();

  List<File> _selectedImages = [];
  List<TextEditingController> _phoneNumberControllers = [TextEditingController()]; // Start with one phone number
  LatLng? _selectedLocation;
  bool _isSubmitting = false;
  String _loadingStatus = 'Preparing...';
  bool _isGeocodingPostalCode = false;
  
  // Dropdown values
  String? _selectedType; // "rent" or "sold"
  String? _selectedPropertyType; // Property type options
  bool _isWholeApartment = false; // For apartment rent
  bool _hasMasterRoom = false; // For apartment rent
  bool _hasCommonRoom = false; // For apartment rent
  final _masterRoomQuantityController = TextEditingController();
  final _commonRoomQuantityController = TextEditingController();

  // Scroll controller
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Don't set location from initialLocation - wait for user to explicitly select location
    // widget.initialLocation is only used for the map picker screen
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _contactNameController.dispose();
    _addressController.dispose();
    _remarkController.dispose();
    _priceController.dispose();
    _entranceWidthController.dispose();
    _longController.dispose();
    _townshipController.dispose();
    _cityController.dispose();
    _streetController.dispose();
    _postalCodeController.dispose();
    _masterRoomQuantityController.dispose();
    _commonRoomQuantityController.dispose();
    for (var controller in _phoneNumberControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showCancelConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
        final isDark = themeProvider.isDarkMode;
        
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cancel Post?',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to cancel? All filled data will be lost.',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'No',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate back to map screen
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text(
                'Yes, Cancel',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      // If pickMultiImage fails, try single image picker
      try {
        final XFile? image = await _imagePicker.pickImage(
          source: source,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _selectedImages.add(File(image.path));
          });
        }
      } catch (e2) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error picking image: $e2')),
          );
        }
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.blue),
              ),
              title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.photo_library, color: Colors.purple),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImages(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _getLocationFromPostalCode() async {
    final postalCode = _postalCodeController.text.trim();
    if (postalCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a postal code'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isGeocodingPostalCode = true;
    });

    try {
      // Try multiple geocoding approaches for better postal code resolution
      List<dynamic>? data;
      
      // Approach 1: Use postalcode parameter (most specific for postal codes)
      try {
        final url1 = Uri.parse(
          'https://nominatim.openstreetmap.org/search?format=json&postalcode=$postalCode&limit=1',
        );
        
        final response1 = await http.get(
          url1,
          headers: {
            'User-Agent': 'MapNest App', // Required by Nominatim
          },
        );

        if (response1.statusCode == 200) {
          final List<dynamic> result1 = json.decode(response1.body);
          if (result1.isNotEmpty) {
            data = result1;
          }
        }
      } catch (e) {
        // Continue to next approach
      }

      // Approach 2: If first approach failed, try with country context (Singapore/Malaysia/Myanmar)
      if (data == null || data!.isEmpty) {
        try {
          // Try with Singapore context (common postal code format)
          final url2 = Uri.parse(
            'https://nominatim.openstreetmap.org/search?format=json&postalcode=$postalCode&countrycodes=sg,my,mm&limit=1',
          );
          
          final response2 = await http.get(
            url2,
            headers: {
              'User-Agent': 'MapNest App',
            },
          );

          if (response2.statusCode == 200) {
            final List<dynamic> result2 = json.decode(response2.body);
            if (result2.isNotEmpty) {
              data = result2;
            }
          }
        } catch (e) {
          // Continue to next approach
        }
      }

      // Approach 3: Fallback to general search query
      if (data == null || data!.isEmpty) {
        try {
          final url3 = Uri.parse(
            'https://nominatim.openstreetmap.org/search?format=json&q=$postalCode&limit=5',
          );
          
          final response3 = await http.get(
            url3,
            headers: {
              'User-Agent': 'MapNest App',
            },
          );

          if (response3.statusCode == 200) {
            final List<dynamic> result3 = json.decode(response3.body);
            // Filter results to find ones that mention postal code
            if (result3.isNotEmpty) {
              // Try to find a result that has postal code in address
              final postalCodeMatch = result3.firstWhere(
                (item) {
                  final displayName = (item['display_name'] ?? '').toString().toLowerCase();
                  final postalCodeLower = postalCode.toLowerCase();
                  return displayName.contains(postalCodeLower);
                },
                orElse: () => result3[0], // Use first result if no match
              );
              data = [postalCodeMatch];
            }
          }
        } catch (e) {
          // All approaches failed
        }
      }

      if (data != null && data.isNotEmpty) {
        final lat = double.tryParse(data[0]['lat'] ?? '');
        final lon = double.tryParse(data[0]['lon'] ?? '');
        
        if (lat != null && lon != null) {
          setState(() {
            _selectedLocation = LatLng(lat, lon);
            _isGeocodingPostalCode = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location found: ${data[0]['display_name'] ?? 'Postal code location'}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else {
          throw Exception('Invalid coordinates received');
        }
      } else {
        throw Exception('No location found for postal code: $postalCode. Please try a different postal code or use "Pick Map" to select location manually.');
      }
    } catch (e) {
      setState(() {
        _isGeocodingPostalCode = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find location for postal code: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Contact number is required';
    }
    final phoneRegex = RegExp(r'^[\d\s\+\-\(\)]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    if (value.replaceAll(RegExp(r'[\s\+\-\(\)]'), '').length < 7) {
      return 'Phone number is too short';
    }
    return null;
  }

  Future<void> _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a location'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _loadingStatus = 'Uploading images...';
    });

    try {
      final postId = DateTime.now().millisecondsSinceEpoch.toString();

      // Upload all images using free image hosting service
      setState(() {
        _loadingStatus = 'Uploading ${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''}...';
      });
      final imageUrls = await ImageUploadService.uploadMultipleImages(
        _selectedImages,
      );

      if (imageUrls.isEmpty) {
        throw Exception('Failed to upload images. Please check your ImgBB API key.');
      }

      // Validate dropdowns
      if (_selectedType == null || _selectedType!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Rent or Sold'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      if (_selectedPropertyType == null || _selectedPropertyType!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select Property Type'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Validate apartment rent fields
      if (_selectedType == 'rent' &&
          (_selectedPropertyType == 'Apartment(Condo)' ||
              _selectedPropertyType == 'Apartment(HDB)')) {
        if (!_isWholeApartment && !_hasMasterRoom && !_hasCommonRoom) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select at least one option: Whole Apartment, Master Room, or Common Room'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }
      }

      // Collect all phone numbers (filter out empty ones)
      final phoneNumbers = _phoneNumberControllers
          .map((controller) => controller.text.trim())
          .where((number) => number.isNotEmpty)
          .toList();

      if (phoneNumbers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one contact number'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      // Create post model
      final post = PostModel(
        id: postId,
        contactName: _contactNameController.text.trim(),
        contactNumbers: phoneNumbers,
        imageUrls: imageUrls,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        createdAt: DateTime.now(),
        type: _selectedType!,
        propertyType: _selectedPropertyType!,
        address: _addressController.text.trim(),
        remark: _remarkController.text.trim(),
        price: _priceController.text.trim(),
        entranceWidth: _entranceWidthController.text.trim(),
        long: _longController.text.trim(),
        township: _townshipController.text.trim(),
        city: _cityController.text.trim(),
        street: _streetController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
      );

      // Save post
      setState(() {
        _loadingStatus = 'Saving post...';
      });
      final postProvider = Provider.of<PostProvider>(context, listen: false);
      final success = await postProvider.createPost(post);
      
      setState(() {
        _loadingStatus = 'Almost done...';
      });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        if (success) {
          Navigator.pop(context, true);
        } else {
          // Show detailed error
          final errorMsg = postProvider.lastError ?? 'Unknown error occurred';
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.error, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Failed to Create Post'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'The post could not be saved to the database.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('Error: $errorMsg'),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Common fixes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Check internet connection'),
                    const Text('2. Verify Firestore is enabled'),
                    const Text('3. Check Firestore rules allow writes'),
                    const Text('4. Ensure Firebase is initialized'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        
        // Show detailed error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Upload Error'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.toString().replaceAll('Exception: ', ''),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Quick Fix:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text('1. Check your ImgBB API key'),
                  const Text('2. Verify internet connection'),
                  const Text('3. Try again later'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _addPhoneNumberField() {
    setState(() {
      _phoneNumberControllers.add(TextEditingController());
    });
  }

  void _removePhoneNumberField(int index) {
    if (_phoneNumberControllers.length > 1) {
      setState(() {
        _phoneNumberControllers[index].dispose();
        _phoneNumberControllers.removeAt(index);
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            // Fixed Title at Top
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Create New Post',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Scrollable Content
            Expanded(
              child: Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Contact Information Section
                          Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // Contact Name Card
                          GlassCard(
                            child: TextFormField(
                              controller: _contactNameController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Contact Name',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                hintText: 'Enter your full name',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.blue.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[50],
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Contact name is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Contact Numbers Section
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.green.shade400,
                                            Colors.green.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.phone, color: Colors.white, size: 20),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Contact Numbers',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: _addPhoneNumberField,
                                      icon: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade400,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      tooltip: 'Add another phone number',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ..._phoneNumberControllers.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final controller = entry.value;
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: index < _phoneNumberControllers.length - 1 ? 12 : 0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextFormField(
                                            controller: controller,
                                            style: TextStyle(
                                              color: isDark ? Colors.white : Colors.black87,
                                              fontSize: 16,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Phone Number ${index + 1}',
                                              labelStyle: TextStyle(
                                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                              hintText: 'Enter contact number',
                                              hintStyle: TextStyle(
                                                color: isDark ? Colors.grey[500] : Colors.grey[400],
                                              ),
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(12),
                                                borderSide: BorderSide.none,
                                              ),
                                              filled: true,
                                              fillColor: isDark
                                                  ? Colors.white.withOpacity(0.1)
                                                  : Colors.grey[50],
                                            ),
                                            keyboardType: TextInputType.phone,
                                            validator: index == 0 ? _validatePhoneNumber : null,
                                          ),
                                        ),
                                        if (_phoneNumberControllers.length > 1)
                                          Padding(
                                            padding: const EdgeInsets.only(left: 8),
                                            child: IconButton(
                                              onPressed: () => _removePhoneNumberField(index),
                                              icon: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade400,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                              tooltip: 'Remove phone number',
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Property Details Section
                          Text(
                            'Property Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Rent/Sold Dropdown
                          GlassCard(
                            child: DropdownButtonFormField<String>(
                              value: _selectedType,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Type *',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple.shade400,
                                        Colors.purple.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.category, color: Colors.white),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[50],
                              ),
                              dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                              items: const [
                                DropdownMenuItem(value: 'rent', child: Text('Rent')),
                                DropdownMenuItem(value: 'sold', child: Text('Sold')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedType = value;
                                  // Reset apartment fields if type is not "rent"
                                  if (value != 'rent') {
                                    _isWholeApartment = false;
                                    _hasMasterRoom = false;
                                    _hasCommonRoom = false;
                                    _masterRoomQuantityController.clear();
                                    _commonRoomQuantityController.clear();
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select Rent or Sold';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Property Type Dropdown
                          GlassCard(
                            child: DropdownButtonFormField<String>(
                              value: _selectedPropertyType,
                              isExpanded: true,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Property Type *',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.teal.shade400,
                                        Colors.teal.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.home_work, color: Colors.white),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[50],
                              ),
                              dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Land(Vacant Land/Land Only)',
                                  child: Text(
                                    'Land (Vacant Land/Land Only)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Apartment(Condo)',
                                  child: Text(
                                    'Apartment (Condo)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Apartment(HDB)',
                                  child: Text(
                                    'Apartment (HDB)',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Land with house',
                                  child: Text(
                                    'Land with house',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                              selectedItemBuilder: (BuildContext context) {
                                return [
                                  'Land(Vacant Land/Land Only)',
                                  'Apartment(Condo)',
                                  'Apartment(HDB)',
                                  'Land with house',
                                ].map<Widget>((String value) {
                                  String displayText;
                                  switch (value) {
                                    case 'Land(Vacant Land/Land Only)':
                                      displayText = 'Land (Vacant/Land Only)';
                                      break;
                                    case 'Apartment(Condo)':
                                      displayText = 'Apartment (Condo)';
                                      break;
                                    case 'Apartment(HDB)':
                                      displayText = 'Apartment (HDB)';
                                      break;
                                    case 'Land with house':
                                      displayText = 'Land with house';
                                      break;
                                    default:
                                      displayText = value;
                                  }
                                  return Text(
                                    displayText,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 16),
                                  );
                                }).toList();
                              },
                              onChanged: (value) {
                                setState(() {
                                  _selectedPropertyType = value;
                                  // Reset apartment fields if not apartment
                                  if (value == null ||
                                      (value != 'Apartment(Condo)' && value != 'Apartment(HDB)')) {
                                    _isWholeApartment = false;
                                    _hasMasterRoom = false;
                                    _hasCommonRoom = false;
                                    _masterRoomQuantityController.clear();
                                    _commonRoomQuantityController.clear();
                                  }
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select Property Type';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Apartment-specific fields (only for Apartment + Rent)
                          if (_selectedPropertyType != null &&
                              (_selectedPropertyType == 'Apartment(Condo)' ||
                                  _selectedPropertyType == 'Apartment(HDB)') &&
                              _selectedType == 'rent') ...[
                            // Whole Apartment Option
                            GlassCard(
                              child: CheckboxListTile(
                                title: Text(
                                  'Whole Apartment',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                value: _isWholeApartment,
                                onChanged: (value) {
                                  setState(() {
                                    _isWholeApartment = value ?? false;
                                    if (_isWholeApartment) {
                                      _hasMasterRoom = false;
                                      _hasCommonRoom = false;
                                      _masterRoomQuantityController.clear();
                                      _commonRoomQuantityController.clear();
                                    }
                                  });
                                },
                                activeColor: Colors.pink.shade600,
                                controlAffinity: ListTileControlAffinity.leading,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Master Room Option
                            if (!_isWholeApartment) ...[
                              GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CheckboxListTile(
                                      title: Text(
                                        'Master Room',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      value: _hasMasterRoom,
                                      onChanged: (value) {
                                        setState(() {
                                          _hasMasterRoom = value ?? false;
                                          if (!_hasMasterRoom) {
                                            _masterRoomQuantityController.clear();
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue.shade600,
                                      controlAffinity: ListTileControlAffinity.leading,
                                    ),
                                    if (_hasMasterRoom) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: TextFormField(
                                          controller: _masterRoomQuantityController,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Colors.black87,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Number of Master Rooms',
                                            labelStyle: TextStyle(
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                            hintText: 'Enter quantity',
                                            hintStyle: TextStyle(
                                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: isDark
                                                ? Colors.white.withOpacity(0.1)
                                                : Colors.grey[50],
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (_hasMasterRoom && (value == null || value.isEmpty)) {
                                              return 'Please enter quantity';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Common Room Option
                              GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CheckboxListTile(
                                      title: Text(
                                        'Common Room',
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontSize: 16,
                                        ),
                                      ),
                                      value: _hasCommonRoom,
                                      onChanged: (value) {
                                        setState(() {
                                          _hasCommonRoom = value ?? false;
                                          if (!_hasCommonRoom) {
                                            _commonRoomQuantityController.clear();
                                          }
                                        });
                                      },
                                      activeColor: Colors.green.shade600,
                                      controlAffinity: ListTileControlAffinity.leading,
                                    ),
                                    if (_hasCommonRoom) ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        child: TextFormField(
                                          controller: _commonRoomQuantityController,
                                          style: TextStyle(
                                            color: isDark ? Colors.white : Colors.black87,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Number of Common Rooms',
                                            labelStyle: TextStyle(
                                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                                            ),
                                            hintText: 'Enter quantity',
                                            hintStyle: TextStyle(
                                              color: isDark ? Colors.grey[500] : Colors.grey[400],
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: isDark
                                                ? Colors.white.withOpacity(0.1)
                                                : Colors.grey[50],
                                          ),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (_hasCommonRoom && (value == null || value.isEmpty)) {
                                              return 'Please enter quantity';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ],

                          // Entrance Width Field (only show if NOT apartment)
                          if (_selectedPropertyType == null ||
                              (_selectedPropertyType != 'Apartment(Condo)' &&
                                  _selectedPropertyType != 'Apartment(HDB)')) ...[
                            GlassCard(
                              child: TextFormField(
                                controller: _entranceWidthController,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Entrance Width',
                                  labelStyle: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  hintText: 'Enter entrance width (optional)',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.cyan.shade400,
                                          Colors.cyan.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.swap_horiz, color: Colors.white),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[50],
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Long (Length) Field (only show if NOT apartment)
                            GlassCard(
                              child: TextFormField(
                                controller: _longController,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Long',
                                  labelStyle: TextStyle(
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                  hintText: 'Enter length (optional)',
                                  hintStyle: TextStyle(
                                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                                  ),
                                  prefixIcon: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.deepPurple.shade400,
                                          Colors.deepPurple.shade600,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.swap_vert, color: Colors.white),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.grey[50],
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Address Field
                          GlassCard(
                            child: TextFormField(
                              controller: _addressController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Address',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                hintText: 'Enter property address (optional)',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.indigo.shade400,
                                        Colors.indigo.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.location_city, color: Colors.white),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[50],
                              ),
                              maxLines: 2,
                              textInputAction: TextInputAction.newline,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Postal Code Field
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _postalCodeController,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Postal Code',
                                    labelStyle: TextStyle(
                                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                                    ),
                                    hintText: 'Enter postal code (optional)',
                                    hintStyle: TextStyle(
                                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.purple.shade400,
                                            Colors.purple.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.markunread_mailbox, color: Colors.white),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.grey[50],
                                  ),
                                  keyboardType: TextInputType.text,
                                  onChanged: (value) {
                                    setState(() {}); // Refresh to show/hide search button
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Township Field
                          GlassCard(
                            child: TextFormField(
                              controller: _townshipController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Township',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                hintText: 'Enter township (optional)',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.brown.shade400,
                                        Colors.brown.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.location_on, color: Colors.white),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[50],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // City Field
                          GlassCard(
                            child: TextFormField(
                              controller: _cityController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'City',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                hintText: 'Enter city (optional)',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade400,
                                        Colors.red.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.apartment, color: Colors.white),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[50],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Street Field
                          GlassCard(
                            child: TextFormField(
                              controller: _streetController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Street',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                hintText: 'Enter street (optional)',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blueGrey.shade400,
                                        Colors.blueGrey.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.streetview, color: Colors.white),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[50],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Remark Field
                          GlassCard(
                            child: TextFormField(
                              controller: _remarkController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Remark',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                hintText: 'Enter any additional remarks (optional)',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.amber.shade400,
                                        Colors.amber.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.note, color: Colors.white),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[50],
                              ),
                              maxLines: 3,
                              textInputAction: TextInputAction.newline,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Price Section
                          Text(
                            'Price',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          GlassCard(
                            child: TextFormField(
                              controller: _priceController,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Price',
                                labelStyle: TextStyle(
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                                hintText: 'Enter price (e.g., 500000 or 500K)',
                                hintStyle: TextStyle(
                                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                                ),
                                prefixIcon: Container(
                                  margin: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.orange.shade400,
                                        Colors.orange.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.attach_money, color: Colors.white),
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.grey[50],
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Images Section
                          Text(
                            'Images',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.pink.shade400,
                                              Colors.pink.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.pink.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.image, color: Colors.white),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Upload Images',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _selectedImages.isEmpty
                                    ? GestureDetector(
                                        onTap: _showImageSourceDialog,
                                        child: Container(
                                          height: 150,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: isDark
                                                  ? [
                                                      Colors.grey[800]!,
                                                      Colors.grey[700]!,
                                                    ]
                                                  : [
                                                      Colors.grey[200]!,
                                                      Colors.grey[100]!,
                                                    ],
                                            ),
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.grey[600]!
                                                  : Colors.grey[300]!,
                                              style: BorderStyle.solid,
                                              width: 2,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 48,
                                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Tap to add images',
                                                style: TextStyle(
                                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 8,
                                          mainAxisSpacing: 8,
                                        ),
                                        itemCount: _selectedImages.length + (_selectedImages.length < 9 ? 1 : 0),
                                        itemBuilder: (context, index) {
                                          if (index < _selectedImages.length) {
                                            return Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.file(
                                                    _selectedImages[index],
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
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
                                                        color: Colors.red,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: const Icon(
                                                        Icons.close,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          } else {
                                            return GestureDetector(
                                              onTap: _showImageSourceDialog,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.grey[300]!),
                                                ),
                                                child: const Icon(Icons.add, size: 32, color: Colors.grey),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Location Section
                          Text(
                            'Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.orange.shade400,
                                            Colors.orange.shade600,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.orange.withOpacity(0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.location_on, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Location',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _selectedLocation != null
                                    ? Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade50,
                                              Colors.blue.shade100,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.blue.shade200,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: Colors.green.shade600,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Location Selected',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.green.shade700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}\n'
                                                    'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    : Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_off,
                                              color: Colors.grey[600],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Please select a location using the buttons below',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                const SizedBox(height: 16),
                                // First row: Current and Pick Map buttons
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.blue.shade400,
                                              Colors.blue.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: _getCurrentLocation,
                                            borderRadius: BorderRadius.circular(12),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Icon(Icons.my_location, color: Colors.white, size: 18),
                                                  SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      'Current',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.purple.shade400,
                                              Colors.purple.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.purple.withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () async {
                                              final pickedLocation = await Navigator.push<LatLng>(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => LocationPickerScreen(
                                                    initialLocation: _selectedLocation ?? widget.initialLocation,
                                                  ),
                                                ),
                                              );
                                              
                                              if (pickedLocation != null) {
                                                setState(() {
                                                  _selectedLocation = pickedLocation;
                                                });
                                              }
                                            },
                                            borderRadius: BorderRadius.circular(12),
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 14),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: const [
                                                  Icon(Icons.map, color: Colors.white, size: 18),
                                                  SizedBox(width: 4),
                                                  Flexible(
                                                    child: Text(
                                                      'Pick Map',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                // Second row: Get from Postal Code button (full width)
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _isGeocodingPostalCode
                                          ? [
                                              Colors.grey.shade400,
                                              Colors.grey.shade600,
                                            ]
                                          : [
                                              Colors.orange.shade400,
                                              Colors.orange.shade600,
                                            ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (_isGeocodingPostalCode ? Colors.grey : Colors.orange).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isGeocodingPostalCode ? null : _getLocationFromPostalCode,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _isGeocodingPostalCode
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                    ),
                                                  )
                                                : const Icon(Icons.location_city, color: Colors.white, size: 18),
                                            const SizedBox(width: 4),
                                            Flexible(
                                              child: Text(
                                                _isGeocodingPostalCode ? 'Loading...' : 'Get from Postal Code',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Cancel and Submit Buttons Row
                          Row(
                            children: [
                              // Cancel Button
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.grey.shade400,
                                        Colors.grey.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _showCancelConfirmationDialog,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.cancel_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Submit Button
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green.shade400,
                                        Colors.green.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _isSubmitting ? null : _submitPost,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_isSubmitting) ...[
                                              SizedBox(
                                                height: 18,
                                                width: 18,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Flexible(
                                                child: Text(
                                                  'Submitting...',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ] else ...[
                                              const Icon(
                                                Icons.check_circle_outline,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              const Flexible(
                                                child: Text(
                                                  'Submit',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  // Beautiful Loading Overlay
                  if (_isSubmitting)
                    Material(
                      color: Colors.black.withOpacity(0.75),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: Center(
                          child: GlassCard(
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Animated Pulsing Icon
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 1500),
                                    curve: Curves.easeInOut,
                                    builder: (context, value, child) {
                                      final pulseValue = (value * 2 % 1.0);
                                      final scale = 0.85 + (0.15 * (0.5 + 0.5 * (pulseValue < 0.5 ? pulseValue * 2 : 2 - pulseValue * 2)));
                                      return Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          // Outer glow
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green.withOpacity(0.3 * (1 - pulseValue)),
                                                  blurRadius: 30,
                                                  spreadRadius: 10,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Main icon container
                                          Transform.scale(
                                            scale: scale,
                                            child: Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    Colors.green.shade400,
                                                    Colors.green.shade600,
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.withOpacity(0.5),
                                                    blurRadius: 20,
                                                    spreadRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.cloud_upload,
                                                color: Colors.white,
                                                size: 40,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  // Loading Text with fade animation
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 800),
                                    builder: (context, value, child) {
                                      return Opacity(
                                        opacity: value,
                                        child: Text(
                                          _loadingStatus,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                            letterSpacing: 0.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 25),
                                  // Animated Progress Bar
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 2000),
                                    curve: Curves.easeInOut,
                                    onEnd: () {
                                      if (_isSubmitting && mounted) {
                                        setState(() {});
                                      }
                                    },
                                    builder: (context, value, child) {
                                      return Container(
                                        height: 8,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: isDark ? Colors.grey[800] : Colors.grey[300],
                                        ),
                                        child: Stack(
                                          children: [
                                            FractionallySizedBox(
                                              widthFactor: value,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      Colors.green.shade400,
                                                      Colors.green.shade600,
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius.circular(10),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.green.withOpacity(0.6),
                                                      blurRadius: 10,
                                                      spreadRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 30),
                                  // Animated Loading Dots
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3, (index) {
                                      return TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration: const Duration(milliseconds: 1200),
                                        curve: Curves.easeInOut,
                                        builder: (context, value, child) {
                                          final delay = index * 0.25;
                                          final animationValue = ((value + delay) % 1.0);
                                          final opacity = 0.3 + (0.7 * (animationValue < 0.5 ? animationValue * 2 : 2 - animationValue * 2));
                                          final scale = 0.8 + (0.2 * (animationValue < 0.5 ? animationValue * 2 : 2 - animationValue * 2));
                                          return Transform.scale(
                                            scale: scale,
                                            child: Container(
                                              margin: const EdgeInsets.symmetric(horizontal: 6),
                                              width: 14,
                                              height: 14,
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade400.withOpacity(opacity),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.green.withOpacity(opacity * 0.5),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
