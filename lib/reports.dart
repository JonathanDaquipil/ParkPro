import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Reports extends StatefulWidget {
  const Reports({super.key});

  @override
  State<Reports> createState() => _ReportsState();
}

class _ReportsState extends State<Reports> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  // Variables for creating a new report
  String _title = '';
  String _description = '';
  String _status = 'Pending'; // Default status

  // Fetch enforcer_id and full_name from SharedPreferences
  Future<Map<String, String?>> _fetchEnforcerDetails() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'enforcerId': prefs.getString('enforcerId'),
      'fullName': prefs.getString('enforcerName'),
    };
  }

  // Fetch reports specific to the current enforcer
  Stream<QuerySnapshot> _fetchReports() async* {
    final enforcerDetails = await _fetchEnforcerDetails();
    final enforcerId = enforcerDetails['enforcerId'];
    if (enforcerId != null) {
      yield* _firestore
          .collection('reports')
          .where('enforcer_id', isEqualTo: enforcerId)
          .snapshots();
    }
  }

  // Generate a new report
  Future<void> _generateReport() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final enforcerDetails = await _fetchEnforcerDetails();
      final enforcerId = enforcerDetails['enforcerId'];
      final fullName = enforcerDetails['fullName'];

      if (enforcerId == null || fullName == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enforcer ID or Name not found! Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Generate report data
      final reportData = {
        'title': _title,
        'description': _description,
        'status': _status,
        'created_at': Timestamp.now(),
        'report_id': DateTime.now().millisecondsSinceEpoch.toString(),
        'enforcer_id': enforcerId,
        'full_name': fullName,
      };

      try {
        await _firestore.collection('reports').add(reportData);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState?.reset();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Update report status
  Future<void> _updateReportStatus(String reportId, String status) async {
    try {
      await _firestore.collection('reports').doc(reportId).update({
        'status': status,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report status updated successfully!'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update report: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text(
          'Manage Reports',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Makes the text bold
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.amberAccent[400],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a New Report',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 25),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration:
                        const InputDecoration(labelText: 'Report Title'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                    onSaved: (value) => _title = value ?? '',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 4,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                    onSaved: (value) => _description = value ?? '',
                  ),
                  const SizedBox(height: 25),
                  DropdownButtonFormField<String>(
                    value: _status,
                    items: const [
                      DropdownMenuItem(
                          value: 'Pending', child: Text('Pending')),
                      DropdownMenuItem(
                          value: 'Resolved', child: Text('Resolved')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _status = value ?? 'Pending';
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: _generateReport,
                    child: const Text('Submit Report'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Your Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: _fetchReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading reports: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No reports available.'),
                  );
                }

                final reports = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report =
                        reports[index].data() as Map<String, dynamic>;
                    final String reportId = reports[index].id;
                    final String title = report['title'] ?? 'Untitled';
                    final String status = report['status'] ?? 'Pending';
                    // ignore: unused_local_variable
                    final String fullName = report['full_name'] ?? 'Unknown';
                    final Timestamp createdAt = report['created_at'];

                    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
                    final String formattedDate =
                        dateFormat.format(createdAt.toDate());

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: Icon(
                          Icons.insert_drive_file,
                          color: status == 'Resolved'
                              ? Colors.green
                              : Colors.orange,
                        ),
                        title: Text('Report: $title'),
                        subtitle: Text(
                          'Status: $status\nSent at: $formattedDate',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.update),
                          onPressed: () {
                            _updateReportStatus(
                              reportId,
                              status == 'Pending' ? 'Resolved' : 'Pending',
                            );
                          },
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
    );
  }
}
