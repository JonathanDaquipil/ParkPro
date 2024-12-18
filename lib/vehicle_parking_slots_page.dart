import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParkingSlotsPage extends StatelessWidget {
  final String areaName; // Pass the selected area name to this page

  const ParkingSlotsPage({super.key, required this.areaName});

  @override
  Widget build(BuildContext context) {
    final String imagePath = 'assets/${areaName.toUpperCase()}.png';

    return Scaffold(
      backgroundColor: Colors.amberAccent[400],
      appBar: AppBar(
        title: Text('$areaName Slots'),
        backgroundColor: Colors.amberAccent[100],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('vehicle_area')
            .doc(areaName)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;

          if (data == null || data.isEmpty) {
            return const Center(
              child: Text('No slots registered for this area.'),
            );
          }

          // Extract slot keys dynamically and sort for consistency
          final slotKeys = data.keys.toList()..sort((a, b) => a.compareTo(b));

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display the image for the selected area
                  Container(
                    width: double.infinity,
                    height: MediaQuery.of(context).size.height * 0.3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Display the area name
                  Text(
                    areaName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // GridView for parking slots
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          MediaQuery.of(context).size.width > 600 ? 4 : 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: slotKeys.length,
                    itemBuilder: (context, index) {
                      final slotKey = slotKeys[index];
                      final isOccupied = data[slotKey] == 'Occupied';

                      return Card(
                        elevation: 4,
                        color: isOccupied ? Colors.red[900] : Colors.green[600],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              slotKey,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              isOccupied ? 'Occupied' : 'Available',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color:
                                    isOccupied ? Colors.white70 : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
