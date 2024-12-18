import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parkpro_admin/completed_tasks_page.dart';

class TaskManagementAdmin extends StatefulWidget {
  const TaskManagementAdmin({Key? key}) : super(key: key);

  @override
  State<TaskManagementAdmin> createState() => _TaskManagementAdminState();
}

class _TaskManagementAdminState extends State<TaskManagementAdmin> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _taskDescriptionController =
      TextEditingController();

  String? _selectedEnforcerId;
  String? _selectedEnforcerName;
  String _taskStatus = 'Pending';
  bool _isLoading = false;

  /// Fetch all tasks from Firestore (ordered by task_number in descending order)
  Stream<QuerySnapshot> _fetchTasks() {
    return _firestore
        .collection('task_management')
        .orderBy('task_number', descending: true) // Order by task number
        .snapshots();
  }

  /// Fetch all registered enforcers from Firestore
  Future<List<Map<String, String>>> _fetchEnforcers() async {
    final snapshot = await _firestore.collection('enforcer_account').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'enforcer_id': data['enforcer_id'] as String,
        'full_name':
            '${data['first_name'] as String} ${data['last_name'] as String}',
      };
    }).toList();
  }

  /// Assigns a task to a specific enforcer
  Future<void> _assignTask() async {
    final String description = _taskDescriptionController.text.trim();

    if (description.isEmpty || _selectedEnforcerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String taskId = _firestore.collection('task_management').doc().id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await _firestore.collection('task_management').doc(taskId).set({
        'task_id': taskId,
        'description': description,
        'status': 'Pending', // Always start with Pending status
        'enforcer_id': _selectedEnforcerId,
        'enforcer_name': _selectedEnforcerName,
        'task_number': timestamp,
        'created_at': Timestamp.now(),
        'completion_time': null,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task assigned successfully.'),
          backgroundColor: Colors.green,
        ),
      );

      _taskDescriptionController.clear();
      setState(() {
        _selectedEnforcerId = null;
        _selectedEnforcerName = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign task: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Fetch all completed tasks from Firestore (ordered by completion_time in descending order)
  Stream<QuerySnapshot> _fetchCompletedTasks() {
    return _firestore
        .collection('task_management')
        .where('status', isEqualTo: 'Completed')
        .orderBy('completion_time', descending: true)
        .snapshots();
  }

  /// Displays completed tasks in a modal
  void _showCompletedTasksDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Use a separate context
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Completed Tasks'),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () =>
                    Navigator.of(dialogContext).pop(), // Use dialogContext
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: StreamBuilder<QuerySnapshot>(
              stream: _fetchCompletedTasks(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No completed tasks available.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                final tasks = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final completionTime =
                        task['completion_time'] as Timestamp?;
                    final completionDate = completionTime != null
                        ? completionTime.toDate().toString().split('.')[0]
                        : 'Date not available';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ListTile(
                        leading:
                            const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(task['description'] ?? 'No description'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Assigned to: ${task['enforcer_name'] ?? 'N/A'} (${task['enforcer_id'] ?? 'N/A'})',
                            ),
                            Text(
                              'Completed on: $completionDate',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Text(
                          'Completed',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildTaskList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _fetchTasks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tasks available.'));
        }

        final allTasks = snapshot.data!.docs;
        final activeTasks = allTasks.where((doc) {
          final status = doc['status'] as String;
          return status == 'Pending' || status == 'In Progress';
        }).toList();

        if (activeTasks.isEmpty) {
          return const Center(child: Text('No active tasks available.'));
        }

        return ListView.builder(
          itemCount: activeTasks.length,
          itemBuilder: (context, index) {
            final task = activeTasks[index];
            final String status = task['status'] as String;

            Color statusColor;
            if (status == 'Pending') {
              statusColor = Colors.orange;
            } else if (status == 'In Progress') {
              statusColor = Colors.blue;
            } else {
              statusColor = Colors.black;
            }

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(task['description'] ?? 'No description'),
                subtitle: Text(
                  'Assigned to: ${task['enforcer_name'] ?? 'N/A'} (${task['enforcer_id'] ?? 'N/A'})',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: status,
                      items: ['Pending', 'In Progress', 'Completed']
                          .map(
                            (statusOption) => DropdownMenuItem<String>(
                              value: statusOption,
                              child: Text(statusOption),
                            ),
                          )
                          .toList(),
                      onChanged: (value) async {
                        if (value != null) {
                          try {
                            await _firestore
                                .collection('task_management')
                                .doc(task['task_id'])
                                .update({
                              'status': value,
                              'completion_time':
                                  value == 'Completed' ? Timestamp.now() : null,
                            });

                            if (value == 'Completed') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Task marked as completed!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating task: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTaskForm() {
    return FutureBuilder<List<Map<String, String>>>(
      future: _fetchEnforcers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No enforcers available.'));
        }

        final enforcers = snapshot.data!;

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Assign Task',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _taskDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Task Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _selectedEnforcerId,
                  items: enforcers.map((enforcer) {
                    return DropdownMenuItem<String>(
                      value: enforcer['enforcer_id'],
                      child: Text(enforcer['full_name']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    final selectedEnforcer = enforcers.firstWhere(
                      (e) => e['enforcer_id'] == value,
                    );
                    setState(() {
                      _selectedEnforcerId = selectedEnforcer['enforcer_id'];
                      _selectedEnforcerName = selectedEnforcer['full_name'];
                    });
                  },
                  decoration: const InputDecoration(
                    labelText: 'Assign to Enforcer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _taskStatus,
                  items: ['Pending', 'In Progress', 'Completed']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _taskStatus = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    labelText: 'Task Status',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _assignTask,
                        child: const Text('Assign Task'),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        backgroundColor: Colors.amberAccent[400],
        title: const Text('Task Management - Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_circle, color: Colors.white),
            tooltip: 'View Completed Tasks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const CompletedTasksPage(), // Pass your widget here
                ),
              );
            },
          ),
        ],
      ),
      body: isLargeScreen
          ? Column(
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: _buildTaskList()),
                      const VerticalDivider(),
                      Expanded(flex: 1, child: _buildTaskForm()),
                    ],
                  ),
                ),
              ],
            )
          : _buildTaskList(),
    );
  }
}
