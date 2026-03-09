import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/listing_model.dart';

class ListingCard extends StatelessWidget {
  final ListingModel listing;
  final VoidCallback onTap;

  const ListingCard({super.key, required this.listing, required this.onTap});

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
        return Icons.place;
    }
  }

  Color _getCategoryColor(String category) {
    // Return accent color for all categories in dark theme
    return const Color(0xFFE53E3E);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              splashColor: Colors.white.withOpacity(0.1),
              highlightColor: Colors.white.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // ── CATEGORY ICON ──────────────────────
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(listing.category),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getCategoryColor(listing.category).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _getCategoryIcon(listing.category),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // ── LISTING DETAILS ───────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── LISTING NAME ────────────────────
                          Text(
                            listing.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // ── ADDRESS ────────────────────────
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  listing.address,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // ── CATEGORY CHIP ─────────────────────
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              listing.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── CHEVRON ICON ───────────────────────
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withOpacity(0.6),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
