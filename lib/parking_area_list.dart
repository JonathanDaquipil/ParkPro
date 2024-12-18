import 'package:flutter/material.dart';
import 'package:parkpro_enforcers/motorcycle_area.dart';
import 'package:parkpro_enforcers/vehicle_area.dart';

class ParkingAreaList extends StatelessWidget {
  const ParkingAreaList({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text(
          'Parking Monitoring',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
          ),
        ),
        backgroundColor: Colors.amberAccent[400],
        automaticallyImplyLeading: false, // Removes the back button
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding to the body
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Title
              const Text(
                'Select a Unit to Manage',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 40), // Space below the title

              // Vehicle Image Option
              InkWell(
                onTap: () {
                  // Navigate to Vehicle Parking Area Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VehicleParkingArea(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'assets/vehicle.png', // Your vehicle image
                    width: 350, // Adjust image width
                    height: 180, // Adjust image height
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20), // Space between the images

              // Motorcycle Image Option
              InkWell(
                onTap: () {
                  // Navigate to Motorcycle Parking Area Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MotorcycleArea(),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    'assets/motorcycle.png', // Your motorcycle image
                    width: 250, // Adjust image width
                    height: 180, // Adjust image height
                    fit: BoxFit.cover,
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
