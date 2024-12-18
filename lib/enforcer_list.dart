import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:intl/intl.dart';
import 'dart:async';

class EnforcerListPage extends StatefulWidget {
  const EnforcerListPage({super.key});

  @override
  State<EnforcerListPage> createState() => _EnforcerListPageState();
}

class _EnforcerListPageState extends State<EnforcerListPage> {
  bool _isRegisterButtonEnabled = true;

  /// Adds a new enforcer
  Future<void> addEnforcer(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    String firstName = '';
    String lastName = '';
    String enforcerId = '';
    String password = '';
    String latitude = '0.0';
    String location = 'Not set';
    String longitude = '0.0';
    // ignore: unused_local_variable
    String lastActive = '';
    // ignore: unused_local_variable
    String status = 'Online';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Register Enforcer'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter first name'
                      : null,
                  onSaved: (value) => firstName = value ?? '',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter last name' : null,
                  onSaved: (value) => lastName = value ?? '',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Enforcer ID'),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter enforcer ID'
                      : null,
                  onSaved: (value) => enforcerId = value ?? '',
                ),
                const SizedBox(height: 8),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) =>
                      value == null || value.isEmpty ? 'Enter password' : null,
                  onSaved: (value) => password = value ?? '',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _isRegisterButtonEnabled
                ? () async {
                    if (formKey.currentState!.validate()) {
                      // Disable the button
                      setState(() {
                        _isRegisterButtonEnabled = false;
                      });

                      // Start timer to re-enable the button after 2 seconds
                      Timer(const Duration(seconds: 2), () {
                        if (mounted) {
                          setState(() {
                            _isRegisterButtonEnabled = true;
                          });
                        }
                      });

                      formKey.currentState!.save();

                      final querySnapshot = await FirebaseFirestore.instance
                          .collection('enforcer_account')
                          .where('enforcer_id', isEqualTo: enforcerId)
                          .get();

                      if (querySnapshot.docs.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enforcer ID is already registered!'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        final enforcerData = {
                          'first_name': firstName,
                          'last_name': lastName,
                          'enforcer_id': enforcerId,
                          'password': password,
                          'latitude': latitude,
                          'location': location,
                          'longitude': longitude,
                          'timestamp': Timestamp.now(),
                        };

                        await FirebaseFirestore.instance
                            .collection('enforcer_account')
                            .add(enforcerData);

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Enforcer registered successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  }
                : null,
            child:
                Text(_isRegisterButtonEnabled ? 'Register' : 'Please wait...'),
          ),
        ],
      ),
    );
  }

  /// Edits an enforcer's details
  Future<void> editEnforcer(
      BuildContext context, DocumentSnapshot enforcer) async {
    final data = enforcer.data() as Map<String, dynamic>;

    // Controllers for editing
    final firstNameController =
        TextEditingController(text: data['first_name'] ?? '');
    final lastNameController =
        TextEditingController(text: data['last_name'] ?? '');
    final passwordController =
        TextEditingController(text: data['password'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Enforcer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await enforcer.reference.update({
                  'first_name': firstNameController.text.trim(),
                  'last_name': lastNameController.text.trim(),
                  if (passwordController.text.isNotEmpty)
                    'password': passwordController.text.trim(),
                  'last_active': FieldValue.serverTimestamp(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enforcer updated successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating enforcer: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Deletes an enforcer from Firestore
  Future<void> deleteEnforcer(
      BuildContext context, DocumentSnapshot enforcer) async {
    final data = enforcer.data() as Map<String, dynamic>;
    final firstName = data['first_name'] ?? 'Unknown';
    final lastName = data['last_name'] ?? 'Unknown';

    final bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Enforcer'),
            content:
                Text('Are you sure you want to delete $firstName $lastName?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await enforcer.reference.delete();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enforcer deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting enforcer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text('Enforcer List'),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.amberAccent[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed:
                  _isRegisterButtonEnabled ? () => addEnforcer(context) : null,
              icon: const Icon(Icons.add),
              label: Text(_isRegisterButtonEnabled
                  ? 'Register Enforcer'
                  : 'Please wait...'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('enforcer_account')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final enforcers = snapshot.data?.docs ?? [];
                  if (enforcers.isEmpty) {
                    return const Center(
                        child: Text('No enforcers registered.'));
                  }

                  return ListView.builder(
                    itemCount: enforcers.length,
                    itemBuilder: (context, index) {
                      final enforcer =
                          enforcers[index].data() as Map<String, dynamic>;
                      final firstName =
                          enforcer['first_name'] ?? 'No First Name';
                      final lastName = enforcer['last_name'] ?? 'No Last Name';
                      final fullName = '$firstName $lastName';
                      final enforcerId = enforcer['enforcer_id'] ?? 'N/A';
                      // ignore: unused_local_variable
                      final location =
                          enforcer['location'] ?? 'No location data';
                      final latitude =
                          enforcer['latitude']?.toString() ?? 'N/A';
                      final longitude =
                          enforcer['longitude']?.toString() ?? 'N/A';
                      final status = enforcer['status'] ?? 'Offline';

                      String lastActiveStr = 'Not yet active';
                      final lastActive = enforcer['last_active'] as Timestamp?;
                      if (lastActive != null) {
                        lastActiveStr = DateFormat('MMM d, y h:mm a')
                            .format(lastActive.toDate());
                      }

                      return Card(
                        elevation: 4.0,
                        margin: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 4.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              fullName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: status == 'Online'
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : Colors.grey
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: status == 'Online'
                                                      ? Colors.green
                                                      : Colors.grey,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      color: status == 'Online'
                                                          ? Colors.green
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    status,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: status == 'Online'
                                                          ? Colors.green
                                                          : Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: $enforcerId',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Last Active: $lastActiveStr',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // ignore: unnecessary_null_comparison
                                      if (latitude != null && longitude != null)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.location_on,
                                            color: Colors.green,
                                          ),
                                          onPressed: () async {
                                            final url = Uri.parse(
                                                'https://www.google.com/maps?q=$latitude,$longitude');
                                            if (await url_launcher
                                                .canLaunchUrl(url)) {
                                              await url_launcher.launchUrl(url);
                                            }
                                          },
                                          tooltip: 'View on Google Maps',
                                        ),
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () => editEnforcer(
                                            context, enforcers[index]),
                                        tooltip: 'Edit Enforcer',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => deleteEnforcer(
                                            context, enforcers[index]),
                                        tooltip: 'Delete Enforcer',
                                      ),
                                    ],
                                  ),
                                ],
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
