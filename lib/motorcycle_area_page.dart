import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MotorcycleAreaPage extends StatefulWidget {
  const MotorcycleAreaPage({Key? key}) : super(key: key);

  @override
  State<MotorcycleAreaPage> createState() => _MotorcycleAreaPageState();
}

class _MotorcycleAreaPageState extends State<MotorcycleAreaPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String searchQuery = "";

  /// Adds a new motorcycle area
  Future<void> addMotorcycleArea(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String newArea = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Motorcycle Area'),
        content: Form(
          key: formKey,
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: 'Area Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) => value == null || value.isEmpty
                ? 'Please enter an area name'
                : null,
            onSaved: (value) => newArea = value?.trim() ?? '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                formKey.currentState!.save();

                final existingArea = await _firestore
                    .collection('motorcycle_area')
                    .doc(newArea)
                    .get();

                if (existingArea.exists) {
                  // If the area already exists, show an error message
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Area already exists!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Auto-increment numbering for the area name
                final count = await _firestore
                    .collection('motorcycle_area')
                    .get()
                    .then((value) => value.docs.length);

                String numberedArea = "$newArea ${count + 1}";

                await _firestore
                    .collection('motorcycle_area')
                    .doc(numberedArea)
                    .set({});

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Motorcycle area added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Adds a new slot to a specific area
  Future<void> addSlot(String areaId) async {
    final document =
        await _firestore.collection('motorcycle_area').doc(areaId).get();
    final data = document.data() ?? {};

    // Find the next available slot number
    int nextSlot = 1;
    while (data.containsKey('Slot $nextSlot')) {
      nextSlot++;
    }

    // Add the new slot
    await _firestore.collection('motorcycle_area').doc(areaId).update({
      'Slot $nextSlot': 'Available',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Slot $nextSlot added to $areaId!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Deletes the last slot from a specific area
  Future<void> deleteLastSlot(String areaId) async {
    final document =
        await _firestore.collection('motorcycle_area').doc(areaId).get();
    final data = document.data() ?? {};

    // Find the last slot number
    int lastSlot = 1;
    while (data.containsKey('Slot $lastSlot')) {
      lastSlot++;
    }
    lastSlot--; // Adjust to the last valid slot

    if (lastSlot > 0) {
      await _firestore.collection('motorcycle_area').doc(areaId).update({
        'Slot $lastSlot': FieldValue.delete(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Slot $lastSlot deleted from $areaId!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No slots available to delete!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Deletes a motorcycle area
  Future<void> deleteMotorcycleArea(String documentId) async {
    await _firestore.collection('motorcycle_area').doc(documentId).delete();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Motorcycle area deleted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text('Motorcycle Areas'),
        backgroundColor: Colors.amberAccent[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Search bar for filtering areas
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => addMotorcycleArea(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Motorcycle Area'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('motorcycle_area').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }

                  final areas = snapshot.data?.docs ?? [];
                  final filteredAreas = areas
                      .where(
                          (area) => area.id.toLowerCase().contains(searchQuery))
                      .toList();

                  if (filteredAreas.isEmpty) {
                    return const Center(
                      child: Text('No matching motorcycle areas found.'),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredAreas.length,
                    itemBuilder: (context, index) {
                      final area = filteredAreas[index];
                      final documentId = area.id;
                      final data = area.data() as Map<String, dynamic>;
                      final slotCount = data.keys
                          .where((key) => key.startsWith('Slot '))
                          .length;

                      return Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.amberAccent[400],
                            child: Text('${index + 1}'),
                          ),
                          title: Text(documentId),
                          subtitle: Text('$slotCount Slots Registered'),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'Add Slot') {
                                await addSlot(documentId);
                              } else if (value == 'Delete Slot') {
                                await deleteLastSlot(documentId);
                              } else if (value == 'Delete Area') {
                                await deleteMotorcycleArea(documentId);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'Add Slot',
                                child: Text('Add Slot'),
                              ),
                              const PopupMenuItem(
                                value: 'Delete Slot',
                                child: Text('Delete Slot'),
                              ),
                              const PopupMenuItem(
                                value: 'Delete Area',
                                child: Text('Delete Area'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
