import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'auth_controller.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for 2 seconds, then show auth form
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return _buildSplashScreen();
    }

    return _buildAuthScreen();
  }

  Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo and branding
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.circle, size: 40, color: Colors.white),
              ),

              const SizedBox(height: 24),

              Text(
                'Circle',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1F2937),
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your private space, organized',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF6B7280)),
              ),

              const Spacer(flex: 3),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Consumer<AuthController>(
            builder: (context, authController, child) {
              return Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // Header
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.circle,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      _isSignUp ? 'Create Account' : 'Welcome back',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1F2937),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      _isSignUp
                          ? 'Sign up to get started'
                          : 'Sign in to your account',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF6B7280),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Name field (only for sign up)
                          if (_isSignUp) ...[
                            _buildFieldLabel('Full Name'),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _nameController,
                              decoration: _buildInputDecoration(
                                'Enter your full name',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                          ],

                          // Email field
                          _buildFieldLabel('Email'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _buildInputDecoration(
                              'Enter your email',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Password field
                          _buildFieldLabel('Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: _buildInputDecoration(
                              'Enter your password',
                            ).copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (_isSignUp && value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          if (!_isSignUp) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  // TODO: Implement forgot password
                                },
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    color: Color(0xFF6366F1),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Error message
                          if (authController.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFFECACA),
                                ),
                              ),
                              child: Text(
                                authController.errorMessage!,
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Submit button
                          Container(
                            width: double.infinity,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed:
                                  authController.isLoading
                                      ? null
                                      : _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child:
                                  authController.isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      )
                                      : Text(
                                        _isSignUp ? 'Sign up' : 'Sign in',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Toggle sign up/sign in
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp
                              ? 'Already have an account? '
                              : 'Don\'t have an account? ',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 14,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                              // Clear form fields when switching modes
                              _emailController.clear();
                              _passwordController.clear();
                              _nameController.clear();
                            });
                            // Clear error without triggering rebuild of parent
                            context.read<AuthController>().clearError();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            _isSignUp ? 'Sign in' : 'Sign up',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF374151),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authController = context.read<AuthController>();

    bool success;
    if (_isSignUp) {
      success = await authController.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (success) {
        // Clear form fields after successful sign up
        _emailController.clear();
        _passwordController.clear();
        _nameController.clear();
      }
    } else {
      success = await authController.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (success) {
        // Clear form fields after successful sign in
        _emailController.clear();
        _passwordController.clear();
      }
    }

    if (success) {
      // Navigation is handled by AuthWrapper listening to auth state
      debugPrint('Auth successful, waiting for navigation...');
    } else {
      debugPrint('Auth failed: ${authController.errorMessage}');
    }
  }
}
