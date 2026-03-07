import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/listing_provider.dart';
import '../widgets/listing_card.dart';
import 'detail_screen.dart';
import 'package:shimmer/shimmer.dart';

class DirectoryScreen extends StatefulWidget {
  const DirectoryScreen({super.key});

  @override
  State<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends State<DirectoryScreen> {
  Timer? _searchDebounce;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Update UI when search text changes
    });
  }

  void _onSearchChanged(String value) {
    // Cancel previous timer
    _searchDebounce?.cancel();

    // Start new timer - only search after 500ms of no typing
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      context.read<ListingProvider>().setSearch(value);
    });
  }

  Future<void> _onRefresh() async {
    await context.read<ListingProvider>().refreshListings();
  }

  void _clearSearch() {
    _searchController.clear();
    context.read<ListingProvider>().setSearch('');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  static const List<String> _categories = [
    'All',
    'Hospital',
    'Police Station',
    'Library',
    'Restaurant',
    'Café',
    'Park',
    'Tourist Attraction',
    'Utility Office', // Added from assignment requirements
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Kigali Directory'),
        backgroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _onRefresh,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Colors.black,
        child: Column(
          children: [
            // ── Search Bar ───────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search for services, restaurants, attractions...',
                  hintStyle: TextStyle(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey.shade600),
                          onPressed: _clearSearch,
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                onChanged: _onSearchChanged,
              ),
            ),

            // ── Category Filter Chips ────────────
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Consumer<ListingProvider>(
                builder: (ctx, prov, _) => ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _categories.map((cat) {
                    final isAll = cat == 'All';
                    final selected = isAll
                        ? prov.selectedCategory == null
                        : prov.selectedCategory == cat;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: FilterChip(
                        label: Text(
                          cat,
                          style: TextStyle(
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: selected ? Colors.white : Colors.black,
                            fontSize: 12,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) => prov.setCategory(isAll ? null : cat),
                        backgroundColor: Colors.grey.shade100,
                        selectedColor: Colors.black,
                        checkmarkColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: selected
                                ? Colors.black
                                : Colors.grey.shade300,
                          ),
                        ),
                        elevation: selected ? 2 : 0,
                        pressElevation: 1,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // ── Listings List ────────────────────
            Expanded(
              child: Consumer<ListingProvider>(
                builder: (ctx, prov, _) {
                  if (prov.isLoading && prov.allListings.isEmpty) {
                    // Show shimmer loading effect for initial load
                    return _buildShimmerList();
                  }

                  if (prov.filteredListings.isEmpty && !prov.isLoading) {
                    return _buildEmptyState(prov.searchQuery.isNotEmpty);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount:
                        prov.filteredListings.length + (prov.isLoading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      // Show loading indicator at bottom if loading more
                      if (i >= prov.filteredListings.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final listing = prov.filteredListings[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ListingCard(
                          listing: listing,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailScreen(listing: listing),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        itemBuilder: (ctx, i) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            height: 100,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 200,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 100,
                        color: Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isSearchResult) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchResult ? Icons.search_off : Icons.location_city_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              isSearchResult ? 'No results found' : 'No listings available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isSearchResult
                  ? 'Try adjusting your search terms or filters'
                  : 'Check back later for new listings',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            if (isSearchResult) ...[
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  _clearSearch();
                  context.read<ListingProvider>().setCategory(null);
                },
                child: const Text(
                  'Clear filters',
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
    );
  }
}
