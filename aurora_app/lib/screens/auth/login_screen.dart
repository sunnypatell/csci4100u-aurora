import 'package:flutter/material.dart';
/// LoginScreen
/// Email/password authentication form with password reset flow and variants
/// for user feedback via Aurora snackbars. Validation occurs locally before
/// dispatching Firebase Auth operations. Designed to keep state minimal: only
/// loading, obscured password toggle, and reset in-progress flag.
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/auth_button.dart';
import '../../services/auth_service.dart';
import '../../widgets/aurora_snackbar.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _resetting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validates form then attempts sign-in, surfacing success or error via
  /// snackbar. On success the global AuthGate will rebuild to dashboard.
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      showAuroraSnackBar(context, 'Signed in successfully', variant: AuroraSnackVariant.success);
      // AuthGate will rebuild to Dashboard automatically; just pop back to root.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      final msg = AuthService.instance.mapAuthError(e);
      if (mounted) {
        showAuroraSnackBar(context, msg, variant: AuroraSnackVariant.error);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Sends password reset email after a lightweight syntactic email check.
  /// Provides info/error/success feedback using snackbar variants.
  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      showAuroraSnackBar(context, 'Enter a valid email to reset password', variant: AuroraSnackVariant.info);
      return;
    }
    setState(() => _resetting = true);
    try {
      await AuthService.instance.sendPasswordResetEmail(email);
      if (mounted) {
        showAuroraSnackBar(context, 'Password reset email sent to $email', variant: AuroraSnackVariant.success);
      }
    } catch (e) {
      final msg = AuthService.instance.mapAuthError(e);
      if (mounted) {
        showAuroraSnackBar(context, msg, variant: AuroraSnackVariant.error);
      }
    } finally {
      if (mounted) setState(() => _resetting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFE7),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),
                  
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios),
                    color: const Color(0xFF2F2E2C),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Welcome back text
                  const Text(
                    'Welcome\nback',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF2F2E2C),
                      height: 1.2,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  const Text(
                    'Sign in to continue your journey',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6F6C66),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 56),
                  
                  // Email field
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'your.email@example.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Password field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: '••••••••',
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF6F6C66),
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Forgot password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetting ? null : _handleResetPassword,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          color: Color(0xFF6F6C66),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login button
                  AuthButton(
                    text: 'Sign in',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                  ),

                  
                  const SizedBox(height: 32),
                  
                  // Sign up prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'New to Aurora? ',
                        style: TextStyle(
                          color: Color(0xFF6F6C66),
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Create account',
                          style: TextStyle(
                            color: Color(0xFFF5C97B),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}