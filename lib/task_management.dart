import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mixins/status_mixin.dart';

class TaskManagementEnforcer extends StatefulWidget {
  final String enforcerId;

  const TaskManagementEnforcer({super.key, required this.enforcerId});

  @override
  State<TaskManagementEnforcer> createState() => _TaskManagementEnforcerState();
}

class _TaskManagementEnforcerState extends State<TaskManagementEnforcer>
    with WidgetsBindingObserver, StatusMixin {
  /// Fetches tasks assigned to the enforcer from Firestore
  Stream<QuerySnapshot> _fetchAssignedTasks(String enforcerId) {
    debugPrint('Fetching tasks for enforcerId: $enforcerId'); // Debug log
    return FirebaseFirestore.instance
        .collection('task_management')
        .where('enforcer_id', isEqualTo: enforcerId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[400],
      appBar: AppBar(
        title: const Text(
          'Task Management',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.amberAccent[100],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assigned Tasks',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _fetchAssignedTasks(widget.enforcerId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Error fetching tasks: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text('No tasks assigned.'),
                        );
                      }

                      final tasks = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task =
                              tasks[index].data() as Map<String, dynamic>;

                          // Validate task fields
                          if (!task.containsKey('task_id') ||
                              !task.containsKey('description') ||
                              !task.containsKey('status')) {
                            return const ListTile(
                              title: Text('Invalid task data'),
                            );
                          }

                          final String taskId = task['task_id'];
                          final String description = task['description'];
                          final String status = task['status'];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            child: ListTile(
                              leading: Icon(
                                Icons.task_alt,
                                color: status == 'Completed'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              title: Text('Task #$taskId'),
                              subtitle: Text(
                                'Status: $status',
                                style: TextStyle(
                                  color: status == 'Completed'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => TaskDetails(
                                      taskId: taskId,
                                      description: description,
                                      status: status,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TaskDetails extends StatelessWidget {
  final String taskId;
  final String description;
  final String status;

  const TaskDetails({
    super.key,
    required this.taskId,
    required this.description,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task #$taskId'),
        backgroundColor: Colors.amberAccent[100],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Task Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Task ID: $taskId',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Status: $status',
              style: TextStyle(
                fontSize: 16,
                color: status == 'Completed' ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Description:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
