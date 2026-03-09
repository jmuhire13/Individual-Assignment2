// ignore_for_file: deprecated_member_use, unnecessary_to_list_in_spreads, unused_field

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'dart:ui' as ui;
import '../providers/listing_provider.dart';
import '../models/listing_model.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  Timer? _searchDebounce;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _showSearch = false;
  latlong.LatLng? _currentLocation;
  bool _isLoadingLocation = false;
  bool _followLocation = false;

  // Map style options
  bool _isDarkMode = false;
  double _currentZoom = 13.0;

  // Kigali city bounds for better UX
  static const _kigaliCenter = latlong.LatLng(-1.9441, 30.0619);

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );
    _fabAnimationController.forward();

    _searchController.addListener(() {
      setState(() {});
    });

    _getCurrentLocation();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      print('🌍 Getting current location...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('🌍 Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        _showLocationError(
          'Location services are disabled. Please enable GPS in your device settings.',
        );
        return;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      print('🌍 Current permission: $permission');

      if (permission == LocationPermission.denied) {
        print('🌍 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('🌍 Permission after request: $permission');

        if (permission == LocationPermission.denied) {
          _showLocationError(
            'Location permission denied. Please grant location access in app settings.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationError(
          'Location permissions permanently denied. Please enable in device settings.',
        );
        return;
      }

      print('🌍 Getting position with high accuracy...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      print(
        '🌍 Raw GPS coordinates: ${position.latitude}, ${position.longitude}',
      );
      print('🌍 Accuracy: ${position.accuracy}m');
      print('🌍 Altitude: ${position.altitude}m');
      print('🌍 Speed: ${position.speed}m/s');

      // Validate if coordinates make sense for Rwanda/East Africa
      bool isValidRwandaLocation = _isValidRwandaCoordinates(
        position.latitude,
        position.longitude,
      );
      print('🌍 Is valid Rwanda location: $isValidRwandaLocation');

      if (!isValidRwandaLocation) {
        print(
          '⚠️ Detected coordinates appear to be outside Rwanda/East Africa',
        );
        print('⚠️ GPS returned: ${position.latitude}, ${position.longitude}');
        print('⚠️ This looks like US/default coordinates');

        // Show warning and use approximate Kigali location instead
        _showLocationWarningAndUseKigali(position.latitude, position.longitude);
        return;
      }

      setState(() {
        _currentLocation = latlong.LatLng(
          position.latitude,
          position.longitude,
        );
        _isLoadingLocation = false;
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location found in Rwanda! Accuracy: ${position.accuracy.round()}m',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Location error: $e');
      _showLocationError(
        'Failed to get location: ${e.toString()}\n\nTry:\n• Enable GPS\n• Grant location permission\n• Check internet connection',
      );
    }
  }

  void _showLocationError(String message) {
    setState(() => _isLoadingLocation = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Try Again',
            textColor: Colors.white,
            onPressed: _getCurrentLocation,
          ),
        ),
      );
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      // Use the provider's search functionality for consistency
      await context.read<ListingProvider>().setSearch(value);
      setState(() => _searchQuery = value.toLowerCase());
    });
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    await context.read<ListingProvider>().setSearch('');
    setState(() => _searchQuery = '');
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _clearSearch();
      }
    });
  }

  void _moveToCurrentLocation() {
    if (_currentLocation != null) {
      print(
        '🎯 Moving to current location: ${_currentLocation!.latitude}, ${_currentLocation!.longitude}',
      );
      _mapController.move(_currentLocation!, 16.0);
      setState(() => _followLocation = true);
    } else {
      print('🎯 Current location not available, getting location...');
      _getCurrentLocation();
    }
  }

  void _moveToKigali() {
    _mapController.move(_kigaliCenter, 13.0);
    setState(() => _followLocation = false);
  }

  void _showLocationHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 8),
            Text('Location Help'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Why can\'t I see my location on the map?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('• Location services must be enabled on your device'),
              SizedBox(height: 4),
              Text('• Grant location permission to this app'),
              SizedBox(height: 4),
              Text('• Ensure GPS or network location is available'),
              SizedBox(height: 4),
              Text('• Check internet connection'),
              SizedBox(height: 12),
              Text(
                'Emulator Users:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('• Set location in emulator settings'),
              Text('• Or use "Go to Kigali Center" option'),
              SizedBox(height: 12),
              Text(
                'The blue location button (📍) will show your current position when available.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _getCurrentLocation();
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // Validate if coordinates are within Rwanda/East Africa region
  bool _isValidRwandaCoordinates(double latitude, double longitude) {
    // Rwanda boundaries (approximate):
    // Latitude: -2.9 to -1.0 (South to North)
    // Longitude: 28.8 to 30.9 (West to East)
    // Adding buffer for East Africa region

    const double minLat = -3.0; // South boundary (with buffer)
    const double maxLat = -0.5; // North boundary (with buffer)
    const double minLng = 28.5; // West boundary (with buffer)
    const double maxLng = 31.5; // East boundary (with buffer)

    return latitude >= minLat &&
        latitude <= maxLat &&
        longitude >= minLng &&
        longitude <= maxLng;
  }

  // Show warning about incorrect coordinates and use Kigali fallback
  void _showLocationWarningAndUseKigali(
    double detectedLat,
    double detectedLng,
  ) {
    // Use approximate location for user's area (24 KG 3 Ave, Kigali)
    const kigaliUserLocation = latlong.LatLng(
      -1.9506,
      30.0618,
    ); // Near KG 3 Ave area

    setState(() {
      _currentLocation = kigaliUserLocation;
      _isLoadingLocation = false;
    });

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 8),
              Text('Location Detected Outside Rwanda'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'GPS returned coordinates that appear to be in the US, not Rwanda:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Detected: $detectedLat, $detectedLng'),
              const SizedBox(height: 12),
              const Text(
                'This usually happens when:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• Using an Android emulator with default US location',
              ),
              const Text('• VPN is active and masking location'),
              const Text('• GPS/location services not properly configured'),
              const SizedBox(height: 12),
              const Text(
                'Using approximate Kigali location instead (KG 3 Ave area).',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSetManualLocationDialog();
              },
              child: const Text('Set Manual Location'),
            ),
          ],
        ),
      );
    }
  }

  // Dialog to manually set location to user's specific area
  void _showSetManualLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Your Location'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Since GPS detection isn\'t working correctly, you can manually set your location:',
            ),
            SizedBox(height: 12),
            Text(
              '1. KG 3 Ave Area (your mentioned location)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('2. Kigali City Center'),
            Text('3. Kacyiru District'),
            Text('4. Nyamirambo District'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _setManualLocation('kg3_ave');
            },
            child: const Text('KG 3 Ave Area'),
          ),
        ],
      ),
    );
  }

  // Set manual location based on user selection
  void _setManualLocation(String locationKey) {
    latlong.LatLng selectedLocation;
    String locationName;

    switch (locationKey) {
      case 'kg3_ave':
        selectedLocation = const latlong.LatLng(
          -1.9506,
          30.0618,
        ); // Near KG 3 Ave
        locationName = 'KG 3 Ave Area (24 KG 3 Ave, Kigali)';
        break;
      case 'city_center':
        selectedLocation = const latlong.LatLng(-1.9441, 30.0619);
        locationName = 'Kigali City Center';
        break;
      default:
        selectedLocation = const latlong.LatLng(-1.9506, 30.0618);
        locationName = 'KG 3 Ave Area';
    }

    setState(() {
      _currentLocation = selectedLocation;
      _followLocation = true;
    });

    _mapController.move(selectedLocation, 16.0);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location manually set to $locationName'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return Icons.local_hospital;
      case 'police station':
        return Icons.local_police;
      case 'library':
        return Icons.library_books;
      case 'restaurant':
        return Icons.restaurant;
      case 'café':
      case 'cafe':
        return Icons.local_cafe;
      case 'park':
        return Icons.park;
      case 'tourist attraction':
        return Icons.attractions;
      case 'utility office':
        return Icons.business;
      default:
        return Icons.location_on;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'hospital':
        return Colors.red;
      case 'police station':
        return Colors.blue;
      case 'library':
        return Colors.purple;
      case 'restaurant':
        return Colors.orange;
      case 'café':
      case 'cafe':
        return Colors.brown;
      case 'park':
        return Colors.green;
      case 'tourist attraction':
        return Colors.pink;
      case 'utility office':
        return Colors.grey;
      default:
        return Colors.red;
    }
  }

  List<ListingModel> _getFilteredListings(
    List<ListingModel> listings,
    ListingProvider provider,
  ) {
    // Use the provider's filtered listings instead of doing our own filtering
    var filtered = provider.filteredListings;

    // Only apply additional category filter if we have a local category selection
    // that differs from the provider's category
    if (_selectedCategory != null &&
        _selectedCategory != provider.selectedCategory) {
      filtered = filtered
          .where((listing) => listing.category == _selectedCategory)
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── MAP WIDGET ─────────────────────────────────────────────────────────────────
          Consumer<ListingProvider>(
            builder: (ctx, prov, _) {
              if (prov.isLoading && prov.allListings.isEmpty) {
                return _buildMapLoadingState();
              }

              final filteredListings = _getFilteredListings(
                prov.allListings,
                prov,
              );
              final markers = _buildMarkers(filteredListings);

              return FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _kigaliCenter,
                  initialZoom: _currentZoom,
                  minZoom: 10.0,
                  maxZoom: 18.0,
                  onPositionChanged: (position, hasGesture) {
                    if (hasGesture) {
                      setState(() => _followLocation = false);
                    }
                    _currentZoom = position.zoom;
                  },
                ),
                children: [
                  // ── BASE MAP LAYER ──────────────────────────────────────────────────────
                  TileLayer(
                    urlTemplate: _isDarkMode
                        ? 'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png'
                        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.kigali.directory',
                    maxZoom: 18,
                  ),

                  // ── CURRENT LOCATION MARKER ────────────────────────────────────────────
                  if (_currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentLocation!,
                          width: 30,
                          height: 30,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                  // ── LISTING MARKERS WITH CLUSTERING ─────────────────────────────────────
                  MarkerClusterLayerWidget(
                    options: MarkerClusterLayerOptions(
                      maxClusterRadius: 120,
                      size: const Size(40, 40),
                      markers: markers,
                      builder: (context, markers) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              markers.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          // ── SEARCH OVERLAY ──────────────────────────────────────────────────────────────
          if (_showSearch) _buildSearchOverlay(),

          // ── CATEGORY FILTER ─────────────────────────────────────────────────────────────
          _buildCategoryFilter(),

          // ── MAP CONTROLS ────────────────────────────────────────────────────────────────
          _buildMapControls(),
        ],
      ),
    );
  }

  // ── BUILD APP BAR ──────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Map View',
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _showSearch ? Icons.close : Icons.search,
            color: Colors.black,
          ),
          onPressed: _toggleSearch,
          tooltip: _showSearch ? 'Close search' : 'Search locations',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.layers, color: Colors.black),
          onSelected: (value) {
            switch (value) {
              case 'style':
                setState(() => _isDarkMode = !_isDarkMode);
                break;
              case 'kigali':
                _moveToKigali();
                break;
              case 'set_manual_location':
                _showSetManualLocationDialog();
                break;
              case 'location_help':
                _showLocationHelp();
                break;
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'style',
              child: Row(
                children: [
                  Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
                  const SizedBox(width: 12),
                  Text(_isDarkMode ? 'Light Mode' : 'Dark Mode'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'kigali',
              child: Row(
                children: [
                  Icon(Icons.location_city),
                  SizedBox(width: 12),
                  Text('Center on Kigali'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'set_manual_location',
              child: Row(
                children: [
                  Icon(Icons.place, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Set My Location'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'location_help',
              child: Row(
                children: [
                  Icon(Icons.help_outline),
                  SizedBox(width: 12),
                  Text('Location Help'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── BUILD MARKERS ──────────────────────────────────────────────────────────────────
  List<Marker> _buildMarkers(List<ListingModel> listings) {
    return listings.map((listing) {
      final categoryColor = _getCategoryColor(listing.category);
      final categoryIcon = _getCategoryIcon(listing.category);

      return Marker(
        point: latlong.LatLng(listing.latitude, listing.longitude),
        width: 40,
        height: 50,
        child: GestureDetector(
          onTap: () => _showListingBottomSheet(listing),
          child: Column(
            children: [
              // ── CUSTOM MARKER ICON ──────────────────────────────────────────────────
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: categoryColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(categoryIcon, color: Colors.white, size: 18),
              ),
              // ── MARKER PIN ──────────────────────────────────────────────────────────
              CustomPaint(
                size: const Size(8, 18),
                painter: MarkerPinPainter(categoryColor),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  // ── BUILD SEARCH OVERLAY ───────────────────────────────────────────────────────────
  Widget _buildSearchOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search locations on map...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade400),
                      onPressed: () async {
                        await _clearSearch();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ),
      ),
    );
  }

  // ── BUILD CATEGORY FILTER ──────────────────────────────────────────────────────────
  Widget _buildCategoryFilter() {
    const categories = [
      'Hospital',
      'Police Station',
      'Library',
      'Restaurant',
      'Café',
      'Park',
      'Tourist Attraction',
      'Utility Office',
    ];

    return Positioned(
      bottom: 100,
      left: 0,
      right: 0,
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            // ── ALL CATEGORIES CHIP ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('All'),
                selected: _selectedCategory == null,
                onSelected: (_) => setState(() => _selectedCategory = null),
                backgroundColor: Colors.white,
                selectedColor: Colors.black,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: _selectedCategory == null
                      ? Colors.white
                      : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // ── CATEGORY CHIPS ──────────────────────────────────────────────────────
            ...categories.map((category) {
              final isSelected = _selectedCategory == category;
              final categoryColor = _getCategoryColor(category);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  avatar: Icon(
                    _getCategoryIcon(category),
                    size: 16,
                    color: isSelected ? Colors.white : categoryColor,
                  ),
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => setState(() {
                    _selectedCategory = isSelected ? null : category;
                  }),
                  backgroundColor: Colors.white,
                  selectedColor: categoryColor,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // ── BUILD MAP CONTROLS ─────────────────────────────────────────────────────────────
  Widget _buildMapControls() {
    return Positioned(
      bottom: 180,
      right: 16,
      child: Column(
        children: [
          // ── CURRENT LOCATION BUTTON ─────────────────────────────────────────────
          ScaleTransition(
            scale: _fabAnimation,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _followLocation ? Colors.blue : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _isLoadingLocation ? null : _moveToCurrentLocation,
                  child: Tooltip(
                    message: _currentLocation != null
                        ? 'Go to my location'
                        : 'Get my current location',
                    child: _isLoadingLocation
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.grey,
                            ),
                          )
                        : Icon(
                            Icons.my_location,
                            color: _followLocation
                                ? Colors.white
                                : Colors.black,
                            size: 20,
                          ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── ZOOM CONTROLS ───────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                    onTap: () {
                      final newZoom = (_currentZoom + 1).clamp(10.0, 18.0);
                      _mapController.move(
                        _mapController.camera.center,
                        newZoom,
                      );
                    },
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.add, color: Colors.black),
                    ),
                  ),
                ),
                Container(width: 40, height: 1, color: Colors.grey.shade300),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    onTap: () {
                      final newZoom = (_currentZoom - 1).clamp(10.0, 18.0);
                      _mapController.move(
                        _mapController.camera.center,
                        newZoom,
                      );
                    },
                    child: const SizedBox(
                      width: 40,
                      height: 40,
                      child: Icon(Icons.remove, color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── BUILD MAP LOADING STATE ────────────────────────────────────────────────────────
  Widget _buildMapLoadingState() {
    return Container(
      color: Colors.grey.shade100,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.black, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Loading map data...',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  // ── SHOW LISTING BOTTOM SHEET ──────────────────────────────────────────────────────
  void _showListingBottomSheet(ListingModel listing) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── BOTTOM SHEET HANDLE ─────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── LISTING INFO ────────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getCategoryColor(
                        listing.category,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(listing.category),
                      color: _getCategoryColor(listing.category),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          listing.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          listing.address,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            listing.category,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── ACTION BUTTONS ──────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // Move map to listing location
                        _mapController.move(
                          latlong.LatLng(listing.latitude, listing.longitude),
                          16.0,
                        );
                      },
                      icon: const Icon(Icons.center_focus_strong),
                      label: const Text('Center'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(color: Colors.grey.shade400),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailScreen(listing: listing),
                          ),
                        );
                      },
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── MARKER PIN PAINTER ─────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
class MarkerPinPainter extends CustomPainter {
  final Color color;

  MarkerPinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = ui.Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
