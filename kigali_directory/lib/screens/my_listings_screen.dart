// ignore_for_file: unused_element, deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:ui';
import '../providers/listing_provider.dart';
import '../widgets/listing_card.dart';
import '../widgets/custom_search_bar.dart';
import '../widgets/glassmorphic_category_chips.dart';
import 'add_edit_listing_screen.dart';
import 'detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  Timer? _searchDebounce;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSelectMode = false;
  final Set<String> _selectedListings = {};

  @override
  void initState() {
    super.initState();
    // Removed controller listener as CustomSearchBar now handles its own state
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value.toLowerCase();
      });
    });
  }

  Future<void> _clearSearch() async {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      if (!_isSelectMode) {
        _selectedListings.clear();
      }
    });
  }

  void _toggleSelection(String listingId) {
    setState(() {
      if (_selectedListings.contains(listingId)) {
        _selectedListings.remove(listingId);
      } else {
        _selectedListings.add(listingId);
      }
    });
  }

  void _selectAll(List<dynamic> listings) {
    setState(() {
      if (_selectedListings.length == listings.length) {
        _selectedListings.clear();
      } else {
        _selectedListings.addAll(listings.map((l) => l.id.toString()));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedListings.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Listings'),
        content: Text(
          'Are you sure you want to delete ${_selectedListings.length} listings? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<ListingProvider>();
      final success = await provider.deleteMultipleListings(
        _selectedListings.toList(),
      );

      if (success && mounted) {
        _toggleSelectMode();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Selected listings deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _onRefresh() async {
    await context.read<ListingProvider>().refreshListings();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0F23),
            Color(0xFF1A1A2E),
            Color(0xFF16213E),
          ],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: Colors.white,
            child: Consumer<ListingProvider>(
              builder: (ctx, prov, _) {
                // Filter to show only current user's listings
                var myListings = prov.myListings
                    .where((l) => l.createdBy == uid)
                    .toList();

                // Apply search filter if active
                if (_searchQuery.isNotEmpty) {
                  myListings = myListings
                      .where(
                        (l) =>
                            l.name.toLowerCase().contains(_searchQuery) ||
                            l.category.toLowerCase().contains(_searchQuery) ||
                            l.address.toLowerCase().contains(_searchQuery),
                      )
                      .toList();
                }

                if (prov.isLoading && myListings.isEmpty) {
                  return _buildShimmerList();
                }

                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── STATISTICS SECTION ────────────────────
                      _buildStatisticsSection(prov, myListings),

                      // ── SEARCH BAR ─────────────────────────────
                      if (myListings.isNotEmpty)
                        CustomSearchBar(
                          controller: _searchController,
                          hintText: 'Search your listings...',
                          onChanged: _onSearchChanged,
                          onClear: () async {
                            await _clearSearch();
                          },
                          showFilterIcon: false,
                        ),

                      // ── LISTINGS CONTENT ───────────────────────
                      myListings.isEmpty
                          ? _buildEmptyState()
                          : _buildListingsView(myListings),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── BUILD APP BAR ─────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        _isSelectMode ? '${_selectedListings.length} selected' : 'My Listings',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: _isSelectMode
          ? IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _toggleSelectMode,
            )
          : null,
      actions: [
        if (_isSelectMode) ...[
          if (_selectedListings.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deleteSelected,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'select_all') {
                final provider = context.read<ListingProvider>();
                final uid = FirebaseAuth.instance.currentUser!.uid;
                final myListings = provider.myListings
                    .where((l) => l.createdBy == uid)
                    .toList();
                _selectAll(myListings);
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'select_all',
                child: Text('Select All'),
              ),
            ],
          ),
        ] else ...[
          IconButton(
            icon: const Icon(Icons.checklist, color: Colors.white),
            onPressed: _toggleSelectMode,
            tooltip: 'Select multiple',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditListingScreen()),
              );
            },
            tooltip: 'Add new listing',
          ),
        ],
      ],
    );
  }

  // ── BUILD STATISTICS SECTION ─────────────────────────────────────────────────────
  Widget _buildStatisticsSection(
    ListingProvider prov,
    List<dynamic> myListings,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total',
                    myListings.length.toString(),
                    Icons.list_alt,
                    const Color(0xFFE53E3E),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Categories',
                    _getCategoryCount(myListings).toString(),
                    Icons.category,
                    const Color(0xFFE53E3E),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Recent',
                    _getRecentCount(myListings).toString(),
                    Icons.schedule,
                    const Color(0xFFE53E3E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  int _getCategoryCount(List<dynamic> listings) {
    return listings.map((l) => l.category).toSet().length;
  }

  int _getRecentCount(List<dynamic> listings) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return listings.where((l) => l.timestamp.isAfter(weekAgo)).length;
  }

  // ── BUILD SEARCH SECTION ─────────────────────────────────────────────────────────
  Widget _buildSearchSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search your listings...',
          hintStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade400),
                  onPressed: _clearSearch,
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
    );
  }

  // ── BUILD EMPTY STATE ─────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    final isSearchResult = _searchQuery.isNotEmpty;

    return SizedBox(
      height: 400,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(60),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  isSearchResult ? Icons.search_off : Icons.add_business,
                  size: 60,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isSearchResult ? 'No matching listings' : 'No listings yet',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearchResult
                    ? 'Try different search terms'
                    : 'Share your favorite places in Kigali with others',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              if (!isSearchResult) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddEditListingScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Your First Listing'),
                ),
              ] else ...[
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _clearSearch,
                  child: const Text(
                    'Clear search',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── BUILD LISTINGS VIEW ──────────────────────────────────────────────────────────
  Widget _buildListingsView(List<dynamic> myListings) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: myListings.length,
      itemBuilder: (ctx, i) {
        final listing = myListings[i];
        final isSelected = _selectedListings.contains(listing.id);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _isSelectMode
              ? _buildSelectableListingCard(listing, isSelected)
              : _buildSwipeableListingCard(listing),
        );
      },
    );
  }

  Widget _buildSelectableListingCard(dynamic listing, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleSelection(listing.id),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? Colors.blue : Colors.grey.shade400,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ListingCard(
                  listing: listing,
                  onTap: () => _toggleSelection(listing.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeableListingCard(dynamic listing) {
    return Dismissible(
      key: ValueKey(listing.id),
      background: Container(
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text('Edit', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      secondaryBackground: Container(
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 24),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Edit action
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddEditListingScreen(listing: listing),
            ),
          );
          return false;
        } else {
          // Delete action
          return await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Listing'),
                  content: Text(
                    'Are you sure you want to delete "${listing.name}"?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ) ??
              false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          context.read<ListingProvider>().deleteListing(listing.id);
        }
      },
      child: ListingCard(
        listing: listing,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DetailScreen(listing: listing)),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.3),
      child: Column(
        children: [
          // Shimmer for statistics
          Container(
            margin: const EdgeInsets.all(16),
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          // Shimmer for search
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          // Shimmer for listings
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 6,
              itemBuilder: (ctx, i) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}