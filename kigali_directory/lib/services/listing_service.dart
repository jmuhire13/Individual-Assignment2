import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int _pageSize = 20;

  CollectionReference get _col => _db.collection('listings');
  String? get _currentUserId => _auth.currentUser?.uid;

  // Helper method for safe double parsing
  static double? _parseDoubleFromData(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Test Firebase connection
  Future<String> testConnection() async {
    try {
      print('🔥 Testing Firestore read access...');
      print('🔥 Collection path: listings');
      print(
        '🔥 Current user: ${_auth.currentUser?.email} (${_auth.currentUser?.uid})',
      );

      // Test collection access
      final QuerySnapshot result = await _col.limit(1).get();
      print('✅ Firestore accessible, found ${result.docs.length} documents');

      // Test if we can list all collections (for debugging)
      try {
        final collections = await _db.collection('listings').get();
        print(
          '🔍 Total documents in listings collection: ${collections.docs.length}',
        );

        if (collections.docs.isNotEmpty) {
          print(
            '📄 Sample document IDs: ${collections.docs.take(3).map((d) => d.id).join(', ')}',
          );
        }
      } catch (e) {
        print('❌ Could not count documents: $e');
      }

      final user = _auth.currentUser;
      if (user != null) {
        print('✅ User authenticated: ${user.email} (${user.uid})');
        return 'Connection OK - User: ${user.email}, Documents: ${result.docs.length}';
      } else {
        print('❌ User not authenticated');
        return 'Connection OK but user not authenticated';
      }
    } catch (e) {
      print('❌ Connection test failed: $e');
      throw e;
    }
  }

  // CREATE listing
  Future<String> addListing(ListingModel listing) async {
    if (_currentUserId == null) {
      throw Exception('Must be logged in to create listings');
    }

    print('🔥 Creating listing: ${listing.name}');

    final newListing = ListingModel(
      id: '',
      name: listing.name,
      category: listing.category,
      address: listing.address,
      contactNumber: listing.contactNumber,
      description: listing.description,
      latitude: listing.latitude,
      longitude: listing.longitude,
      createdBy: _currentUserId!,
      timestamp: DateTime.now(),
    );

    try {
      final docRef = await _col.add(newListing.toMap());
      print('✅ Document created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Firestore error: $e');

      // Provide specific error messages based on error type
      if (e.toString().contains('permission-denied')) {
        throw Exception('Permission denied: Check Firebase security rules');
      } else if (e.toString().contains('network-request-failed')) {
        throw Exception('Network error: Check internet connection');
      } else {
        throw Exception('Failed to create listing: ${e.toString()}');
      }
    }
  }

  // READ ALL listings
  Stream<List<ListingModel>> getListings({int pageSize = _pageSize}) {
    print('🔥 Setting up Firestore stream for listings...');
    print('🔥 Collection: listings, Page size: $pageSize');
    print('🔥 Current user: ${_auth.currentUser?.email}');

    return _col.limit(pageSize).snapshots().map((snap) {
      print('📡 Firestore snapshot received: ${snap.docs.length} documents');

      if (snap.docs.isEmpty) {
        print('⚠️  No documents found in collection. Possible causes:');
        print('   - Collection is empty');
        print('   - Security rules are blocking access');
        print('   - Wrong collection name');
        print('   - Network connectivity issues');
      }

      final listings = snap.docs
          .map((doc) {
            try {
              final listing = ListingModel.fromFirestore(doc);
              print('✅ Parsed listing: ${listing.name} (ID: ${doc.id})');
              return listing;
            } catch (e) {
              print('❌ Error parsing document ${doc.id}: $e');
              print('❌ Document data: ${doc.data()}');
              return null;
            }
          })
          .where((listing) => listing != null)
          .cast<ListingModel>()
          .toList();

      // Sort by timestamp (newest first)
      listings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('📋 Returning ${listings.length} valid listings');
      return listings;
    });
  }

  // READ user's listings
  Stream<List<ListingModel>> getMyListings() {
    if (_currentUserId == null) return Stream.value([]);

    print('🔥 Setting up user listings stream for: $_currentUserId');

    return _col.where('createdBy', isEqualTo: _currentUserId).snapshots().map((
      snap,
    ) {
      print('📡 User listings snapshot: ${snap.docs.length} documents');

      final listings = snap.docs
          .map((doc) {
            try {
              return ListingModel.fromFirestore(doc);
            } catch (e) {
              print('❌ Error parsing user document ${doc.id}: $e');
              return null;
            }
          })
          .where((listing) => listing != null)
          .cast<ListingModel>()
          .toList();

      listings.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      print('📋 Returning ${listings.length} user listings');
      return listings;
    });
  }

  // READ by category
  Stream<List<ListingModel>> getListingsByCategory(String category) {
    print('🔥 Setting up category filter for: $category');

    return _col
        .where('category', isEqualTo: category)
        .limit(_pageSize)
        .snapshots()
        .map((snap) {
          final listings = snap.docs
              .map((doc) {
                try {
                  return ListingModel.fromFirestore(doc);
                } catch (e) {
                  return null;
                }
              })
              .where((listing) => listing != null)
              .cast<ListingModel>()
              .toList();

          listings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return listings;
        });
  }

  // SEARCH listings by name (Assignment requirement)
  Future<List<ListingModel>> searchListings(String searchTerm) async {
    try {
      print('🔍 Searching for: $searchTerm');

      if (searchTerm.trim().isEmpty) {
        print('🔍 Empty search term, returning empty results');
        return [];
      }

      // Get all listings and filter in memory (no orderBy to avoid indexes)
      final snap = await _col
          .limit(_pageSize * 3) // Get more results for better filtering
          .get();

      print('🔍 Search: Retrieved ${snap.docs.length} docs to filter');

      final filteredListings = snap.docs
          .map((doc) {
            try {
              return ListingModel.fromFirestore(doc);
            } catch (e) {
              print('❌ Error parsing search document ${doc.id}: $e');
              return null;
            }
          })
          .where((listing) => listing != null)
          .cast<ListingModel>()
          .where((listing) {
            final searchLower = searchTerm.toLowerCase().trim();
            final nameMatch = listing.name.toLowerCase().contains(searchLower);
            final descMatch = listing.description.toLowerCase().contains(
              searchLower,
            );
            final addressMatch = listing.address.toLowerCase().contains(
              searchLower,
            );
            final categoryMatch = listing.category.toLowerCase().contains(
              searchLower,
            );

            final matches =
                nameMatch || descMatch || addressMatch || categoryMatch;
            if (matches) {
              print('🔍 Match found: ${listing.name}');
            }
            return matches;
          })
          .toList();

      // Sort results by relevance (name matches first, then others)
      filteredListings.sort((a, b) {
        final searchLower = searchTerm.toLowerCase().trim();
        final aNameMatch = a.name.toLowerCase().contains(searchLower);
        final bNameMatch = b.name.toLowerCase().contains(searchLower);

        if (aNameMatch && !bNameMatch) return -1;
        if (!aNameMatch && bNameMatch) return 1;

        return a.name.compareTo(b.name);
      });

      print(
        '🔍 Search results: ${filteredListings.length} matches for "$searchTerm"',
      );
      return filteredListings;
    } catch (e) {
      print('❌ Search failed: $e');
      throw Exception('Search failed: ${e.toString()}');
    }
  }

  // UPDATE listing (Assignment: Only user's own listings)
  Future<void> updateListing(String id, Map<String, dynamic> data) async {
    if (_currentUserId == null) {
      throw Exception('Must be logged in to update listings');
    }

    try {
      // 🔒 ASSIGNMENT RULE: Check ownership before updating
      final docSnapshot = await _col.doc(id).get();
      if (!docSnapshot.exists) {
        throw Exception('Listing not found');
      }

      final listing = ListingModel.fromFirestore(docSnapshot);
      if (listing.createdBy != _currentUserId) {
        throw Exception('You can only update your own listings');
      }

      // Prevent changing ownership or creation time
      data.remove('createdBy');
      data.remove('timestamp');

      await _col.doc(id).update(data);
    } catch (e) {
      throw Exception('Failed to update listing: ${e.toString()}');
    }
  }

  // DELETE listing (Assignment: Only user's own listings)
  Future<void> deleteListing(String id) async {
    if (_currentUserId == null) {
      throw Exception('Must be logged in to delete listings');
    }

    try {
      // 🔒 ASSIGNMENT RULE: Check ownership before deleting
      final docSnapshot = await _col.doc(id).get();
      if (!docSnapshot.exists) {
        throw Exception('Listing not found');
      }

      final listing = ListingModel.fromFirestore(docSnapshot);
      if (listing.createdBy != _currentUserId) {
        throw Exception('You can only delete your own listings');
      }

      await _col.doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete listing: ${e.toString()}');
    }
  }

  // BATCH DELETE multiple listings
  Future<void> deleteMultipleListings(List<String> listingIds) async {
    if (_currentUserId == null) {
      throw Exception('Must be logged in to delete listings');
    }

    final batch = _db.batch();

    for (String id in listingIds) {
      // Verify ownership for each listing
      final docSnapshot = await _col.doc(id).get();
      if (docSnapshot.exists) {
        final listing = ListingModel.fromFirestore(docSnapshot);
        if (listing.createdBy == _currentUserId) {
          batch.delete(_col.doc(id));
        }
      }
    }

    await batch.commit();
  }

  // Add sample data for testing (if collection is empty)
  Future<String> addSampleData() async {
    if (_currentUserId == null) {
      throw Exception('Must be logged in to add sample data');
    }

    try {
      print('🔥 Adding sample listings for testing...');

      final sampleListings = [
        ListingModel(
          id: '',
          name: 'Kigali University Hospital',
          category: 'Hospital',
          address: 'KN 4 Ave, Kigali',
          contactNumber: '+250 788 123 456',
          description: 'Main public hospital in Kigali with emergency services',
          latitude: -1.9394,
          longitude: 30.0644,
          createdBy: _currentUserId!,
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        ListingModel(
          id: '',
          name: 'Nyamirambo Police Station',
          category: 'Police Station',
          address: 'Nyamirambo, Kigali',
          contactNumber: '+250 788 654 321',
          description: 'Local police station serving Nyamirambo area',
          latitude: -1.9706,
          longitude: 30.0394,
          createdBy: _currentUserId!,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        ListingModel(
          id: '',
          name: 'Kigali Public Library',
          category: 'Library',
          address: 'KN 82 St, Kigali',
          contactNumber: '+250 788 111 222',
          description: 'Main public library with books and computer access',
          latitude: -1.9536,
          longitude: 30.0606,
          createdBy: _currentUserId!,
          timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
        ListingModel(
          id: '',
          name: 'Heaven Restaurant',
          category: 'Restaurant',
          address: 'Kacyiru, Kigali',
          contactNumber: '+250 788 333 444',
          description:
              'Popular restaurant with local and international cuisine',
          latitude: -1.9242,
          longitude: 30.1067,
          createdBy: _currentUserId!,
          timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        ),
      ];

      int addedCount = 0;
      for (final listing in sampleListings) {
        try {
          await addListing(listing);
          addedCount++;
          print('✅ Added sample: ${listing.name}');
        } catch (e) {
          print('❌ Failed to add ${listing.name}: $e');
        }
      }

      return 'Added $addedCount sample listings successfully';
    } catch (e) {
      throw Exception('Failed to add sample data: ${e.toString()}');
    }
  }

  // Fix listings with incorrect coordinates (US coordinates instead of Kigali)
  Future<String> fixIncorrectCoordinates() async {
    if (_currentUserId == null) {
      throw Exception('Must be logged in to fix coordinates');
    }

    try {
      print('🔧 Checking for listings with incorrect coordinates...');

      // Get all listings to check coordinates
      final snap = await _col.get();
      int fixedCount = 0;

      for (final doc in snap.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final latitude = _parseDoubleFromData(data['latitude']) ?? 0;
          final longitude = _parseDoubleFromData(data['longitude']) ?? 0;

          // Check if coordinates are outside Kigali range
          final isKigaliLatitude = latitude >= -2.5 && latitude <= -1.0;
          final isKigaliLongitude = longitude >= 29.0 && longitude <= 31.0;

          if (!isKigaliLatitude || !isKigaliLongitude) {
            print(
              '🔧 Found incorrect coordinates in ${data['name']}: $latitude, $longitude',
            );

            // Update with correct Kigali coordinates based on location type
            double newLat, newLng;
            final category = data['category'] ?? '';
            final name = data['name'] ?? '';

            // Assign realistic Kigali coordinates based on category/name
            if (category == 'Hospital' ||
                name.toLowerCase().contains('hospital')) {
              newLat = -1.9394;
              newLng = 30.0644; // Kigali University Hospital area
            } else if (category == 'Police Station') {
              newLat = -1.9706;
              newLng = 30.0394; // Nyamirambo area
            } else if (category == 'Library') {
              newLat = -1.9536;
              newLng = 30.0606; // City center
            } else if (category == 'Restaurant') {
              newLat = -1.9242;
              newLng = 30.1067; // Kacyiru area
            } else if (category == 'Park') {
              newLat = -1.9395;
              newLng = 30.0644; // Near city center
            } else {
              newLat = -1.9441;
              newLng = 30.0619; // Kigali city center default
            }

            // Update the document
            await _col.doc(doc.id).update({
              'latitude': newLat,
              'longitude': newLng,
            });

            print('✅ Fixed coordinates for ${data['name']}: $newLat, $newLng');
            fixedCount++;
          }
        } catch (e) {
          print('❌ Error checking document ${doc.id}: $e');
        }
      }

      return 'Fixed coordinates for $fixedCount listings';
    } catch (e) {
      throw Exception('Failed to fix coordinates: ${e.toString()}');
    }
  }
}
