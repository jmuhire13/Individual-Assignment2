import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/listing_model.dart';

class ListingService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const int _pageSize = 20; // Load only 20 listings at a time

  // Shortcut to the 'listings' collection
  CollectionReference get _col => _db.collection('listings');

  // Get current user ID - needed for assignment ownership validation
  String? get _currentUserId => _auth.currentUser?.uid;

  // ── CREATE (Assignment Requirement: Only authenticated users) ─────
  Future<String> addListing(ListingModel listing) async {
    // 🔒 ASSIGNMENT RULE: Must be authenticated to create listings
    if (_currentUserId == null) {
      throw Exception('Must be logged in to create listings');
    }

    // 🔒 ASSIGNMENT RULE: Create new listing with enforced ownership
    final newListing = ListingModel(
      id: '', // Firestore will generate ID
      name: listing.name,
      category: listing.category,
      address: listing.address,
      contactNumber: listing.contactNumber,
      description: listing.description,
      latitude: listing.latitude,
      longitude: listing.longitude,
      createdBy: _currentUserId!, // Force current user as owner
      timestamp: DateTime.now(), // Use server time
    );

    try {
      final docRef = await _col.add(newListing.toMap());
      return docRef.id; // Return the generated ID
    } catch (e) {
      throw Exception('Failed to create listing: ${e.toString()}');
    }
  }

  // ── READ ALL (Assignment: Shared directory for all users) ──────────
  // Returns a live stream with limited results for better performance
  Stream<List<ListingModel>> getListings({int pageSize = _pageSize}) {
    return _col
        .orderBy('timestamp', descending: true)
        .limit(pageSize) // Only load first 20 listings
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList(),
        );
  }

  // ── READ BY CATEGORY (Assignment: Filter by category) ──────────────
  Stream<List<ListingModel>> getListingsByCategory(String category) {
    return _col
        .where('category', isEqualTo: category)
        .orderBy('timestamp', descending: true)
        .limit(_pageSize)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList(),
        );
  }

  // ── READ BY USER (Assignment: "My Listings" screen) ────────────────
  Stream<List<ListingModel>> getMyListings() {
    if (_currentUserId == null) return Stream.value([]);

    return _col
        .where('createdBy', isEqualTo: _currentUserId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList(),
        );
  }

  // ── SEARCH BY NAME (Assignment: Search listings by name) ───────────
  Future<List<ListingModel>> searchListings(String searchTerm) async {
    try {
      // Firestore doesn't support case-insensitive search directly
      // We'll get all listings and filter in memory for now
      // In production, you'd use Algolia or similar for better search
      final snap = await _col
          .orderBy('name')
          .startAt([searchTerm.toLowerCase()])
          .endAt([searchTerm.toLowerCase() + '\uf8ff'])
          .limit(_pageSize * 2) // Get more results for filtering
          .get();

      return snap.docs
          .map((doc) => ListingModel.fromFirestore(doc))
          .where(
            (listing) =>
                listing.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
                listing.description.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                ) ||
                listing.address.toLowerCase().contains(
                  searchTerm.toLowerCase(),
                ),
          )
          .toList();
    } catch (e) {
      throw Exception('Search failed: ${e.toString()}');
    }
  }

  // ── READ NEXT PAGE ───────────────────────────────────
  // For pagination - load more listings
  Future<List<ListingModel>> getNextPage(
    DocumentSnapshot lastDoc, {
    int pageSize = _pageSize,
  }) async {
    final snap = await _col
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDoc)
        .limit(pageSize)
        .get();

    return snap.docs.map((doc) => ListingModel.fromFirestore(doc)).toList();
  }

  // ── UPDATE (Assignment: Only user's own listings) ──────────────────
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

  // ── DELETE (Assignment: Only user's own listings) ──────────────────
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

  // ── BATCH OPERATIONS (For better performance) ──────────────────────
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
}
