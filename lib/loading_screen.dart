import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  final String message;
  final String logoPath;
  final Widget nextScreen;

  const LoadingScreen({
    super.key,
    required this.message, // Dynamic loading message
    required this.logoPath, // Path for the logo
    required this.nextScreen, // Screen to navigate to after loading
  });

  @override
  Widget build(BuildContext context) {
    // Navigate to the next screen after a 5-second delay
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
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
              logoPath,
              width: MediaQuery.of(context).size.width * 0.5,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
