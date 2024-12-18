import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:parkpro_admin/firebase_options.dart';
import 'package:parkpro_admin/admin_login.dart';
import 'package:parkpro_admin/admin_home.dart'; // Import Admin Dashboard
import 'package:parkpro_admin/enforcer_list.dart'; // Import Enforcer List
import 'package:parkpro_admin/add_enforcer.dart'; // Import Add Enforcer Page

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.web);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ParkPro Admin',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      initialRoute: '/login', // Define the initial route
      routes: {
        '/login': (context) => const AdminLoginPage(), // Login Page
        '/dashboard': (context) => const AdminHomePage(), // Admin Dashboard
        '/enforcers': (context) => const EnforcerListPage(), // Enforcer List
        '/add_enforcer': (context) =>
            const AddEnforcerPage(), // Add Enforcer Page
      },
    );
  }
}
