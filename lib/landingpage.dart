import "package:flutter/material.dart";
import 'loginform.dart'; // Import the Choose Unit Page

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image:
                    AssetImage('assets/adminscreenbg.jpeg'), // Background image
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset(
                  'assets/logo2.png', // Replace with your logo
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 10),
                // Title
                Text(
                  'ParkPro',
                  style: TextStyle(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[900],
                    shadows: [
                      Shadow(
                        offset: const Offset(10.0,
                            10.0), // Horizontal and vertical shadow offset
                        blurRadius: 4.0, // Shadow blur radius
                        color: Colors.black.withOpacity(0.5), // Shadow color
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Get Started Button
                ElevatedButton(
                  onPressed: () {
                    // Navigate to Choose Unit Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginForm(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
