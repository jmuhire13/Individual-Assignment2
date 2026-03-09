// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../models/listing_model.dart';
import '../providers/listing_provider.dart';

class AddEditListingScreen extends StatefulWidget {
  // If listing is null — we are ADDING a new one
  // If listing is not null — we are EDITING an existing one
  final ListingModel? listing;
  const AddEditListingScreen({super.key, this.listing});

  @override
  State<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends State<AddEditListingScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();

  String _selectedCategory = 'Hospital';
  bool _isLoading = false;
  bool _isLoadingLocation = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static const List<String> _categories = [
    'Hospital',
    'Police Station',
    'Library',
    'Restaurant',
    'Café',
    'Park',
    'Tourist Attraction',
  ];

  static const Map<String, IconData> _categoryIcons = {
    'Hospital': Icons.local_hospital,
    'Police Station': Icons.local_police,
    'Library': Icons.library_books,
    'Restaurant': Icons.restaurant,
    'Café': Icons.local_cafe,
    'Park': Icons.park,
    'Tourist Attraction': Icons.attractions,
  };

  static const Map<String, Color> _categoryColors = {
    'Hospital': Colors.red,
    'Police Station': Colors.blue,
    'Library': Colors.brown,
    'Restaurant': Colors.orange,
    'Café': Colors.amber,
    'Park': Colors.green,
    'Tourist Attraction': Colors.purple,
  };

  // True if editing, false if adding
  bool get _isEditing => widget.listing != null;

  @override
  void initState() {
    super.initState();

    _setupAnimations();

    // If editing, pre-fill all fields with existing data
    if (_isEditing) {
      _nameCtrl.text = widget.listing!.name;
      _addressCtrl.text = widget.listing!.address;
      _contactCtrl.text = widget.listing!.contactNumber;
      _descCtrl.text = widget.listing!.description;
      _latCtrl.text = widget.listing!.latitude.toString();
      _lngCtrl.text = widget.listing!.longitude.toString();
      _selectedCategory = widget.listing!.category;
    }
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latCtrl.text = position.latitude.toStringAsFixed(6);
        _lngCtrl.text = position.longitude.toStringAsFixed(6);
      });

      _showSnackBar('Current location loaded successfully!', Colors.green);
    } catch (e) {
      _showSnackBar('Failed to get location: $e', Colors.red);
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateCoordinate(String? value, String coordinateType) {
    if (value == null || value.trim().isEmpty) {
      return '$coordinateType is required';
    }

    final double? coord = double.tryParse(value.trim());
    if (coord == null) {
      return 'Invalid $coordinateType format';
    }

    if (coordinateType == 'Latitude' && (coord < -90 || coord > 90)) {
      return 'Latitude must be between -90 and 90';
    }

    if (coordinateType == 'Longitude' && (coord < -180 || coord > 180)) {
      return 'Longitude must be between -180 and 180';
    }

    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone number is optional
    }

    // Basic phone number validation
    final phoneRegex = RegExp(r'^[\+]?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fix the errors above', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final provider = context.read<ListingProvider>();
      final uid = FirebaseAuth.instance.currentUser!.uid;

      if (_isEditing) {
        // UPDATE — only send changed fields
        await provider.updateListing(widget.listing!.id, {
          'name': _nameCtrl.text.trim(),
          'category': _selectedCategory,
          'address': _addressCtrl.text.trim(),
          'contactNumber': _contactCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'latitude': double.parse(_latCtrl.text.trim()),
          'longitude': double.parse(_lngCtrl.text.trim()),
        });

        _showSnackBar('Listing updated successfully!', Colors.green);
      } else {
        // CREATE — build a full new ListingModel
        final newListing = ListingModel(
          id: '',
          name: _nameCtrl.text.trim(),
          category: _selectedCategory,
          address: _addressCtrl.text.trim(),
          contactNumber: _contactCtrl.text.trim(),
          description: _descCtrl.text.trim(),
          latitude: double.parse(_latCtrl.text.trim()),
          longitude: double.parse(_lngCtrl.text.trim()),
          createdBy: uid,
          timestamp: DateTime.now(),
        );
        await provider.addListing(newListing);

        _showSnackBar('Listing created successfully!', Colors.green);
      }

      // Go back after saving
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnackBar('Failed to save listing: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _categoryColors[_selectedCategory] ?? Colors.grey;
    final categoryIcon = _categoryIcons[_selectedCategory] ?? Icons.place;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Listing' : 'Add Listing',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: _isLoading ? null : _save,
              child: Text(
                'SAVE',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _isLoading ? Colors.grey : Colors.blue,
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(                          // ← fixed: added `child:` parameter
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header Section ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [categoryColor.withOpacity(0.1), Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: categoryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: categoryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              categoryIcon,
                              color: categoryColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isEditing ? 'Update Listing' : 'Create New Listing',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  _selectedCategory,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: categoryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Basic Information ──────────────────────
                    Text(
                      'BASIC INFORMATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // ── Name ─────────────────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _nameCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Place / Service Name *',
                                  labelStyle: TextStyle(color: Colors.grey.shade400),
                                  hintText: 'Enter the name of the place or service',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  prefixIcon: Icon(Icons.business, color: categoryColor),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(color: categoryColor, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) => _validateRequired(value, 'Name'),
                                textCapitalization: TextCapitalization.words,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Category Dropdown ─────────────────
                            DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: InputDecoration(
                                labelText: 'Category *',
                                prefixIcon: Icon(categoryIcon, color: categoryColor),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: categoryColor, width: 2),
                                ),
                              ),
                              items: _categories.map((cat) {
                                final catColor = _categoryColors[cat] ?? Colors.grey;
                                final catIcon = _categoryIcons[cat] ?? Icons.place;
                                return DropdownMenuItem(
                                  value: cat,
                                  child: Row(
                                    children: [
                                      Icon(catIcon, color: catColor, size: 20),
                                      const SizedBox(width: 12),
                                      Text(cat),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedCategory = val!),
                            ),

                            const SizedBox(height: 20),

                            // ── Address ───────────────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _addressCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Address *',
                                  labelStyle: TextStyle(color: Colors.grey.shade400),
                                  hintText: 'Enter the full address',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  prefixIcon: Icon(Icons.location_on, color: categoryColor),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(color: categoryColor, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) => _validateRequired(value, 'Address'),
                                maxLines: 2,
                                textCapitalization: TextCapitalization.words,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // ── Contact ───────────────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade800,
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextFormField(
                                controller: _contactCtrl,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'Contact Number',
                                  labelStyle: TextStyle(color: Colors.grey.shade400),
                                  hintText: '+250 XXX XXX XXX',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  prefixIcon: Icon(Icons.phone, color: categoryColor),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(color: categoryColor, width: 2),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                ),
                                validator: _validatePhoneNumber,
                                keyboardType: TextInputType.phone,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Description ──────────────────────
                    Text(
                      'DESCRIPTION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _descCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: TextStyle(color: Colors.grey.shade400),
                              hintText:
                                  'Provide a detailed description of the place or service...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(bottom: 60),
                                child: Icon(Icons.description, color: categoryColor),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide(color: categoryColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                              alignLabelWithHint: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Location ──────────────────────
                    Text(
                      'LOCATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                        letterSpacing: 1.2,
                      ),
                    ),

                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.my_location, color: categoryColor),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'GPS Coordinates',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: _isLoadingLocation
                                      ? null
                                      : _getCurrentLocation,
                                  icon: _isLoadingLocation
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.my_location, size: 18),
                                  label: Text(
                                    _isLoadingLocation ? 'Loading...' : 'Current',
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: categoryColor,
                                    side: BorderSide(color: categoryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.amber.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.lightbulb_outline,
                                    color: Colors.amber,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Tip: Right-click any location on Google Maps and copy coordinates',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            Row(
                              children: [
                                // ── Latitude ──────────────────────────
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextFormField(
                                      controller: _latCtrl,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Latitude *',
                                        labelStyle:
                                            TextStyle(color: Colors.grey.shade400),
                                        hintText: '-1.9441',
                                        hintStyle:
                                            TextStyle(color: Colors.grey.shade500),
                                        prefixIcon: Icon(Icons.south, color: categoryColor),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(25),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(25),
                                          borderSide:
                                              BorderSide(color: categoryColor, width: 2),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(25),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                      ),
                                      validator: (value) =>
                                          _validateCoordinate(value, 'Latitude'),
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // ── Longitude ─────────────────────────
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade800,
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextFormField(
                                      controller: _lngCtrl,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: InputDecoration(
                                        labelText: 'Longitude *',
                                        labelStyle:
                                            TextStyle(color: Colors.grey.shade400),
                                        hintText: '30.0619',
                                        hintStyle:
                                            TextStyle(color: Colors.grey.shade500),
                                        prefixIcon: Icon(Icons.east, color: categoryColor),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(25),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(25),
                                          borderSide:
                                              BorderSide(color: categoryColor, width: 2),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(25),
                                          borderSide: BorderSide.none,
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 16,
                                        ),
                                      ),
                                      validator: (value) =>
                                          _validateCoordinate(value, 'Longitude'),
                                      keyboardType: const TextInputType.numberWithOptions(
                                        decimal: true,
                                        signed: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Save Button ───────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _save,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(_isEditing ? Icons.save : Icons.add),
                        label: Text(
                          _isLoading
                              ? 'Saving...'
                              : _isEditing
                                  ? 'Save Changes'
                                  : 'Add Listing',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: categoryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    _descCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }
}