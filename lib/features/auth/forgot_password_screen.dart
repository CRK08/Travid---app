import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import 'otp_verification_screen.dart';
import 'reset_password_screen.dart';

/// Forgot Password Screen
/// Allows user to reset password via email or phone OTP
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inputController = TextEditingController();
  bool _isLoading = false;
  String _verificationType = 'email'; // 'email' or 'phone'


  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final input = _inputController.text.trim();

      if (_verificationType == 'email') {
        // Send password reset email
        await authService.resetPassword(input);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset link sent to your email'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // Send phone OTP
        await authService.sendPhoneOTP(
          phoneNumber: input,
          onCodeSent: (verificationId) {
            setState(() {
              _isLoading = false;
            });
            
            // Navigate to OTP verification
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OTPVerificationScreen(
                  verificationType: 'phone',
                  destination: input,
                  verificationId: verificationId,
                  onVerify: (otp) => _handleVerifyOTP(otp, verificationId),
                  onResend: () => _handleSendOTP(),
                ),
              ),
            );
          },
          onError: (error) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(error), backgroundColor: Colors.red),
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleVerifyOTP(String otp, String verificationId) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.verifyPhoneOTP(
        verificationId: verificationId,
        otp: otp,
      );

      if (mounted) {
        // Navigate to reset password screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ResetPasswordScreen(),
          ),
        );
      }
    } catch (e) {
      throw e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Forgot Password', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.primaryColor,
              theme.colorScheme.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Title
                    Text(
                      'Reset Password',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Description
                    Text(
                      'Enter your email or phone number to receive a verification code',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Verification Type Selector
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: SegmentedButton<String>(
                          style: ButtonStyle(
                             side: WidgetStateProperty.all(BorderSide.none),
                             backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return theme.primaryColor.withValues(alpha: 0.1);
                                }
                                return Colors.transparent;
                             }),
                          ),
                          segments: const [
                            ButtonSegment(
                              value: 'email',
                              label: Text('Email'),
                              icon: Icon(Icons.email_outlined),
                            ),
                            ButtonSegment(
                              value: 'phone',
                              label: Text('Phone'),
                              icon: Icon(Icons.phone_android),
                            ),
                          ],
                          selected: {_verificationType},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _verificationType = newSelection.first;
                              _inputController.clear();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Input Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            // Email/Phone Input
                            TextFormField(
                              controller: _inputController,
                              keyboardType: _verificationType == 'email'
                                  ? TextInputType.emailAddress
                                  : TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: _verificationType == 'email' ? 'Email' : 'Phone Number',
                                hintText: _verificationType == 'email'
                                    ? 'your.email@example.com'
                                    : '+91 9876543210',
                                prefixIcon: Icon(
                                  _verificationType == 'email'
                                      ? Icons.email_outlined
                                      : Icons.phone_android,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your $_verificationType';
                                }
                                if (_verificationType == 'email' && !value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                if (_verificationType == 'phone' && value.length < 10) {
                                  return 'Please enter a valid phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Send OTP Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSendOTP,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: theme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(_verificationType == 'email' ? 'Send Reset Link' : 'Send OTP'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),

                    // Back to Login
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Back to Login', style: TextStyle(color: Colors.white)),
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
