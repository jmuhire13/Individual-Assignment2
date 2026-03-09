# Kigali Directory

A Flutter mobile app for discovering and managing essential services and locations in Kigali, Rwanda. Users can browse hospitals, restaurants, parks, police stations, and more — with real-time data, interactive maps, and a glassmorphic dark UI.

## Features

- **Authentication** — Sign up, login, email verification, and password reset via Firebase Auth
- **Explore Directory** — Browse all listings with category filtering and debounced search
- **Interactive Maps** — View locations on OpenStreetMap with clustered markers; launch navigation to Google Maps
- **CRUD Listings** — Create, edit, and delete listings with GPS coordinate capture and Kigali region validation
- **My Listings** — Manage your own listings with ownership-based permissions
- **Listing Details** — Glassmorphic detail page with embedded map, contact info, directions, and sharing
- **Profile & Settings** — User profile, dark/light theme toggle, notification preferences, language selection
- **Glassmorphic UI** — Dark gradient background with frosted-glass cards, blur effects, and accent-colored chips throughout

## Supported Categories

Hospital · Police Station · Library · Restaurant · Café · Park · Tourist Attraction · Utility Office

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter + Dart |
| Backend | Firebase Core, Firebase Auth, Cloud Firestore |
| Maps | flutter_map (OpenStreetMap), flutter_map_marker_cluster, Geolocator, LatLng2 |
| State Management | Provider |
| Local Storage | SharedPreferences, CachedNetworkImage |
| UI | Shimmer loading, BackdropFilter glassmorphism, Material Design 3 |
| Utilities | url_launcher, image_picker, intl, http |

## Project Structure

```
lib/
├── main.dart                       # Entry point & Firebase init
├── firebase_options.dart           # Firebase config
├── models/
│   ├── listing_model.dart          # Listing data model
│   └── user_model.dart             # User profile model
├── providers/
│   ├── auth_provider.dart          # Auth state management
│   ├── listing_provider.dart       # Listings CRUD & real-time sync
│   └── theme_provider.dart         # Theme & preferences
├── services/
│   ├── auth_service.dart           # Firebase Auth integration
│   └── listing_service.dart        # Firestore operations
├── screens/
│   ├── login_screen.dart           # Login
│   ├── signup_screen.dart          # Registration
│   ├── verify_email_screen.dart    # Email verification
│   ├── main_screen.dart            # Bottom nav shell
│   ├── directory_screen.dart       # Explorer / browse listings
│   ├── map_screen.dart             # Full map view
│   ├── detail_screen.dart          # Listing detail
│   ├── add_edit_listing_screen.dart # Create / edit form
│   ├── my_listings_screen.dart     # User's listings
│   └── settings_screen.dart        # Profile & settings
└── widgets/
    ├── listing_card.dart           # Glassmorphic listing card
    ├── glassmorphic_category_chips.dart  # Category filter pills
    ├── custom_search_bar.dart      # Search bar widget
    └── category_chip.dart          # Category chip
```

## Setup

```bash
# Clone & install
git clone <repo-url>
cd Individual-Assignment2/kigali_directory
flutter pub get

# Firebase setup
# Place google-services.json in android/app/
# Run: flutterfire configure

# Run
flutter run
```

**Requirements:** Flutter 3.16+, Android SDK 21+ / iOS 12+, Firebase project with Auth + Firestore enabled.

## Firestore Schema

```
listings/{id}
  ├── name, category, address, contactNumber, description
  ├── latitude, longitude
  ├── createdBy (uid), timestamp, updatedAt

users/{uid}
  ├── name, email, createdAt, preferences
```

**Security Rules:** Public read, authenticated create, owner-only update/delete.

## License

MIT
- **Demo Video:** [Insert Video URL]
- **Firebase Console:** [Project: kigalidirectory-5c898]

---

### Technical Stack Summary

**Flutter 3.16+** | **Firebase Backend** | **OpenStreetMap + Google Maps Navigation** | **Provider State Management** | **Material Design 3**
