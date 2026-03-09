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
    // Avoid duplicate subscriptions
    _allListingsSubscription?.cancel();

    print('Starting to listen to all listings...');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _allListingsSubscription = _service.getListings().listen(
      (listings) {
        print('Received ${listings.length} listings from Firebase');
        _listings = listings;
        _isLoading = false;

        // If we have search results, re-apply search to new data
        if (_searchQuery.isNotEmpty && _searchResults.isEmpty) {
          _performSearch(_searchQuery);
        }

        notifyListeners();
      },
      onError: (error) {
        print('Error loading listings: $error');
        _isLoading = false;
        _errorMessage = 'Failed to load listings: ${error.toString()}';
        notifyListeners();
      },
    );
  }

  // Start listening to current user's listings for "My Listings" screen
  void startListeningToMyListings() {
    // Avoid duplicate subscriptions
    _myListingsSubscription?.cancel();

    _myListingsSubscription = _service.getMyListings().listen(
      (myListings) {
        _myListings = myListings;
        notifyListeners();
      },
      onError: (error) {
        print('Error loading my listings: $error');
        // Don't override main error message unless it's empty
        if (_errorMessage == null) {
          _errorMessage = 'Failed to load your listings: ${error.toString()}';
          notifyListeners();
        }
      },
    );
  }

  // Initialize all streams (call this when user logs in)
  void initialize() {
    print('ListingProvider.initialize() called');

    // Cleanup any existing streams first
    _cleanupSubscriptions();

    // Clear error state
    _errorMessage = null;

    // Start fresh
    startListeningToAllListings();
    startListeningToMyListings();
  }

  // Test Firebase connection
  Future<String> testFirebaseConnection() async {
    try {
      print('Testing Firebase connection...');
      final result = await _service.testConnection();
      print('Firebase connection test: $result');
      return result;
    } catch (e) {
      print('Firebase connection failed: $e');
      _errorMessage = 'Firebase connection failed: $e';
      notifyListeners();
      throw e;
    }
  }

  // Add sample data for testing (if collection is empty)
  Future<String> addSampleData() async {
    try {
      final result = await _service.addSampleData();
      print('Sample data added: $result');
      return result;
    } catch (e) {
      print('Failed to add sample data: $e');
      throw e;
    }
  }

  // Stop all streams (call this when user logs out)
  void cleanup() {
    print('Cleaning up ListingProvider...');

    _cleanupSubscriptions();

    // Reset all state
    _listings.clear();
    _myListings.clear();
    _searchResults.clear();
    _searchQuery = '';
    _selectedCategory = null;
    _errorMessage = null;
    _isLoading = false;
    _isCrudLoading = false;

    notifyListeners();
  }

  // ── CRUD OPERATIONS (Assignment: Create, Read, Update, Delete) ──────

  // CREATE: Add new listing (Assignment requirement)
  Future<bool> addListing(ListingModel listing) async {
    print('Adding listing: ${listing.name}');
    _isCrudLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final docId = await _service.addListing(listing);
      print('Listing created with ID: $docId');

      _isCrudLoading = false;
      notifyListeners();

      // Show success feedback
      _showSuccessMessage('Listing created successfully!');

      // Note: Don't manually refresh - the Firestore stream will automatically
      // pick up the new listing and update the UI

      return true;
    } catch (e) {
      print('Error creating listing: $e');
      _isCrudLoading = false;

      // Provide user-friendly error messages
      if (e.toString().contains('permission-denied')) {
        _errorMessage =
            'Permission denied. Please check your Firebase security rules.';
      } else if (e.toString().contains('network-request-failed')) {
        _errorMessage = 'Network error. Please check your internet connection.';
      } else {
        _errorMessage = 'Failed to create listing: ${e.toString()}';
      }

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

  // Helper method to perform search without changing loading state
  Future<void> _performSearch(String searchTerm) async {
    try {
      final results = await _service.searchListings(searchTerm);
      _searchResults = results;
    } catch (e) {
      print('Background search failed: $e');
      _searchResults.clear();
    }
  }

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
  Future<void> setSearch(String query) async {
    _searchQuery = query.trim();

    // If search is cleared, clear results
    if (_searchQuery.isEmpty) {
      _searchResults.clear();
      notifyListeners();
      return;
    }

    // Trigger actual search
    await searchListings(_searchQuery);
  }

  // Filter by category (Assignment requirement)
  void setCategory(String? category) {
    // Cancel any existing category subscription first
    _categorySubscription?.cancel();

    _selectedCategory = category;

    // Only create specific category stream if we're filtering
    // Most of the time, we'll just use the main listings with client-side filtering
    if (category != null) {
      // Optional: Create category-specific stream for better performance with large datasets
      // For now, we'll rely on client-side filtering which is simpler and more reliable
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
    print('Refreshing all data...');

    // Don't show loading spinner for refresh, just refresh in background
    _errorMessage = null;

    try {
      // Force refresh by restarting streams
      await _restartStreams();

      print('Data refreshed successfully');
    } catch (e) {
      print('Refresh failed: $e');
      _errorMessage = 'Failed to refresh data: ${e.toString()}';
      notifyListeners();
    }
  }

  // Helper method to restart all streams
  Future<void> _restartStreams() async {
    // Cancel existing subscriptions
    _cleanupSubscriptions();

    // Small delay to ensure cleanup is complete
    await Future.delayed(const Duration(milliseconds: 100));

    // Restart streams
    startListeningToAllListings();
    startListeningToMyListings();
  }

  // Public method for refresh (used by UI)
  Future<void> refreshListings() async {
    return refresh();
  }

  // Fix listings with incorrect coordinates (Developer tool)
  Future<String> fixIncorrectCoordinates() async {
    try {
      final result = await _service.fixIncorrectCoordinates();
      print('Coordinates fixed: $result');
      return result;
    } catch (e) {
      print('Failed to fix coordinates: $e');
      throw e;
    }
  }

  // Clean up all subscriptions
  // Always cancel subscriptions when done to avoid memory leaks
  @override
  void dispose() {
    _cleanupSubscriptions();
    super.dispose();
  }

  // Clean up all subscriptions (improved version)
  void _cleanupSubscriptions() {
    _allListingsSubscription?.cancel();
    _allListingsSubscription = null;

    _myListingsSubscription?.cancel();
    _myListingsSubscription = null;

    _categorySubscription?.cancel();
    _categorySubscription = null;
  }
}