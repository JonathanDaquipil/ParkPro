import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkpro_user/otp/otp_sender.dart';
import 'package:parkpro_user/otp/otp_utils.dart';
import 'package:parkpro_user/otp/otp_verification_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _passwordError;
  String? _emailError;

  // Function to check if email already exists
  Future<bool> _emailExists(String email) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('user')
        .where('Email', isEqualTo: email)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Function to initiate OTP verification
  Future<void> _initiateOTPVerification() async {
    if (_formKey.currentState!.validate() &&
        _passwordError == null &&
        _emailError == null) {
      try {
        final email = _emailController.text.trim();

        // Check if the email is already registered
        bool emailTaken = await _emailExists(email);
        if (emailTaken) {
          setState(() {
            _emailError = 'The Email is Already in Use';
          });
          return; // Exit if email is already in use
        }

        final otp = generateOTP(); // Generate a 6-digit OTP

        // Send OTP to the user's email
        await sendEmail(
          email: email,
          otpCode: otp,
          userName: _firstNameController.text.trim(),
        );

        // Temporarily hold user data
        final userData = {
          'First_Name': _firstNameController.text.trim(),
          'Last_Name': _lastNameController.text.trim(),
          'Email': email,
          'Password': _passwordController.text.trim(),
        };

        // Navigate to OTP Verification Page with email, OTP, and user data
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPVerificationPage(
              email: email,
              generatedOTP: otp,
              userData: userData,
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields correctly!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.amberAccent[400],
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Create Your Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),

                // First Name Field
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Fill this field';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    setState(() {}); // Trigger revalidation
                  },
                ),
                const SizedBox(height: 16),

                // Last Name Field
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Fill this field';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    setState(() {}); // Trigger revalidation
                  },
                ),
                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorText: _emailError, // Show email error message
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Fill this field';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    setState(() {
                      _emailError = null; // Clear error on change
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Fill this field';
                    }
                    return null;
                  },
                  onChanged: (_) {
                    setState(() {
                      _passwordError = null; // Clear password mismatch error
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    errorText:
                        _passwordError, // Display error for password mismatch
                  ),
                  onChanged: (value) {
                    setState(() {
                      // Update the error if passwords do not match
                      _passwordError = _passwordController.text == value
                          ? null
                          : 'Passwords do not match!';
                    });
                  },
                ),
                const SizedBox(height: 30),

                // Sign Up Button with Gradient
                GestureDetector(
                  onTap: () {
                    if (_formKey.currentState!.validate() &&
                        _passwordError == null &&
                        _emailError == null) {
                      _initiateOTPVerification(); // Initiate OTP Verification
                    } else {
                      _formKey.currentState!.validate();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Colors.amberAccent, Colors.amberAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.black54)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('OR'),
                    ),
                    Expanded(child: Divider(color: Colors.black54)),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
