import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkpro_enforcers/motorcycle_slots.dart';

class MotorcycleArea extends StatefulWidget {
  const MotorcycleArea({super.key});

  @override
  _MotorcycleAreaState createState() => _MotorcycleAreaState();
}

class _MotorcycleAreaState extends State<MotorcycleArea> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[400],
      appBar: AppBar(
        title: const Text(
          'Motorcycle Parking Areas',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
          ),
        ),
        backgroundColor: Colors.amberAccent[100],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('motorcycle_area')
            .snapshots(),
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
                    Icons.motorcycle,
                    color: Colors.deepOrange,
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
                              builder: (context) => MotorcycleSlot(
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
