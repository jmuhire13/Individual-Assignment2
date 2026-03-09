import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/listing_provider.dart';
import 'directory_screen.dart';
import 'my_listings_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';
import 'add_edit_listing_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // The 4 main screens
  final List<Widget> _screens = const [
    DirectoryScreen(),
    MyListingsScreen(),
    MapScreen(),
    SettingsScreen(),
  ];

  // Navigation configuration
  final List<NavigationItem> _navItems = [
    NavigationItem(
      icon: Icons.explore_outlined,
      activeIcon: Icons.explore,
      label: 'Explore',
      tooltip: 'Browse all listings',
    ),
    NavigationItem(
      icon: Icons.bookmark_outline,
      activeIcon: Icons.bookmark,
      label: 'My Listings',
      tooltip: 'Your saved listings',
    ),
    NavigationItem(
      icon: Icons.map_outlined,
      activeIcon: Icons.map,
      label: 'Map',
      tooltip: 'View on map',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profile',
      tooltip: 'Settings & profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeInOut),
    );

    // Initialize listing provider
    Future.microtask(() {
      if (mounted) {
        final listingProvider = context.read<ListingProvider>();
        listingProvider.initialize();
        _fabAnimationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) return;

    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),

      // ── FLOATING ACTION BUTTON ────────────────────────
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? ScaleTransition(
              scale: _fabAnimation,
              child: FloatingActionButton(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => const AddEditListingScreen(),
                    ),
                  );

                  // If listing was created successfully, the stream will automatically update
                  // But we can provide user feedback here
                  if (result == true && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Listing added successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                backgroundColor: const Color(0xFFE53E3E),
                foregroundColor: Colors.white,
                elevation: 8,
                child: const Icon(Icons.add, size: 28),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // ── GLASSMORPHIC FLOATING BOTTOM NAVIGATION ─────────────────
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        height: 70,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _navItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isSelected = index == _currentIndex;

                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _onNavTap(index),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // ── ICON WITH SELECTION BACKGROUND ────────────
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE53E3E)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Center(
                                        child: AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 200),
                                          child: Icon(
                                            isSelected
                                                ? item.activeIcon
                                                : item.icon,
                                            key: ValueKey(isSelected),
                                            size: 22,
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.white.withOpacity(0.7),
                                          ),
                                        ),
                                      ),

                                      // Badge for My Listings (show count)
                                      if (index == 1)
                                        Consumer<ListingProvider>(
                                          builder: (ctx, prov, _) {
                                            final count = prov.myListings.length;
                                            if (count == 0) return const SizedBox();

                                            return Positioned(
                                              right: -8,
                                              top: -4,
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                constraints: const BoxConstraints(
                                                  minWidth: 16,
                                                  minHeight: 16,
                                                ),
                                                child: Text(
                                                  count > 99
                                                      ? '99+'
                                                      : count.toString(),
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  ),
                                ),

                                // ── LABEL (ONLY FOR SELECTED ITEM) ─────────────
                                if (isSelected) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── NAVIGATION ITEM DATA CLASS ─────────────────────────────────────
class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String tooltip;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tooltip,
  });
}