import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MotorcycleSlot extends StatefulWidget {
  final String areaName; // Pass the selected area name to this page

  const MotorcycleSlot({super.key, required this.areaName});

  @override
  _MotorcycleSlotState createState() => _MotorcycleSlotState();
}

class _MotorcycleSlotState extends State<MotorcycleSlot> {
  // Reference to the Firestore collection
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    // Dynamically determine the image asset based on the area name
    final String imagePath = 'assets/${widget.areaName.toUpperCase()}.png';

    return Scaffold(
      backgroundColor: Colors.amberAccent[400],
      appBar: AppBar(
        title: Text('${widget.areaName} Slots'),
        backgroundColor: Colors.amberAccent[100],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the image for the selected area
              Container(
                width: double.infinity,
                height: MediaQuery.of(context).size.height *
                    0.3, // 30% of screen height
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Title
              Text(
                'Manage Slot in ${widget.areaName}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              // Real-time Firestore listener using StreamBuilder
              StreamBuilder<DocumentSnapshot>(
                stream: _firestore
                    .collection('motorcycle_area')
                    .doc(widget.areaName)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const Center(
                      child: Text(
                        'No slots available for this area.',
                        style: TextStyle(fontSize: 16),
                      ),
                    );
                  }

                  // Extract slot data from Firestore
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final slotStatus = {
                    for (var key in data.keys) key: data[key] ?? 'Available',
                  };

                  return GridView.builder(
                    shrinkWrap: true, // Allow GridView to fit within the Column
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600
                          ? 4
                          : 3, // Slots per row
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount:
                        slotStatus.length, // Total slots based on database
                    itemBuilder: (context, index) {
                      final slotKey = slotStatus.keys.elementAt(index);
                      final slotValue = slotStatus[slotKey] ?? 'Available';
                      final isOccupied = slotValue == 'Occupied';

                      return Card(
                        elevation: 4,
                        color: isOccupied ? Colors.red[900] : Colors.green[400],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
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
                              const SizedBox(height: 10), // Space between texts
                              DropdownButton<String>(
                                value: slotValue, // Current status of the slot
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Available',
                                    child: Text('Available'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Occupied',
                                    child: Text('Occupied'),
                                  ),
                                ],
                                onChanged: (newValue) {
                                  if (newValue != null) {
                                    _updateSlotStatus(slotKey, newValue);
                                  }
                                },
                                style: TextStyle(
                                  color:
                                      isOccupied ? Colors.white : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                dropdownColor: Colors.black,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update the Firestore database with the new slot status
  Future<void> _updateSlotStatus(String slotKey, String status) async {
    try {
      final areaRef =
          _firestore.collection('motorcycle_area').doc(widget.areaName);

      await areaRef.update({slotKey: status});
    } catch (e) {
      print("Error updating slot status: $e");
    }
  }
}
