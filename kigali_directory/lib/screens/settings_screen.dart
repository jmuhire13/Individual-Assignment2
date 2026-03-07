import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/auth_provider.dart' as app_auth;
import '../providers/listing_provider.dart';

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
      _darkMode = prefs.getBool('dark_mode') ?? false;
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
    // Note: Firebase Auth doesn't directly support updating profile
    // This would need to be implemented in AuthProvider
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
          color: Colors.grey[600],
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Profile Section ──────────────────────
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[600]!, Colors.blue[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Hero(
                          tag: 'profile_avatar',
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 3,
                              ),
                            ),
                            child: user?.photoURL != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: user!.photoURL!,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) =>
                                          Icon(
                                            Icons.person,
                                            size: 30,
                                            color: Colors.blue[600],
                                          ),
                                    ),
                                  )
                                : Icon(
                                    Icons.person,
                                    size: 30,
                                    color: Colors.blue[600],
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_isEditingProfile)
                                TextField(
                                  controller: _nameController,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Enter name',
                                    hintStyle: TextStyle(color: Colors.white70),
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
                                      ),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white70,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.white,
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
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: user?.emailVerified == true
                                          ? Colors.green.withOpacity(0.2)
                                          : Colors.red.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: user?.emailVerified == true
                                            ? Colors.green.withOpacity(0.5)
                                            : Colors.red.withOpacity(0.5),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          user?.emailVerified == true
                                              ? Icons.verified
                                              : Icons.warning,
                                          size: 12,
                                          color: user?.emailVerified == true
                                              ? Colors.green
                                              : Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          user?.emailVerified == true
                                              ? 'Verified'
                                              : 'Not verified',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: user?.emailVerified == true
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (user?.emailVerified != true) ...[
                                    const SizedBox(width: 8),
                                    TextButton(
                                      onPressed: _resendVerification,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                      ),
                                      child: const Text(
                                        'Resend',
                                        style: TextStyle(fontSize: 12),
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
                            _isEditingProfile ? Icons.check : Icons.edit,
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
                              Colors.blue,
                            ),
                            const SizedBox(width: 12),
                            _buildStatCard(
                              'Views This Month',
                              '0', // Would need to implement view tracking
                              Icons.visibility,
                              Colors.green,
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
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_outlined),
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Get notified about app updates'),
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() => _pushNotifications = value);
                        _savePreference('push_notifications', value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.location_on_outlined),
                      title: const Text('Location Notifications'),
                      subtitle: const Text(
                        'Get notified about nearby services',
                      ),
                      value: _locationNotifications,
                      onChanged: (value) {
                        setState(() => _locationNotifications = value);
                        _savePreference('location_notifications', value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.email_outlined),
                      title: const Text('Email Notifications'),
                      subtitle: const Text('Receive updates via email'),
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() => _emailNotifications = value);
                        _savePreference('email_notifications', value);
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.campaign_outlined),
                      title: const Text('Marketing Emails'),
                      subtitle: const Text('Receive promotional content'),
                      value: _marketingEmails,
                      onChanged: (value) {
                        setState(() => _marketingEmails = value);
                        _savePreference('marketing_emails', value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── App Preferences ──────────────────────
              _buildSectionTitle('App Preferences'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language_outlined),
                      title: const Text('Language'),
                      subtitle: Text(_preferredLanguage),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: const Text('Select Language'),
                            children:
                                ['English', 'Kinyarwanda', 'French', 'Swahili']
                                    .map(
                                      (lang) => SimpleDialogOption(
                                        onPressed: () {
                                          setState(
                                            () => _preferredLanguage = lang,
                                          );
                                          _savePreference(
                                            'preferred_language',
                                            lang,
                                          );
                                          Navigator.pop(context);
                                        },
                                        child: Text(lang),
                                      ),
                                    )
                                    .toList(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.straighten_outlined),
                      title: const Text('Distance Unit'),
                      subtitle: Text(_distanceUnit),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: const Text('Select Distance Unit'),
                            children: ['Kilometers', 'Miles']
                                .map(
                                  (unit) => SimpleDialogOption(
                                    onPressed: () {
                                      setState(() => _distanceUnit = unit);
                                      _savePreference('distance_unit', unit);
                                      Navigator.pop(context);
                                    },
                                    child: Text(unit),
                                  ),
                                )
                                .toList(),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.dark_mode_outlined),
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Use dark theme'),
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() => _darkMode = value);
                        _savePreference('dark_mode', value);
                        // Would need to implement theme switching
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Data & Privacy ──────────────────────
              _buildSectionTitle('Data & Privacy'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download_outlined),
                      title: const Text('Download My Data'),
                      subtitle: const Text('Export all your data'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Implement data export
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Data export feature coming soon'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Clear Cache'),
                      subtitle: const Text('Free up storage space'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        // Clear cache
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cache cleared successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Help & Support ──────────────────────
              _buildSectionTitle('Help & Support'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help_outline),
                      title: const Text('Help Center'),
                      subtitle: const Text('Get help and support'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help center coming soon'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.feedback_outlined),
                      title: const Text('Send Feedback'),
                      subtitle: const Text('Help us improve the app'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Feedback feature coming soon'),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('About'),
                      subtitle: const Text('Version 1.0.0'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'Kigali Directory',
                          applicationVersion: '1.0.0',
                          applicationLegalese: '© 2024 Kigali Directory',
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

              const SizedBox(height: 24),

              // ── Account Actions ──────────────────────
              _buildSectionTitle('Account'),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.security_outlined),
                      title: const Text('Change Password'),
                      subtitle: const Text('Update your password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final authProvider = context
                            .read<app_auth.AuthProvider>();
                        try {
                          await authProvider.resetPassword(user?.email ?? '');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset email sent!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.orange),
                      title: const Text(
                        'Sign Out',
                        style: TextStyle(color: Colors.orange),
                      ),
                      subtitle: const Text('Sign out of your account'),
                      onTap: () async {
                        final shouldSignOut = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Sign Out'),
                            content: const Text(
                              'Are you sure you want to sign out?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
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
                          await context.read<app_auth.AuthProvider>().signOut();
                        }
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_forever,
                        color: Colors.red,
                      ),
                      title: const Text(
                        'Delete Account',
                        style: TextStyle(color: Colors.red),
                      ),
                      subtitle: const Text('Permanently delete your account'),
                      onTap: _showDeleteAccountDialog,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
