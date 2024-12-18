import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _ManageUserPageState();
}

class _ManageUserPageState extends State<UserList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent[100],
      appBar: AppBar(
        title: const Text('Manage Users'),
        backgroundColor: Colors.amberAccent[400],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('user') // Access the "user" collection
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final users = snapshot.data?.docs ?? [];
            if (users.isEmpty) {
              return const Center(child: Text('No users found.'));
            }

            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final fullName = '${user['First_Name']} ${user['Last_Name']}';
                final email = user['Email'];

                return Card(
                  elevation: 4.0,
                  child: ListTile(
                    title: Text(fullName), // Display the full name
                    subtitle: Text('Email: $email'), // Display the email
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmation = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete User'),
                            content: Text(
                                'Are you sure you want to delete $fullName?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );

                        if (confirmation == true) {
                          // Delete user from Firestore
                          await FirebaseFirestore.instance
                              .collection('user')
                              .doc(user.id)
                              .delete();

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User deleted successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
