import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'vehicle_parking_slots_page.dart';

class VehicleParkingAreaPage extends StatelessWidget {
  const VehicleParkingAreaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[400],
      appBar: AppBar(
        title: const Text(
          'Vehicle Parking Areas',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
          ),
        ),
        backgroundColor: Colors.amberAccent[100],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('vehicle_area').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final documents = snapshot.data?.docs ?? [];
          if (documents.isEmpty) {
            return const Center(
              child: Text('No vehicle parking areas found.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              final areaName = document.id;
              final data = document.data() as Map<String, dynamic>;

              final availableSlots =
                  data.values.where((status) => status == 'Available').length;
              final totalSlots = data.length;
              final allOccupied = availableSlots == 0;

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: Icon(
                    totalSlots == 0
                        ? Icons.info
                        : (allOccupied ? Icons.error : Icons.directions_car),
                    color: totalSlots == 0
                        ? Colors.blueGrey
                        : (allOccupied ? Colors.red : Colors.blueAccent),
                    size: 40,
                  ),
                  title: Text(
                    areaName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: totalSlots == 0
                      ? const Text(
                          'No Slots Registered',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      : Text(
                          allOccupied
                              ? 'Full'
                              : 'Available Slots: $availableSlots / $totalSlots',
                          style: TextStyle(
                            color: allOccupied ? Colors.red : Colors.green,
                          ),
                        ),
                  onTap: () {
                    if (totalSlots == 0) {
                      // No slots registered, show a message or do nothing
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('No slots available in $areaName.'),
                        ),
                      );
                    } else {
                      // Navigate to the Vehicle Parking Slots Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ParkingSlotsPage(areaName: areaName),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
