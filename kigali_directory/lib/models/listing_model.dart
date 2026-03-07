import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class ListingModel {
  final String id;
  final String name;
  final String category;
  final String address;
  final String contactNumber;
  final String description;
  final double latitude;
  final double longitude;
  final String createdBy;
  final DateTime timestamp;

  // 📂 ASSIGNMENT REQUIRED CATEGORIES
  static const List<String> validCategories = [
    'Hospital',
    'Police Station',
    'Library',
    'Restaurant',
    'Café',
    'Park',
    'Tourist Attraction',
    'Utility Office', // Added from assignment description
  ];

  const ListingModel({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.contactNumber,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.createdBy,
    required this.timestamp,
  });

  // 🔒 SAFE: Reads ONE document from Firestore with error handling
  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      return ListingModel(
        id: doc.id,
        name: data['name']?.toString() ?? 'Unknown Place',
        category: data['category']?.toString() ?? validCategories.first,
        address: data['address']?.toString() ?? 'Address not provided',
        contactNumber: data['contactNumber']?.toString() ?? 'No contact',
        description:
            data['description']?.toString() ?? 'No description available',

        // Safe number parsing with fallbacks
        latitude: _parseDouble(data['latitude']) ?? -1.9441, // Kigali default
        longitude: _parseDouble(data['longitude']) ?? 30.0619, // Kigali default

        createdBy: data['createdBy']?.toString() ?? '',

        // Safe timestamp parsing
        timestamp: data['timestamp'] != null
            ? (data['timestamp'] as Timestamp).toDate()
            : DateTime.now(),
      );
    } catch (e) {
      // If parsing completely fails, return a safe default
      return ListingModel(
        id: doc.id,
        name: 'Unknown Place',
        category: validCategories.first,
        address: 'Address not provided',
        contactNumber: 'No contact',
        description: 'No description available',
        latitude: -1.9441, // Kigali city center
        longitude: 30.0619, // Kigali city center
        createdBy: '',
        timestamp: DateTime.now(),
      );
    }
  }

  // Helper method for safe double parsing
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Converts this object into a Map Firebase can save
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'address': address,
      'contactNumber': contactNumber,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'createdBy': createdBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  // Creates a copy with some fields replaced — used when editing
  ListingModel copyWith({
    String? name,
    String? category,
    String? address,
    String? contactNumber,
    String? description,
    double? latitude,
    double? longitude,
  }) {
    return ListingModel(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      address: address ?? this.address,
      contactNumber: contactNumber ?? this.contactNumber,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdBy: createdBy,
      timestamp: timestamp,
    );
  }

  // 🚀 PERFORMANCE: Proper equality for Provider optimization
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ListingModel &&
        other.id == id &&
        other.name == name &&
        other.category == category &&
        other.address == address &&
        other.contactNumber == contactNumber &&
        other.description == description &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.createdBy == createdBy &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        category.hashCode ^
        address.hashCode ^
        contactNumber.hashCode ^
        description.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        createdBy.hashCode ^
        timestamp.hashCode;
  }

  // 🐛 DEBUGGING: Clear toString for easier debugging
  @override
  String toString() {
    return 'ListingModel(id: $id, name: $name, category: $category, address: $address)';
  }

  // 📍 HELPER METHODS for business logic

  // Calculate distance to another location (in kilometers)
  double distanceTo(double otherLat, double otherLng) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    double dLat = _toRadians(otherLat - latitude);
    double dLng = _toRadians(otherLng - longitude);

    double a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(latitude)) *
            math.cos(_toRadians(otherLat)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180);

  // Validate if category is from assignment requirements
  bool get hasValidCategory => validCategories.contains(category);

  // Check if listing has complete information
  bool get isComplete {
    return name.isNotEmpty &&
        address.isNotEmpty &&
        description.isNotEmpty &&
        hasValidCategory &&
        latitude != 0 &&
        longitude != 0;
  }

  // Get Google Maps URL for navigation
  String get googleMapsUrl {
    return 'https://www.google.com/maps?q=$latitude,$longitude';
  }

  // Get human-readable time since created
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
}
