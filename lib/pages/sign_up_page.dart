import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:odp/pages/login.dart'; // Import your login page
import 'package:shared_preferences/shared_preferences.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _nameController    = TextEditingController();
  final TextEditingController _emailController   = TextEditingController();
  final TextEditingController _passwordController= TextEditingController();
  final TextEditingController _mobileController  = TextEditingController();

  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  bool _loading = false;
  String _userType = 'User';
  String? _errorMessage; // <-- Add this line

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _saveCredentials(String email, String password) async {
    final prefs = await _prefs;
    await prefs.setString('savedEmail', email);
    await prefs.setString('savedPassword', password);
  }

  Future<void> _signup() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Save user data in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'mobile': _mobileController.text.trim(),
        'userType': _userType,
      });

      Fluttertoast.showToast(
        msg: 'Verification email sent. Please check your inbox.',
      );

      // Ask to save credentials
      if (!mounted) return;
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.save_outlined, color: Colors.teal.shade800),
              SizedBox(width: 8),
              Text('Save Login Details?'),
            ],
          ),
          content: Text(
            'Would you like to save your email and password for faster login next time?',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Not Now',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ) ?? false;

      if (shouldSave) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('savedEmail', _emailController.text.trim());
        await prefs.setString('savedPassword', _passwordController.text.trim());
        Fluttertoast.showToast(
          msg: 'Login details saved successfully',
          backgroundColor: Colors.teal.shade800,
        );
      }

      _nameController.clear();
      _emailController.clear();
      _passwordController.clear();
      _mobileController.clear();

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showErrorDialog('This email is already registered.');
      } else if (e.code == 'invalid-email') {
        _showErrorDialog('Invalid email format.');
      } else if (e.code == 'weak-password') {
        _showErrorDialog('Password is too weak.');
      } else {
        _showErrorDialog('Signup Failed: ${e.message}');
      }
    } catch (e) {
      _showErrorDialog('Signup Failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Registration Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.teal.shade800)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required IconData iconData,
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: Colors.teal.shade900),
        cursorColor: Colors.teal.shade900,
        decoration: InputDecoration(
          prefixIcon: Icon(iconData, color: Colors.teal.shade800),
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.teal.shade400),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildUserTypeSelector() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.teal.shade800),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _userType = 'User'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _userType == 'User'
                      ? Colors.teal.shade100
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'User',
                  style: TextStyle(
                    color: Colors.teal.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _userType = 'Turf Owner'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _userType == 'Turf Owner'
                      ? Colors.teal.shade100
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Turf Owner',
                  style: TextStyle(
                    color: Colors.teal.shade900,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Image.asset(
          'lib/assets/logo.png', // Ensure logo.png is added to assets folder and mentioned in pubspec.yaml
          height: 40, // Adjust height as needed
          fit: BoxFit.contain,
        ),
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Register new account',
              style: TextStyle(
                color: Colors.teal.shade800,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            if (_errorMessage != null) // <-- Show error message if present
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            _buildUserTypeSelector(),
            const SizedBox(height: 20),

            _buildTextField(
              iconData: Icons.person_outline,
              hintText: 'Name',
              controller: _nameController,
            ),
            const SizedBox(height: 20),

            _buildTextField(
              iconData: Icons.email_outlined,
              hintText: 'Email',
              controller: _emailController,
            ),
            const SizedBox(height: 20),

            _buildTextField(
              iconData: Icons.lock_outline,
              hintText: 'Password',
              controller: _passwordController,
              isPassword: true,
            ),
            const SizedBox(height: 20),

            _buildTextField(
              iconData: Icons.phone_outlined,
              hintText: 'Mobile Number',
              controller: _mobileController,
            ),
            const SizedBox(height: 30),

            ElevatedButton(
              onPressed: _loading ? null : _signup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade600,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white),
              )
                  : const Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => LoginApp()),
                );
              },
              child: Text(
                'Already have an account? Login',
                style: TextStyle(
                  color: Colors.teal.shade600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
