import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as app_auth;
import 'providers/listing_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/verify_email_screen.dart';

// The FIRST function Flutter calls — like pressing the power button
void main() async {
  // Wake up Flutter's engine before doing anything else
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Connect to Firebase — await means "wait until this is done"
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Start the app only if Firebase initialized successfully
    runApp(const MyApp());
  } catch (e) {
    // If Firebase fails, show error app instead of crashing
    runApp(ErrorApp(error: e.toString()));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider = the "announcer system" for the whole app
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => app_auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => ListingProvider()),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ), // Add theme provider
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Kigali Directory',
            debugShowCheckedModeBanner: false,

            // Use dynamic theme from ThemeProvider
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode
                ? ThemeMode.dark
                : ThemeMode.light,

            home: const AuthGate(),
          );
        },
      ),
    );
  }
}

// AuthGate = the security camera watching who is logged in
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // This stream fires every time login state changes
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Still loading? Show a styled spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 2,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading Kigali Directory...',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        final user = snapshot.data;
        // Not logged in → go to Login
        if (user == null) return const LoginScreen();
        // Logged in but email not verified → go to Verify screen
        if (!user.emailVerified) return const VerifyEmailScreen();
        // Fully verified → go to the main app
        return const MainScreen();
      },
    );
  }
}

// 🚨 ERROR APP - Shows when Firebase fails to initialize
class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'App Failed to Start',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // Show instruction to restart app manually
                    // (Flutter doesn't allow programmatic app restart)
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Close App'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
