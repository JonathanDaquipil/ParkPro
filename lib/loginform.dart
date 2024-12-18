import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkpro_user/loading_screen.dart';
import 'package:parkpro_user/choose_unit_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isTermsAccepted = false;

  // Method to validate login credentials
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!_isTermsAccepted) {
      setState(() {
        _errorMessage = 'Please accept the Terms and Conditions to proceed.';
      });
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('user')
          .where('Email', isEqualTo: email)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No user found with this email.';
        });
      } else {
        final user = snapshot.docs.first;
        final storedPassword = user['Password'];

        if (storedPassword == password) {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('loggedInEmail', email);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LoadingScreen(
                message: 'Logging in...',
                logoPath: 'assets/logo1.png',
                nextScreen: ChooseUnitPage(loggedInEmail: email),
              ),
            ),
          );
        } else {
          setState(() {
            _errorMessage = 'Incorrect password.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error logging in: $e';
      });
    }
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Terms and Conditions'),
          content: SingleChildScrollView(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black),
                children: [
                  TextSpan(
                    text:
                        'Welcome to ParkPro! By using our application, you agree to comply with and be bound by the following terms and conditions. Please read them carefully before accessing or using our services.\n\n',
                  ),
                  TextSpan(
                    text: '1. General Use\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        'ParkPro is designed to assist users in locating and managing parking spaces within supported areas.\n\n',
                  ),
                  TextSpan(
                    text: '2. Account Registration\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        '• Certain features of ParkPro may require account registration.\n\n',
                  ),
                  TextSpan(
                    text: '3. No Fees or Reservations\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        '• ParkPro is a free service and does not charge users for accessing or using its features.\n\n',
                  ),
                  TextSpan(
                    text:
                        '• The app does not facilitate parking reservations but provides real-time information on available parking spaces to help users make informed decisions.\n\n',
                  ),
                  TextSpan(
                    text: '4. Parking Space Usage\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                      text:
                          '• Parking spaces shown in the app are managed by third-party providers or public facilities. Availability is subject to change and is not guaranteed by ParkPro.\n\n'),
                  TextSpan(
                      text:
                          '• Users are expected to park responsibly and comply with all rules set by the respective parking facilities.\n\n'),
                  TextSpan(
                    text: '5. User Responsibilities\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                      text:
                          '• Users must ensure their vehicles meet the requirements of the parking facilities they choose, including size, weight, and safety regulations.\n\n'),
                  TextSpan(
                      text:
                          '•ParkPro is not liable for any damage, loss, or disputes arising from the use of parking spaces.\n\n'),
                  TextSpan(
                    text: '6. Prohibited Activities\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                      text:
                          '• Misuse of the app, including providing false information or using the app for unlawful activities, is strictly prohibited.\n\n'),
                  TextSpan(
                      text:
                          '• Attempts to manipulate, hack, or reverse-engineer the app are forbidden.\n\n'),
                  TextSpan(
                    text: '7. Liability and Disclaimer\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                      text:
                          '• ParkPro is a tool for providing parking information and is not involved in the management or operation of parking spaces.\n\n'),
                  TextSpan(
                      text:
                          '• Users acknowledge that ParkPro is not responsible for the accuracy of parking availability data, disputes with parking providers, or any related issues.\n\n'),
                  TextSpan(
                    text: '8. Privacy\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                      text:
                          '• User data is handled according to our Privacy Policy. By using ParkPro, you consent to the collection and use of your information as outlined in the policy.\n\n'),
                  TextSpan(
                    text: '9. Modifications to Terms\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                      text:
                          '• ParkPro reserves the right to modify these terms and conditions at any time. Changes will be communicated through the app or email, and continued use of the app indicates acceptance of the updated terms.\n\n'),
                  TextSpan(
                    text: '10. Contact Information\n',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                      text:
                          '• For questions or concerns about these terms, please contact us at support@parkpro.com.\n\n'),
                  TextSpan(
                      text:
                          'By using ParkPro, you acknowledge that you have read, understood, and agree to these terms and conditions. If you do not agree, please discontinue use of the app immediately.\n\n'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: Colors.amberAccent[400],
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Login Logo
              Image.asset(
                'assets/loginlogo.png',
                height: 150,
              ),
              const SizedBox(height: 20),

              const Text(
                'Welcome Back!',
                style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Terms and Conditions Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _isTermsAccepted,
                    onChanged: (value) {
                      setState(() {
                        _isTermsAccepted = value ?? false;
                      });
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _showTermsAndConditions,
                      child: const Text(
                        'I agree to the Terms and Conditions',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Error Message
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),

              // Login Button
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isTermsAccepted ? Colors.amberAccent : Colors.grey,
                  padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Sign-Up Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(fontSize: 14),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/signup');
                    },
                    child: const Text(
                      'Sign Up',
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
    );
  }
}
