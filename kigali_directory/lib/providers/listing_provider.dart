import 'dart:async';
import 'package:flutter/material.dart';
import '../models/listing_model.dart';
import '../services/listing_service.dart';

class ListingProvider extends ChangeNotifier {
  final ListingService _service = ListingService();

  // ── STATE VARIABLES ──────────────────────────────────────────────────
  List<ListingModel> _listings = []; // All listings (shared directory)
  List<ListingModel> _myListings = []; // Current user's listings
  List<ListingModel> _searchResults = []; // Search results

  bool _isLoading = false; // General loading state
  bool _isCrudLoading = false; // Loading for create/update/delete
  String? _errorMessage; // Error message for UI

  String _searchQuery = ''; // Current search term
  String? _selectedCategory; // Current category filter

  StreamSubscription? _allListingsSubscription; // Stream for all listings
  StreamSubscription? _myListingsSubscription; // Stream for user's listings
  StreamSubscription? _categorySubscription; // Stream for category filter

  // ── GETTERS (Assignment: UI access to state) ────────────────────────
  bool get isLoading => _isLoading;
  bool get isCrudLoading => _isCrudLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;

  // All listings for shared directory (Assignment requirement)
  List<ListingModel> get allListings => _listings;

  // User's own listings for "My Listings" screen (Assignment requirement)
  List<ListingModel> get myListings => _myListings;

  // Search results (Assignment: search by name functionality)
  List<ListingModel> get searchResults => _searchResults;

  // Filtered listings with search + category filter (Assignment requirements)
  List<ListingModel> get filteredListings {
    List<ListingModel> sourceList = _searchQuery.isNotEmpty
        ? _searchResults
        : _listings;

    return sourceList.where((listing) {
      final matchesCategory =
          _selectedCategory == null || listing.category == _selectedCategory;
      return matchesCategory;
    }).toList();
  }

  // Check if user owns a specific listing (for edit/delete permissions)
  bool canModifyListing(ListingModel listing, String? currentUserId) {
    return currentUserId != null && listing.createdBy == currentUserId;
  }

  // ── INITIALIZATION (Assignment: Real-time updates) ──────────────────

  // Start listening to all listings for shared directory
  void startListeningToAllListings() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _allListingsSubscription = _service.getListings().listen(
      (listings) {
        _listings = listings;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        _isLoading = false;
        _errorMessage = 'Failed to load listings: ${error.toString()}';
        notifyListeners();
      },
    );
  }

  // Start listening to current user's listings for "My Listings" screen
  void startListeningToMyListings() {
    _myListingsSubscription = _service.getMyListings().listen(
      (myListings) {
        _myListings = myListings;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load your listings: ${error.toString()}';
        notifyListeners();
      },
    );
  }

  // Initialize all streams (call this when user logs in)
  void initialize() {
    startListeningToAllListings();
    startListeningToMyListings();
  }

  // Stop all streams (call this when user logs out)
  void cleanup() {
    _allListingsSubscription?.cancel();
    _myListingsSubscription?.cancel();
    _categorySubscription?.cancel();

    _listings.clear();
    _myListings.clear();
    _searchResults.clear();
    _searchQuery = '';
    _selectedCategory = null;
    _errorMessage = null;

    notifyListeners();
  }

  // ── CRUD OPERATIONS (Assignment: Create, Read, Update, Delete) ──────

  // CREATE: Add new listing (Assignment requirement)
  Future<bool> addListing(ListingModel listing) async {
    _isCrudLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.addListing(listing);
      _isCrudLoading = false;
      notifyListeners();

      // Show success feedback
      _showSuccessMessage('Listing created successfully!');
      return true;
    } catch (e) {
      _isCrudLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // UPDATE: Update existing listing (Assignment: Only user's own listings)
  Future<bool> updateListing(String id, Map<String, dynamic> data) async {
    _isCrudLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.updateListing(id, data);
      _isCrudLoading = false;
      notifyListeners();

      _showSuccessMessage('Listing updated successfully!');
      return true;
    } catch (e) {
      _isCrudLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // DELETE: Delete listing (Assignment: Only user's own listings)
  Future<bool> deleteListing(String id) async {
    _isCrudLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteListing(id);
      _isCrudLoading = false;
      notifyListeners();

      _showSuccessMessage('Listing deleted successfully!');
      return true;
    } catch (e) {
      _isCrudLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // DELETE MULTIPLE: Batch delete for better UX
  Future<bool> deleteMultipleListings(List<String> listingIds) async {
    _isCrudLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.deleteMultipleListings(listingIds);
      _isCrudLoading = false;
      notifyListeners();

      _showSuccessMessage(
        '${listingIds.length} listings deleted successfully!',
      );
      return true;
    } catch (e) {
      _isCrudLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ── SEARCH & FILTER (Assignment: Search by name + filter by category) ─

  // Search listings by name (Assignment requirement)
  Future<void> searchListings(String searchTerm) async {
    _searchQuery = searchTerm.trim();

    if (_searchQuery.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _service.searchListings(_searchQuery);
      _searchResults = results;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Search failed: ${e.toString()}';
      _searchResults.clear();
      notifyListeners();
    }
  }

  // Set search query (for debounced input)
  void setSearch(String query) {
    _searchQuery = query.trim();

    // If search is cleared, clear results
    if (_searchQuery.isEmpty) {
      _searchResults.clear();
    }

    notifyListeners();
  }

  // Filter by category (Assignment requirement)
  void setCategory(String? category) {
    _selectedCategory = category;

    // If filtering by category, start listening to category-specific stream
    if (category != null) {
      _categorySubscription?.cancel();
      _categorySubscription = _service
          .getListingsByCategory(category)
          .listen(
            (categoryListings) {
              // Update the main listings with filtered results for better UX
              notifyListeners();
            },
            onError: (error) {
              _errorMessage =
                  'Failed to filter by category: ${error.toString()}';
              notifyListeners();
            },
          );
    } else {
      _categorySubscription?.cancel();
    }

    notifyListeners();
  }

  // Clear search and filters
  void clearSearchAndFilters() {
    _searchQuery = '';
    _selectedCategory = null;
    _searchResults.clear();
    _categorySubscription?.cancel();
    _errorMessage = null;
    notifyListeners();
  }

  // ── UTILITY METHODS ──────────────────────────────────────────────────

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Show success message (temporary)
  void _showSuccessMessage(String message) {
    // In a real app, you might use a different mechanism for success messages
    // For now, we'll just clear any existing error
    _errorMessage = null;
    notifyListeners();

    // Could trigger a success callback here if needed
  }

  // Get listing by ID (helper method)
  ListingModel? getListingById(String id) {
    try {
      return _listings.firstWhere((listing) => listing.id == id);
    } catch (e) {
      try {
        return _myListings.firstWhere((listing) => listing.id == id);
      } catch (e) {
        return null;
      }
    }
  }

  // Get statistics for user dashboard
  Map<String, dynamic> get userStatistics {
    return {
      'totalListings': _listings.length,
      'myListings': _myListings.length,
      'categoryCounts': _getCategoryCounts(),
      'recentListings': _listings
          .where((l) => DateTime.now().difference(l.timestamp).inDays <= 7)
          .length,
    };
  }

  // Helper: Get count of listings by category
  Map<String, int> _getCategoryCounts() {
    final counts = <String, int>{};
    for (final listing in _listings) {
      counts[listing.category] = (counts[listing.category] ?? 0) + 1;
    }
    return counts;
  }

  // Refresh all data (for pull-to-refresh functionality)
  Future<void> refresh() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Cancel existing subscriptions and restart them
      _cleanupSubscriptions();
      initialize();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to refresh data: ${e.toString()}';
      notifyListeners();
    }
  }

  // Public method for refresh (used by UI)
  Future<void> refreshListings() async {
    return refresh();
  }

  // Clean up all subscriptions
  void _cleanupSubscriptions() {
    _allListingsSubscription?.cancel();
    _myListingsSubscription?.cancel();
    _categorySubscription?.cancel();
  }

  // Always cancel subscriptions when done to avoid memory leaks
  @override
  void dispose() {
    _cleanupSubscriptions();
    super.dispose();
  }
}
