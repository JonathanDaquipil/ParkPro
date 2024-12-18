import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkpro_enforcers/vehicle_slots.dart';

class VehicleParkingArea extends StatefulWidget {
  const VehicleParkingArea({super.key});

  @override
  _VehicleParkingAreaState createState() => _VehicleParkingAreaState();
}

class _VehicleParkingAreaState extends State<VehicleParkingArea> {
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
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final documents = snapshot.data?.docs;

          if (documents == null || documents.isEmpty) {
            return const Center(
              child: Text('No parking areas available.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              final areaName = document.id; // Document name
              final data = document.data() as Map<String, dynamic>?;

              // Count available slots
              int availableSlots = 0;
              if (data != null) {
                availableSlots =
                    data.values.where((status) => status == 'Available').length;
              }

              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                child: ListTile(
                  leading: const Icon(
                    Icons.directions_car,
                    color: Colors.blueAccent,
                    size: 40,
                  ),
                  title: Text(
                    areaName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    data == null || data.isEmpty
                        ? 'No Slot Registered'
                        : availableSlots > 0
                            ? '$availableSlots Slot${availableSlots > 1 ? 's' : ''} Available'
                            : 'Full',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          (data == null || data.isEmpty || availableSlots == 0)
                              ? Colors.red
                              : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  onTap: data == null || data.isEmpty
                      ? null
                      : () {
                          // Navigate to Parking Slots Page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VehicleSlot(
                                areaName: areaName,
                              ),
                            ),
                          ).then((_) {
                            // Refresh the UI after returning from the Slots page
                            setState(() {});
                          });
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
