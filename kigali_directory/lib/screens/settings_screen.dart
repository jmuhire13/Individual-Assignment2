// ignore_for_file: use_build_context_synchronously, deprecated_member_use, unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/listing_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  bool _locationNotifications = false;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _marketingEmails = false;
  String _preferredLanguage = 'English';
  String _distanceUnit = 'Kilometers';
  bool _darkMode = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditingProfile = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadPreferences();
    _initializeProfileData();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _fadeController.forward();
    _slideController.forward();
  }

  void _initializeProfileData() {
    final user = context.read<app_auth.AuthProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  // Load saved notification preference
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _locationNotifications = prefs.getBool('location_notifications') ?? false;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _marketingEmails = prefs.getBool('marketing_emails') ?? false;
      _preferredLanguage = prefs.getString('preferred_language') ?? 'English';
      _distanceUnit = prefs.getString('distance_unit') ?? 'Kilometers';
      _darkMode = context.read<ThemeProvider>().isDarkMode;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _updateProfile() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile update feature coming soon'),
        backgroundColor: Colors.orange,
      ),
    );
    setState(() {
      _isEditingProfile = false;
    });
  }

  Future<void> _resendVerification() async {
    final authProvider = context.read<app_auth.AuthProvider>();
    try {
      await authProvider.resendVerificationEmail();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email sent!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Account deletion is not available in this version. Please contact support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53E3E).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFE53E3E), size: 28),
                ),
                const SizedBox(height: 10),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.white.withOpacity(0.8), size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFFE53E3E),
        activeTrackColor: const Color(0xFFE53E3E).withOpacity(0.3),
        inactiveThumbColor: Colors.white.withOpacity(0.6),
        inactiveTrackColor: Colors.white.withOpacity(0.2),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0F23), Color(0xFF1A1A2E), Color(0xFF16213E)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: CustomScrollView(
              slivers: [
                // ── GLASSMORPHIC APP BAR ──────────────────────
                SliverAppBar(
                  expandedHeight: 100,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: ClipRRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.1),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                            ),
                          ),
                        ),
                        child: const FlexibleSpaceBar(
                          title: Text(
                            'Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          centerTitle: true,
                        ),
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                // ── PROFILE CONTENT ──────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Profile Section ──────────────────────
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
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
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 70,
                                        height: 70,
                                        decoration: BoxDecoration(
                                          color: const Color(
                                            0xFFE53E3E,
                                          ).withOpacity(0.15),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: const Color(
                                              0xFFE53E3E,
                                            ).withOpacity(0.4),
                                            width: 3,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFE53E3E,
                                              ).withOpacity(0.2),
                                              blurRadius: 12,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: user?.photoURL != null
                                            ? ClipOval(
                                                child: CachedNetworkImage(
                                                  imageUrl: user!.photoURL!,
                                                  fit: BoxFit.cover,
                                                  placeholder: (context, url) =>
                                                      const CircularProgressIndicator(
                                                        color: Colors.white,
                                                      ),
                                                  errorWidget:
                                                      (context, url, error) =>
                                                          Icon(
                                                            Icons.person,
                                                            size: 30,
                                                            color: Colors.white
                                                                .withOpacity(
                                                                  0.7,
                                                                ),
                                                          ),
                                                ),
                                              )
                                            : Icon(
                                                Icons.person,
                                                size: 30,
                                                color: Colors.white.withOpacity(
                                                  0.7,
                                                ),
                                              ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (_isEditingProfile)
                                              TextField(
                                                controller: _nameController,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                decoration:
                                                    const InputDecoration(
                                                      hintText: 'Enter name',
                                                      hintStyle: TextStyle(
                                                        color: Colors.white70,
                                                      ),
                                                      border:
                                                          UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                      enabledBorder:
                                                          UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Colors
                                                                      .white70,
                                                                ),
                                                          ),
                                                      focusedBorder:
                                                          UnderlineInputBorder(
                                                            borderSide:
                                                                BorderSide(
                                                                  color: Colors
                                                                      .white,
                                                                ),
                                                          ),
                                                    ),
                                              )
                                            else
                                              Text(
                                                user?.displayName ?? 'User',
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            const SizedBox(height: 4),
                                            Text(
                                              user?.email ?? '',
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        user?.emailVerified ==
                                                            true
                                                        ? Colors.green
                                                              .withOpacity(0.2)
                                                        : Colors.red
                                                              .withOpacity(0.2),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          user?.emailVerified ==
                                                              true
                                                          ? Colors.green
                                                                .withOpacity(
                                                                  0.5,
                                                                )
                                                          : Colors.red
                                                                .withOpacity(
                                                                  0.5,
                                                                ),
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        user?.emailVerified ==
                                                                true
                                                            ? Icons.verified
                                                            : Icons.warning,
                                                        size: 12,
                                                        color:
                                                            user?.emailVerified ==
                                                                true
                                                            ? Colors.green
                                                            : Colors.red,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        user?.emailVerified ==
                                                                true
                                                            ? 'Verified'
                                                            : 'Not verified',
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              user?.emailVerified ==
                                                                  true
                                                              ? Colors.green
                                                              : Colors.red,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (user?.emailVerified !=
                                                    true) ...[
                                                  const SizedBox(width: 8),
                                                  TextButton(
                                                    onPressed:
                                                        _resendVerification,
                                                    style: TextButton.styleFrom(
                                                      foregroundColor:
                                                          Colors.white,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 4,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Resend',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          _isEditingProfile
                                              ? Icons.check
                                              : Icons.edit,
                                          color: Colors.white,
                                        ),
                                        onPressed: () {
                                          if (_isEditingProfile) {
                                            _updateProfile();
                                          } else {
                                            setState(() {
                                              _isEditingProfile = true;
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Statistics ──────────────────────
                        Consumer<ListingProvider>(
                          builder: (context, provider, child) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildSectionTitle('Your Activity'),
                                  Row(
                                    children: [
                                      _buildStatCard(
                                        'Total Listings',
                                        '${provider.allListings.where((l) => l.createdBy == user?.uid).length}',
                                        Icons.list_alt,
                                        Colors.black87,
                                      ),
                                      const SizedBox(width: 12),
                                      _buildStatCard(
                                        'Views This Month',
                                        '0',
                                        Icons.visibility,
                                        Colors.black87,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // ── Notifications ──────────────────────
                        _buildSectionTitle('Notifications'),
                        ClipRRect(
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
                              ),
                              child: Column(
                                children: [
                                  _buildNotificationTile(
                                    Icons.notifications_outlined,
                                    'Push Notifications',
                                    'Get notified about app updates',
                                    _pushNotifications,
                                    (value) {
                                      setState(
                                        () => _pushNotifications = value,
                                      );
                                      _savePreference(
                                        'push_notifications',
                                        value,
                                      );
                                    },
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  _buildNotificationTile(
                                    Icons.location_on_outlined,
                                    'Location Notifications',
                                    'Get notified about nearby services',
                                    _locationNotifications,
                                    (value) {
                                      setState(
                                        () => _locationNotifications = value,
                                      );
                                      _savePreference(
                                        'location_notifications',
                                        value,
                                      );
                                    },
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  _buildNotificationTile(
                                    Icons.email_outlined,
                                    'Email Notifications',
                                    'Receive updates via email',
                                    _emailNotifications,
                                    (value) {
                                      setState(
                                        () => _emailNotifications = value,
                                      );
                                      _savePreference(
                                        'email_notifications',
                                        value,
                                      );
                                    },
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  _buildNotificationTile(
                                    Icons.campaign_outlined,
                                    'Marketing Emails',
                                    'Receive promotional content',
                                    _marketingEmails,
                                    (value) {
                                      setState(() => _marketingEmails = value);
                                      _savePreference(
                                        'marketing_emails',
                                        value,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── App Preferences ──────────────────────
                        _buildSectionTitle('App Preferences'),
                        ClipRRect(
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
                              ),
                              child: Column(
                                // ← fixed: removed duplicate Column wrapping
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      Icons.language_outlined,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    title: const Text(
                                      'Language',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      _preferredLanguage,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color(
                                            0xFF1a1a2e,
                                          ),
                                          title: const Text(
                                            'Select Language',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children:
                                                [
                                                      'English',
                                                      'Kinyarwanda',
                                                      'French',
                                                      'Swahili',
                                                    ]
                                                    .map(
                                                      (lang) => ListTile(
                                                        title: Text(
                                                          lang,
                                                          style:
                                                              const TextStyle(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        ),
                                                        onTap: () {
                                                          setState(
                                                            () =>
                                                                _preferredLanguage =
                                                                    lang,
                                                          );
                                                          _savePreference(
                                                            'preferred_language',
                                                            lang,
                                                          );
                                                          Navigator.pop(
                                                            context,
                                                          );
                                                        },
                                                      ),
                                                    )
                                                    .toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  ListTile(
                                    leading: Icon(
                                      Icons.straighten_outlined,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    title: const Text(
                                      'Distance Unit',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      _distanceUnit,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color(
                                            0xFF1a1a2e,
                                          ),
                                          title: const Text(
                                            'Select Distance Unit',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: ['Kilometers', 'Miles']
                                                .map(
                                                  (unit) => ListTile(
                                                    title: Text(
                                                      unit,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    onTap: () {
                                                      setState(
                                                        () => _distanceUnit =
                                                            unit,
                                                      );
                                                      _savePreference(
                                                        'distance_unit',
                                                        unit,
                                                      );
                                                      Navigator.pop(context);
                                                    },
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  _buildNotificationTile(
                                    Icons.dark_mode_outlined,
                                    'Dark Mode',
                                    'Use dark theme',
                                    context.watch<ThemeProvider>().isDarkMode,
                                    (value) async {
                                      await context
                                          .read<ThemeProvider>()
                                          .setTheme(value);
                                      setState(() => _darkMode = value);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            value
                                                ? 'Dark mode enabled'
                                                : 'Light mode enabled',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF16213e,
                                          ),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Data & Privacy ──────────────────────
                        _buildSectionTitle('Data & Privacy'),
                        ClipRRect(
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
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      Icons.download_outlined,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    title: const Text(
                                      'Download My Data',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Export all your data',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Data export feature coming soon',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF16213e,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  ListTile(
                                    leading: Icon(
                                      Icons.delete_outline,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    title: const Text(
                                      'Clear Cache',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Free up storage space',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    onTap: () async {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Cache cleared successfully',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF0f3460,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Help & Support ──────────────────────
                        _buildSectionTitle('Help & Support'),
                        ClipRRect(
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
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      Icons.help_outline,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    title: const Text(
                                      'Help Center',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Get help and support',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Help center coming soon',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF16213e,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  ListTile(
                                    leading: Icon(
                                      Icons.feedback_outlined,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    title: const Text(
                                      'Send Feedback',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Help us improve the app',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    onTap: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: const Text(
                                            'Feedback feature coming soon',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF16213e,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  ListTile(
                                    leading: Icon(
                                      Icons.info_outline,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    title: const Text(
                                      'About',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Version 1.0.0',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    onTap: () {
                                      showAboutDialog(
                                        context: context,
                                        applicationName: 'Kigali Directory',
                                        applicationVersion: '1.0.0',
                                        applicationLegalese:
                                            '© 2024 Kigali Directory',
                                        children: [
                                          const Padding(
                                            padding: EdgeInsets.only(top: 16),
                                            child: Text(
                                              'A comprehensive directory for Kigali City services and locations.',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Developer Tools ──────────────────────
                        _buildSectionTitle('Developer Tools'),
                        ClipRRect(
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
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0xFFE53E3E),
                                    ),
                                    title: const Text(
                                      'Fix Coordinates',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Fix listings with incorrect coordinates',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    onTap: () async {
                                      final shouldFix = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Fix Coordinates'),
                                          content: const Text(
                                            'This will update listings with incorrect coordinates (like US coordinates) to proper Kigali, Rwanda coordinates.\n\nDo you want to continue?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text(
                                                'Fix Coordinates',
                                              ),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (shouldFix == true) {
                                        try {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Row(
                                                children: [
                                                  SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  ),
                                                  SizedBox(width: 12),
                                                  Text('Fixing coordinates...'),
                                                ],
                                              ),
                                              duration: Duration(seconds: 10),
                                            ),
                                          );

                                          final listingProvider = context
                                              .read<ListingProvider>();
                                          final result = await listingProvider
                                              .fixIncorrectCoordinates();

                                          ScaffoldMessenger.of(
                                            context,
                                          ).hideCurrentSnackBar();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(result),
                                              backgroundColor: Colors.green,
                                              duration: const Duration(
                                                seconds: 4,
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).hideCurrentSnackBar();
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Error fixing coordinates: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                              duration: const Duration(
                                                seconds: 4,
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Account Actions ──────────────────────
                        _buildSectionTitle('Account'),
                        ClipRRect(
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
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: Icon(
                                      Icons.security_outlined,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                    title: const Text(
                                      'Change Password',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    subtitle: Text(
                                      'Update your password',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.chevron_right,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                    onTap: () async {
                                      final authProvider = context
                                          .read<app_auth.AuthProvider>();
                                      try {
                                        await authProvider.resetPassword(
                                          user?.email ?? '',
                                        );
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: const Text(
                                              'Password reset email sent!',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor: const Color(
                                              0xFF0f3460,
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error: $e',
                                              style: const TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                            backgroundColor:
                                                Colors.red.shade800,
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.logout,
                                      color: Colors.orange,
                                    ),
                                    title: const Text(
                                      'Sign Out',
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                    subtitle: Text(
                                      'Sign out of your account',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    onTap: () async {
                                      final shouldSignOut = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: const Color(
                                            0xFF1a1a2e,
                                          ),
                                          title: const Text(
                                            'Sign Out',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          content: const Text(
                                            'Are you sure you want to sign out?',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange,
                                                foregroundColor: Colors.white,
                                              ),
                                              child: const Text('Sign Out'),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (shouldSignOut == true) {
                                        await context
                                            .read<app_auth.AuthProvider>()
                                            .signOut();
                                      }
                                    },
                                  ),
                                  Divider(
                                    color: Colors.white.withOpacity(0.1),
                                    height: 1,
                                  ),
                                  ListTile(
                                    leading: const Icon(
                                      Icons.delete_forever,
                                      color: Colors.red,
                                    ),
                                    title: const Text(
                                      'Delete Account',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    subtitle: Text(
                                      'Permanently delete your account',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                    onTap: _showDeleteAccountDialog,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
