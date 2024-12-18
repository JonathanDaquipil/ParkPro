import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vehicle_parking_area_page.dart';
import 'motorcycle_parking_area_page.dart';

class ChooseUnitPage extends StatefulWidget {
  final String loggedInEmail;

  const ChooseUnitPage({super.key, required this.loggedInEmail});

  @override
  _ChooseUnitPageState createState() => _ChooseUnitPageState();
}

class _ChooseUnitPageState extends State<ChooseUnitPage> {
  @override
  void initState() {
    super.initState();
    _monitorUserData();
  }

  // Monitors if the user's data exists in Firestore
  Future<void> _monitorUserData() async {
    try {
      FirebaseFirestore.instance
          .collection('user')
          .where('Email', isEqualTo: widget.loggedInEmail)
          .snapshots()
          .listen((snapshot) async {
        if (snapshot.docs.isEmpty) {
          // If no user data exists, log the user out
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', false);
          await prefs.remove('loggedInEmail');

          if (mounted) {
            Navigator.pushNamedAndRemoveUntil(
                context, '/login', (route) => false);
          }
        }
      });
    } catch (e) {
      // Handle Firestore or network errors
      print('Error monitoring user data: $e');
    }
  }

  // Logs out the user and navigates to the login screen
  Future<void> _logout(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('loggedInEmail');

    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // Builds an option with an image and navigation
  Widget _buildOption({
    required String imagePath,
    required VoidCallback onTap,
    required double width,
    required double height,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Image.asset(
          imagePath,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text(
          'Choose Your Type of Unit',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
          ),
        ),
        backgroundColor: Colors.amberAccent[400],
        automaticallyImplyLeading: false, // Removes the back button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Choose Your Type of Unit',
                style: TextStyle(
                  fontFamily: "Rock Salt",
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40), // Space below the title
              // Vehicle Parking Option
              _buildOption(
                imagePath: 'assets/vehicle.png',
                width: 350,
                height: 180,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VehicleParkingAreaPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20), // Space between options
              // Motorcycle Parking Option
              _buildOption(
                imagePath: 'assets/motorcycle.png',
                width: 250,
                height: 180,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MotorcycleParkingAreaPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
