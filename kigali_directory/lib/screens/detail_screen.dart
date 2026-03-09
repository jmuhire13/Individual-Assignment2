// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/listing_model.dart';

class DetailScreen extends StatefulWidget {
  final ListingModel listing;
  const DetailScreen({super.key, required this.listing});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Hospital':
        return Icons.local_hospital;
      case 'Police Station':
        return Icons.local_police;
      case 'Library':
        return Icons.library_books;
      case 'Restaurant':
        return Icons.restaurant;
      case 'Café':
        return Icons.local_cafe;
      case 'Park':
        return Icons.park;
      case 'Tourist Attraction':
        return Icons.attractions;
      default:
        return Icons.place;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Hospital':
        return Colors.red;
      case 'Police Station':
        return Colors.blue;
      case 'Library':
        return Colors.brown;
      case 'Restaurant':
        return Colors.orange;
      case 'Café':
        return Colors.amber;
      case 'Park':
        return Colors.green;
      case 'Tourist Attraction':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Future<void> _openDirections() async {
    try {
      // Debug: Print the actual coordinates being used
      print('🗺️ Opening directions for: ${widget.listing.name}');
      // ignore: avoid_print
      print(
        '🗺️ Coordinates: ${widget.listing.latitude}, ${widget.listing.longitude}',
      );

      // Check if coordinates are in Kigali range
      final isKigaliLatitude =
          widget.listing.latitude >= -2.5 && widget.listing.latitude <= -1.0;
      final isKigaliLongitude =
          widget.listing.longitude >= 29.0 && widget.listing.longitude <= 31.0;

      if (!isKigaliLatitude || !isKigaliLongitude) {
        _showSnackBar(
          '⚠️ Warning: This location appears to be outside Kigali area',
          Colors.orange,
        );
        print(
          '⚠️ Coordinates seem wrong for Kigali: ${widget.listing.latitude}, ${widget.listing.longitude}',
        );
      }

      final url = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${widget.listing.latitude},${widget.listing.longitude}',
      );

      print('🗺️ Google Maps URL: $url');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _showSnackBar('Opening Google Maps...', Colors.green);
      } else {
        // Fallback to geo: scheme
        final geoUrl = Uri.parse(
          'geo:${widget.listing.latitude},${widget.listing.longitude}',
        );
        if (await canLaunchUrl(geoUrl)) {
          await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
          _showSnackBar('Opening Maps...', Colors.green);
        } else {
          _showSnackBar(
            'No maps app found. Please install Google Maps.',
            Colors.orange,
          );
        }
      }
    } catch (e) {
      print('Error opening directions: $e');
      _showSnackBar('Could not open maps', Colors.red);
    }
  }

  Future<void> _makePhoneCall() async {
    try {
      final url = Uri.parse('tel:${widget.listing.contactNumber}');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _showSnackBar('Opening phone app...', Colors.green);
      } else {
        _showSnackBar(
          'Phone calling not supported on this device',
          Colors.orange,
        );
      }
    } catch (e) {
      print('Error making phone call: $e');
      _showSnackBar('Could not make phone call', Colors.red);
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    _showSnackBar('$label copied to clipboard', Colors.green);
  }

  void _shareListing() {
    // Share functionality would require share_plus package
    // For now, copy address to clipboard instead
    _copyToClipboard(
      '${widget.listing.name}\n${widget.listing.address}\n${widget.listing.contactNumber}',
      'Listing info',
    );
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

  @override
  Widget build(BuildContext context) {
    final position = LatLng(widget.listing.latitude, widget.listing.longitude);
    final categoryColor = _getCategoryColor(widget.listing.category);
    final categoryIcon = _getCategoryIcon(widget.listing.category);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          slivers: [
            // ── Custom App Bar with Map ─────────────────────
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: Colors.white,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: _shareListing,
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    FlutterMap(
                      options: MapOptions(
                        initialCenter: position,
                        initialZoom: 15,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.kigali_directory',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: position,
                              width: 50,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: categoryColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  categoryIcon,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Gradient overlay for better text readability
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.7),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Content ─────────────────────────────────────
            SliverToBoxAdapter(
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header Section ──────────────────────
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: categoryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: categoryColor.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    categoryIcon,
                                    size: 16,
                                    color: categoryColor,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    widget.listing.category,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: categoryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          widget.listing.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Contact Information ──────────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.location_on,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Address',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.listing.address,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.copy, size: 20),
                                    onPressed: () => _copyToClipboard(
                                      widget.listing.address,
                                      'Address',
                                    ),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.phone,
                                      size: 20,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Contact Number',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          widget.listing.contactNumber,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.copy, size: 20),
                                        onPressed: () => _copyToClipboard(
                                          widget.listing.contactNumber,
                                          'Phone number',
                                        ),
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.call, size: 20),
                                        onPressed: _makePhoneCall,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Description ──────────────────────────
                        const Text(
                          'About',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Text(
                            widget.listing.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.6,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // ── Action Buttons ──────────────────────
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _openDirections,
                                icon: const Icon(Icons.directions),
                                label: const Text('Get Directions'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _shareListing,
                                icon: const Icon(Icons.share),
                                label: const Text('Share'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  side: const BorderSide(color: Colors.blue),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
