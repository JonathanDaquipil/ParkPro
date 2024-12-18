import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CompletedTasksPage extends StatelessWidget {
  const CompletedTasksPage({Key? key}) : super(key: key);

  Future<String> _getEnforcerName(String enforcerId) async {
    try {
      // Query the collection where the enforcer_id matches the provided ID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('enforcer_account')
          .where('enforcer_id', isEqualTo: enforcerId)
          .get();

      // Check if any document matches the query
      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return '${data['first_name'] ?? ''} ${data['last_name'] ?? ''}'.trim();
      }
      return 'Unknown Enforcer'; // Return if no documents match
    } catch (e) {
      debugPrint('Error fetching enforcer name: $e');
      return 'Unknown Enforcer'; // Return in case of an error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text('Completed Tasks'),
        backgroundColor: Colors.amberAccent[400],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('task_management')
            .where('status', isEqualTo: 'Completed')
            .orderBy('completion_time', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No completed tasks found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final task = snapshot.data!.docs[index];
              final data = task.data() as Map<String, dynamic>;

              // Format completion time
              String formattedTime = 'Time not available';
              if (data['completion_time'] != null) {
                final timestamp = data['completion_time'] as Timestamp;
                final dateTime = timestamp.toDate();
                formattedTime = DateFormat('MMM d, y h:mm a').format(dateTime);
              }

              return FutureBuilder<String>(
                future: _getEnforcerName(data['enforcer_id'] ?? ''),
                builder: (context, enforcerSnapshot) {
                  final enforcerName = enforcerSnapshot.data ?? 'Loading...';

                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ExpansionTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ),
                      title: Text(
                        data['description'] ?? 'No description',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Text(
                        'Completed: $formattedTime',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(height: 8),
                              _buildInfoRow(
                                  Icons.person, 'Enforcer', enforcerName),
                              const SizedBox(height: 8),
                              _buildInfoRow(Icons.numbers, 'Task ID',
                                  data['task_id']?.toString() ?? 'N/A'),
                              const SizedBox(height: 8),
                              if (data['location'] != null) ...[
                                _buildInfoRow(Icons.location_on, 'Location',
                                    data['location']),
                                const SizedBox(height: 8),
                              ],
                              if (data['notes'] != null) ...[
                                _buildInfoRow(
                                    Icons.note, 'Notes', data['notes']),
                                const SizedBox(height: 8),
                              ],
                              _buildInfoRow(Icons.access_time,
                                  'Completion Time', formattedTime),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}
