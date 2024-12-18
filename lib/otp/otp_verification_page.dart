import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkpro_user/otp/otp_sender.dart';
import 'package:parkpro_user/otp/otp_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkpro_user/loginform.dart';

class OTPVerificationPage extends StatefulWidget {
  final String email; // The email used for OTP
  final String generatedOTP; // The generated OTP
  final Map<String, dynamic> userData; // Holds user data for Firestore

  const OTPVerificationPage({
    super.key,
    required this.email,
    required this.generatedOTP,
    required this.userData,
  });

  @override
  _OTPVerificationPageState createState() => _OTPVerificationPageState();
}

class _OTPVerificationPageState extends State<OTPVerificationPage> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  String _currentOTP = ""; // Holds the current OTP
  bool _isResendDisabled = false; // Tracks if the Resend button is disabled
  int _resendCooldown = 0; // Tracks the cooldown timer in seconds
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _currentOTP = widget.generatedOTP; // Set the initial OTP
  }

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    _resendTimer?.cancel(); // Clean up the timer
    super.dispose();
  }

  // Function to handle OTP verification
  Future<void> _verifyOTP() async {
    String enteredOTP =
        _otpControllers.map((controller) => controller.text).join();

    if (enteredOTP.length == 6 && enteredOTP == _currentOTP) {
      // OTP verified successfully
      try {
        // Save user data to Firestore with "IsVerified" status
        await FirebaseFirestore.instance.collection('user').add({
          ...widget.userData, // Include all user data
          'IsVerified': true, // Mark the user as verified
        });

        // Update SharedPreferences to reflect user logout state
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP verified and account created!')),
        );

        // Redirect to the login form and refresh the app
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginForm(),
          ),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving data: $e')),
        );
      }
    } else {
      // Display error if OTP is invalid
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please enter 6 digits.')),
      );
    }
  }

  // Function to resend OTP
  Future<void> _resendOTP() async {
    if (_isResendDisabled) return;

    setState(() {
      _isResendDisabled = true; // Disable the Resend button
      _resendCooldown = 60; // Set a 2-minute cooldown
    });

    // Start the cooldown timer
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _resendCooldown -= 1;
        if (_resendCooldown <= 0) {
          _isResendDisabled = false; // Re-enable the Resend button
          timer.cancel(); // Stop the timer
        }
      });
    });

    try {
      final newOTP = generateOTP(); // Generate a new OTP
      await sendEmail(
        email: widget.email,
        otpCode: newOTP,
        userName: widget.userData['name'] ??
            "User", // Use actual user name if available
      );
      setState(() {
        _currentOTP = newOTP; // Update the OTP
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP has been resent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend OTP: $e')),
      );
    }
  }

  // Widget for OTP boxes
  Widget _buildOTPBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 40,
          child: TextField(
            controller: _otpControllers[index],
            keyboardType: TextInputType.number,
            maxLength: 1,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20),
            decoration: InputDecoration(
              counterText: '', // Hide the character counter
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(
                    color: Color.fromARGB(255, 246, 203, 49), width: 2.0),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus(); // Move to next box
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus(); // Move to previous box
              }
            },
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text('Verify OTP'),
        backgroundColor: Colors.amberAccent[400],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              const Text(
                'Enter the OTP',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'We have sent a 6-digit OTP to your email. Please enter it below to verify your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 30),

              // OTP Input Boxes
              _buildOTPBoxes(),
              const SizedBox(height: 30),

              // Verify Button
              ElevatedButton(
                onPressed: _verifyOTP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amberAccent[400],
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Verify OTP',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Resend OTP
              TextButton(
                onPressed: _isResendDisabled ? null : _resendOTP,
                child: Text(
                  _isResendDisabled
                      ? 'Resend OTP in ${_resendCooldown}s'
                      : 'Resend OTP',
                  style: TextStyle(
                    fontSize: 16,
                    color: _isResendDisabled ? Colors.grey : Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
