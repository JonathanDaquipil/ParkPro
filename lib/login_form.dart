import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parkpro_enforcers/enforcer_homescreen.dart';
import 'package:geolocator/geolocator.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  // Check if location services are enabled and permissions are granted
  Future<void> _checkLocationPermission() async {
    setState(() => _isLoading = true);

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage =
              'Location services are disabled. Please enable location services to use this app.';
          _isLoading = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permission is required to use this app.';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permissions are permanently denied. Please enable them in your device settings.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _errorMessage = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking location permission: $e';
        _isLoading = false;
      });
    }
  }

  // Method to validate login credentials
  Future<void> _login() async {
    // First check location permission again
    await _checkLocationPermission();
    if (_errorMessage != null) return; // If there's an error, don't proceed

    setState(() => _isLoading = true);

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both username and password.';
        _isLoading = false;
      });
      return;
    }

    try {
      // Try to get current location to ensure it's working
      try {
        await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
      } catch (e) {
        setState(() {
          _errorMessage =
              'Unable to get location. Please ensure location services are enabled.';
          _isLoading = false;
        });
        return;
      }

      // Retrieve enforcer data from Firestore
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('enforcer_account')
          .where('enforcer_id', isEqualTo: username)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _errorMessage = 'No enforcer found with this ID.';
          _isLoading = false;
        });
      } else {
        final enforcer = snapshot.docs.first;
        final storedPassword = enforcer['password'];

        // Check if the password matches
        if (storedPassword == password) {
          final fullName = '${enforcer['first_name']} ${enforcer['last_name']}';

          try {
            // Update enforcer status to Online
            await FirebaseFirestore.instance
                .collection('enforcer_account')
                .doc(enforcer.id)
                .update({
              'status': 'Online',
              'last_active': FieldValue.serverTimestamp(),
            });

            // Save login data to SharedPreferences
            final SharedPreferences prefs =
                await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', true);
            await prefs.setString('enforcerName', fullName);
            await prefs.setString('enforcerId', username);

            debugPrint('Login successful for enforcer: $username');
            debugPrint('Status updated to Online');

            if (!mounted) return;

            // Navigate to Enforcer Dashboard
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EnforcerDashboard(
                  enforcerName: fullName,
                  enforcerId: username,
                  firstName: enforcer['first_name'],
                  lastName: enforcer['last_name'],
                ),
              ),
            );
          } catch (e) {
            setState(() {
              _errorMessage = 'Error updating enforcer status: $e';
              _isLoading = false;
            });
          }
        } else {
          setState(() {
            _errorMessage = 'Incorrect password.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error logging in: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text('Enforcer Login'),
        backgroundColor: Colors.amberAccent[400],
        automaticallyImplyLeading: false,
        actions: [
          // Add a refresh button for location permission
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkLocationPermission,
            tooltip: 'Check Location Permission',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Login Logo
                    Image.asset(
                      'assets/logo1.png',
                      height: 150,
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Welcome Enforcer!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location Status
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Username Field
                    TextField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        labelText: 'Username',
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

                    // Login Button
                    ElevatedButton(
                      onPressed: _errorMessage == null ? _login : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amberAccent,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 50),
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

                    // Redirect Text
                    const Text(
                      "Don't have an account? Contact the Administrator.",
                      style: TextStyle(color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
