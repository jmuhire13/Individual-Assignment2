import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _login() async {
    // Clear any previous errors
    context.read<AuthProvider>().clearError();

    // Validate form inputs
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Hide keyboard
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text.trim());

    // AuthGate in main.dart will auto-navigate on success
    // Error message will be shown in UI if login fails
  }

  // Password reset functionality (Assignment: Essential auth feature)
  Future<void> _showPasswordResetDialog() async {
    final resetEmailCtrl = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Container(
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
            controller: resetEmailCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Enter your email',
              labelStyle: TextStyle(color: Colors.grey.shade400),
              hintText: 'example@email.com',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(25),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) => TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      if (resetEmailCtrl.text.trim().isNotEmpty) {
                        final success = await auth.resetPassword(
                          resetEmailCtrl.text.trim(),
                        );
                        if (mounted) {
                          Navigator.of(context).pop();
                          if (success) {
                            _showSnackBar(
                              'Password reset email sent! Check your inbox.',
                            );
                          }
                        }
                      }
                    },
              child: auth.isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Reset Email'),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      resizeToAvoidBottomInset: true, // Ensure keyboard responsiveness
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 80),

                    // ── APP LOGO/TITLE ─────────────────────────
                    const Icon(
                      Icons.location_city,
                      size: 80,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kigali Directory',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Find essential services & places in Kigali',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // ── EMAIL INPUT ────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _emailCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: Colors.grey,
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(
                            r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                          ).hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── PASSWORD INPUT ─────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _passCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelStyle: TextStyle(color: Colors.grey.shade400),
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: Colors.grey,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey.shade400,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.transparent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: const BorderSide(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _login(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── FORGOT PASSWORD LINK ──────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showPasswordResetDialog,
                        child: Text(
                          'Forgot Password?',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ── ERROR MESSAGE ──────────────────────────
                    if (auth.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: Colors.red.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                auth.errorMessage!,
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.close,
                                color: Colors.red.shade700,
                                size: 18,
                              ),
                              onPressed: auth.clearError,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                    // ── LOGIN BUTTON ───────────────────────────
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: auth.isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 2,
                          shadowColor: Colors.black.withOpacity(0.3),
                        ),
                        child: auth.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── SIGNUP NAVIGATION ──────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose(); // always clean up controllers
    _passCtrl.dispose();
    super.dispose();
  }
}
