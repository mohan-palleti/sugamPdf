import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import '../services/utilities.dart';
// import '../services/auth_service.dart';  // Uncomment when Firebase auth is implemented

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // final AuthService _authService = AuthService();  // Uncomment when Firebase auth is implemented
  String? _phone;
  // String? _verificationId;  // Uncomment when Firebase auth is implemented
  bool _codeSent = false;
  bool _loading = false;

  void _sendOtp() async {
    if (_phone == null) return;
    setState(() => _loading = true);
    try {
      // await _authService.sendOtp(_phone!);
      // The sendOtp method should handle codeSent, but for now, show code input
      setState(() {
        _codeSent = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send OTP')));
    }
  }

  void _verifyOtp(String code) async {
    appLog('Verifying OTP: $code');
    // if (_verificationId == null) return;
    setState(() => _loading = true);
    try {
      // await _authService.verifyOtp(_verificationId!, code);
      //wait for 2 seconds to simulate network delay
      await Future.delayed(const Duration(seconds: 2));
      _onLoginSuccess();
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP')));
      }
    }
  }

  void _onLoginSuccess() {
    Navigator.pushReplacementNamed(context, '/user-info');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf),
            SizedBox(width: 8),
            Text(
              'Sugam PDF',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Skip'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          IconButton(
            icon: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Need help? Contact support!')),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // const SizedBox(height: 50, child: Placeholder(color: Colors.white)),
                    const SizedBox(height: 16),
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_codeSent)
                      IntlPhoneField(
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.onPrimary, width: 2),
                          ),
                        ),
                        initialCountryCode: 'IN',
                        onChanged: (phone) => _phone = phone.completeNumber,
                      ),
                    const SizedBox(height: 16),
                    if (!_codeSent)
                      ElevatedButton(
                        onPressed: _sendOtp,
                        child: const Text('Send OTP'),
                      ),
                    if (_codeSent) ...[
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.onPrimary,
                            width: 2
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: OtpTextField(
                          numberOfFields: 6,
                          borderColor: Theme.of(context).colorScheme.onPrimary,
                          enabled: true,
                          onSubmit: _verifyOtp,
                          borderWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _verifyOtp(''),
                        child: const Text('Verify OTP'),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
