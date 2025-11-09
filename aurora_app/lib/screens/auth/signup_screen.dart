import 'package:flutter/material.dart';
import '../../widgets/auth/custom_text_field.dart';
import '../../widgets/auth/auth_button.dart';
import '../../services/auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _strength = 0; // 0..1
  String _strengthLabel = 'Too weak';

  static final _specialCharReg = RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]');
  static final _upperReg = RegExp(r'[A-Z]');

  void _evaluatePassword(String value) {
    int score = 0;
    if (value.length >= 8) score++;
    if (_upperReg.hasMatch(value)) score++;
    if (_specialCharReg.hasMatch(value)) score++;
    if (value.length >= 12) score++; // bonus length
    _strength = score / 4.0;
    switch (score) {
      case 0:
      case 1:
        _strengthLabel = 'Weak';
        break;
      case 2:
        _strengthLabel = 'Fair';
        break;
      case 3:
        _strengthLabel = 'Good';
        break;
      case 4:
        _strengthLabel = 'Strong';
        break;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService.instance.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created!')),
      );
      Navigator.pop(context); // Back to login
    } catch (e) {
      final msg = AuthService.instance.mapAuthError(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                  
                  // Create account text
                  const Text(
                    'Create\naccount',
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
                    'Start your wellness journey today',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6F6C66),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Name field
                  CustomTextField(
                    controller: _nameController,
                    label: 'Full name',
                    hintText: 'John Doe',
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
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
                    onChanged: _evaluatePassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 8) {
                        return 'Min 8 characters';
                      }
                      if (!_upperReg.hasMatch(value)) {
                        return 'Need at least one uppercase letter';
                      }
                      if (!_specialCharReg.hasMatch(value)) {
                        return 'Need at least one special character';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 12),
                  _PasswordStrengthBar(strength: _strength, label: _strengthLabel),
                  
                  const SizedBox(height: 24),
                  
                  // Confirm password field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm password',
                    hintText: '••••••••',
                    obscureText: _obscureConfirmPassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: const Color(0xFF6F6C66),
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Sign up button
                  AuthButton(
                    text: 'Create account',
                    onPressed: _handleSignUp,
                    isLoading: _isLoading,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: Color(0xFF6F6C66),
                          fontSize: 15,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Sign in',
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

class _PasswordStrengthBar extends StatelessWidget {
  final double strength; // 0..1
  final String label;
  const _PasswordStrengthBar({required this.strength, required this.label});

  Color _color() {
    if (strength < 0.25) return const Color(0xFFF2B8A0); // weak
    if (strength < 0.5) return const Color(0xFFF5C97B); // fair
    if (strength < 0.75) return const Color(0xFFA6C0B5); // good
    return const Color(0xFF8BBF9F); // strong
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 10,
            decoration: BoxDecoration(
              color: const Color(0xFFE8E4DC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: strength.clamp(0, 1),
              child: Container(color: _color()),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Strength: $label',
          style: const TextStyle(fontSize: 12, color: Color(0xFF6F6C66)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Password must be ≥8 chars, include 1 uppercase & 1 special character.',
          style: TextStyle(fontSize: 11, color: Color(0xFF6F6C66)),
        )
      ],
    );
  }
}