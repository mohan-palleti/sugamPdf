import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class UserInfoScreen extends StatefulWidget {
  const UserInfoScreen({super.key});

  @override
  State<UserInfoScreen> createState() => _UserInfoScreenState();
}

class _UserInfoScreenState extends State<UserInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  String? _name, _dob, _gender, _role;
  bool _loading = false;

  void _saveInfo() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _loading = true);
    // final user = FirebaseAuth.instance.currentUser;
    // if (user == null) return;
    // await _authService.saveUserInfo(user.uid, {
    //   'name': _name,
    //   'dob': _dob,
    //   'gender': _gender,
    //   'role': _role,
    //   'phone': user.phoneNumber,
    // });
    setState(() => _loading = false);
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Info')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                        ),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
                      onSaved: (v) => _name = v,
                    ),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)'),
                      validator: (v) => v == null || v.isEmpty ? 'Enter DOB' : null,
                      onSaved: (v) => _dob = v,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (v) => _gender = v,
                      validator: (v) => v == null ? 'Select gender' : null,
                    ),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'User', child: Text('User')),
                        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                      ],
                      onChanged: (v) => _role = v,
                      validator: (v) => v == null ? 'Select role' : null,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _saveInfo,
                      child: const Text('Save & Continue'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
