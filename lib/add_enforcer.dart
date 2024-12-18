import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEnforcerPage extends StatefulWidget {
  const AddEnforcerPage({Key? key}) : super(key: key);

  @override
  State<AddEnforcerPage> createState() => _AddEnforcerPageState();
}

class _AddEnforcerPageState extends State<AddEnforcerPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addEnforcer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Extract and trim input values
        final firstName = _firstNameController.text.trim();
        final lastName = _lastNameController.text.trim();
        final password = _passwordController.text.trim();

        // Fallback initials for ID generation
        final initialFirstName =
            firstName.isNotEmpty ? firstName[0].toUpperCase() : 'X';
        final initialLastName =
            lastName.isNotEmpty ? lastName[0].toUpperCase() : 'X';

        // Generate unique enforcer ID
        final timestamp =
            DateTime.now().millisecondsSinceEpoch.toString().substring(8);
        final enforcerId = '$initialFirstName$initialLastName$timestamp';

        // Save to Firestore
        await FirebaseFirestore.instance.collection('enforcer_account').add({
          'enforcer_id': enforcerId,
          'first_name': firstName,
          'last_name': lastName,
          'password': password,
          'status': 'Offline', // Default status
          'last_active': FieldValue.serverTimestamp(), // Last active timestamp
          'location': 'Not Available', // Default location
          'latitude': 0.0,
          'longitude': 0.0,
          'created_at': FieldValue.serverTimestamp(), // Creation timestamp
        });

        if (!mounted) return;

        // Success notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Enforcer successfully added with ID: $enforcerId'),
            backgroundColor: Colors.green,
          ),
        );

        // Clear form fields
        _formKey.currentState!.reset();
        _firstNameController.clear();
        _lastNameController.clear();
        _passwordController.clear();

        // Close page
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;

        // Error notification
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error while adding enforcer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Enforcer'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // First Name Field
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Last Name Field
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password Field
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters long';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _addEnforcer,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Add Enforcer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
