import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:flutter_otp_text_field/flutter_otp_text_field.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  String? _phone;
  String? _verificationId;
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send OTP')));
    }
  }

  void _verifyOtp(String code) async {
    print('Verifying OTP: $code');
    // if (_verificationId == null) return;
    setState(() => _loading = true);
    try {
      // await _authService.verifyOtp(_verificationId!, code);
      _onLoginSuccess();
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP')));
    }
  }

  void _onLoginSuccess() {
    Navigator.pushReplacementNamed(context, '/user-info');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_codeSent) ...[
                    IntlPhoneField(
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      initialCountryCode: 'IN',
                      onChanged: (phone) => _phone = phone.completeNumber,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _sendOtp,
                      child: const Text('Send OTP'),
                    ),
                  ] else ...[
                    const Text('Enter OTP sent to your phone'),
                    const SizedBox(height: 16),
                    OtpTextField(
                      numberOfFields: 6,
                      borderColor: Colors.deepPurple,
                      onSubmit: _verifyOtp,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
