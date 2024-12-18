import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'enforcer_homescreen.dart';
import 'firebase_options.dart';
import 'login_form.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkPro',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home:
          const InitialLoadingScreen(), // Start with the initial loading screen
    );
  }
}

// Initial Loading Screen to check login state
class InitialLoadingScreen extends StatelessWidget {
  const InitialLoadingScreen({super.key});

  Future<void> _checkLoginState(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final String enforcerName = prefs.getString('enforcerName') ?? 'Unknown';
      final String enforcerId = prefs.getString('enforcerId') ?? 'Unknown';

      // Navigate to the dashboard with persisted data
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoadingScreen(
            nextScreen: EnforcerDashboard(
              enforcerName: enforcerName,
              enforcerId: enforcerId,
              firstName: '',
              lastName: '',
            ),
          ),
        ),
      );
    } else {
      // Navigate to login page if not logged in
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LoginForm(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _checkLoginState(context); // Check if the user is already logged in
    return const Scaffold(
      backgroundColor: Colors.amberAccent,
      body: Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      ),
    );
  }
}

// General Loading Screen Widget
class LoadingScreen extends StatelessWidget {
  final Widget nextScreen;

  const LoadingScreen({super.key, required this.nextScreen});

  @override
  Widget build(BuildContext context) {
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    });

    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/logo1.png',
              height: MediaQuery.of(context).size.height * 0.2,
              width: MediaQuery.of(context).size.width * 0.5,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              'ParkPro',
              style: TextStyle(
                color: Colors.black,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
