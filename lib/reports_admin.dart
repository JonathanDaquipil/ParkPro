import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsAdmin extends StatelessWidget {
  const ReportsAdmin({super.key});

  /// Fetches reports from Firestore
  Stream<QuerySnapshot> _fetchReports() {
    return FirebaseFirestore.instance.collection('reports').snapshots();
  }

  /// Updates the status of a report in Firestore
  Future<void> _updateReportStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('reports')
        .doc(docId)
        .update({'status': newStatus});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text('Reports Management'),
        backgroundColor: Colors.amberAccent[400],
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          return LayoutBuilder(
            builder: (context, constraints) {
              return constraints.maxWidth > 600
                  ? _buildGridLayout(reports)
                  : _buildListLayout(reports);
            },
          );
        },
      ),
    );
  }

  Widget _buildGridLayout(List<QueryDocumentSnapshot> reports) {
    // Sort reports by the `created_at` field in descending order
    reports.sort((a, b) {
      Timestamp createdAtA = a['created_at'];
      Timestamp createdAtB = b['created_at'];
      return createdAtB.compareTo(createdAtA); // Descending order
    });

    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3 / 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
      ),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return _buildReportCard(reports[index], context);
      },
    );
  }

  Widget _buildListLayout(List<QueryDocumentSnapshot> reports) {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        return _buildReportCard(reports[index], context);
      },
    );
  }

  Widget _buildReportCard(
      QueryDocumentSnapshot reportDoc, BuildContext context) {
    final report = reportDoc.data() as Map<String, dynamic>;
    final String docId = reportDoc.id;
    final String reportId = report['report_id'] ?? 'Unknown ID';
    final String title = report['title'] ?? 'Untitled';
    final String status = report['status'] ?? 'Pending';
    final String description =
        report['description'] ?? 'No description provided.';
    final String submittedBy = report['full_name'] ?? 'Unknown Enforcer';
    final String enforcerId = report['enforcer_id'] ?? 'unknown enforcer id';
    final Timestamp createdAt = report['created_at'];
    final Timestamp updatedAt = report['updated_at'] ?? createdAt;

    final formattedCreatedAt = "${createdAt.toDate().toLocal()}".split(' ')[0];
    final formattedUpdatedAt = "${updatedAt.toDate().toLocal()}".split(' ')[0];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report ID: $reportId',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Title: $title',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: $status',
              style: TextStyle(
                fontSize: 14,
                color: status == 'Resolved' ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Submitted by: $submittedBy (Enforcer ID: $enforcerId)',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text(
              'Description:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created at: $formattedCreatedAt',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Updated at: $formattedUpdatedAt',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => _updateReportStatus(docId, 'Resolved'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Mark as Resolved'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _updateReportStatus(docId, 'Pending'),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Mark as Pending'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
