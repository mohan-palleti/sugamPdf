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
      //wait for 2 seconds to simulate network delay
      await Future.delayed(const Duration(seconds: 2));
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
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        Icon(Icons.picture_as_pdf, color: Colors.white),
        const SizedBox(width: 8),
        const Text(
          'Sugum PDF',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
          ],
        ),
        centerTitle: true,
        elevation: 4,
        backgroundColor: const Color.fromARGB(255, 58, 164, 183),
        // shape: const RoundedRectangleBorder(
        //   borderRadius: BorderRadius.vertical(
        // bottom: Radius.circular(24),
        //   ),
        // ),
        actions: [
          IconButton(
        icon: const Icon(Icons.help_outline, color: Colors.white),
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
            colors: [const Color.fromARGB(255, 58, 164, 183), const Color.fromARGB(255, 64, 117, 251)],
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
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!_codeSent)
                      IntlPhoneField(
                        decoration: const InputDecoration(
                          labelText: 'Mobile Number',
                          labelStyle: TextStyle(color: Colors.white),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        initialCountryCode: 'IN',
                        onChanged: (phone) => _phone = phone.completeNumber,
                      ),
                    const SizedBox(height: 16),
                    if (!_codeSent)
                      ElevatedButton(
                        onPressed: _sendOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                        ),
                        child: const Text('Send OTP'),
                      ),
                    if (_codeSent) ...[
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: OtpTextField(
                          numberOfFields: 6,
                          borderColor: Colors.white,
                          enabled: true,
                          onSubmit: _verifyOtp,
                          borderWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _verifyOtp(''),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.deepPurple,
                        ),
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
