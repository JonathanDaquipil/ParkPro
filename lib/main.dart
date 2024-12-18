import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:parkpro_user/choose_unit_page.dart';
import 'package:parkpro_user/firebase_options.dart';
import 'package:parkpro_user/loading_screen.dart';
import 'package:parkpro_user/loginform.dart';
import 'package:parkpro_user/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.android);

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String? loggedInEmail =
      prefs.getString('loggedInEmail'); // Get the email of the logged-in user

  runApp(MyApp(isLoggedIn: isLoggedIn, loggedInEmail: loggedInEmail));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? loggedInEmail;

  const MyApp({super.key, required this.isLoggedIn, this.loggedInEmail});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkPro',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: LoadingScreen(
        message: 'Initializing ParkPro...',
        logoPath: 'assets/logo1.png',
        nextScreen: isLoggedIn && loggedInEmail != null
            ? ChooseUnitPage(loggedInEmail: loggedInEmail!)
            : const LoginForm(),
      ),
      routes: {
        '/login': (context) => const LoginForm(),
        '/signup': (context) => const SignUpPage(),
        '/chooseUnit': (context) =>
            const ChooseUnitPage(loggedInEmail: ''), // Default or fallback
        '/loadingscreen': (context) => const LoadingScreen(
              message: 'Please wait...',
              logoPath: 'assets/logo1.png',
              nextScreen: LoginForm(),
            ),
      },
    );
  }
}
