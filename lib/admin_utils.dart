import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Hash a password using SHA-256
String hashPassword(String password) {
  final bytes = utf8.encode(password); // Convert password to bytes
  return sha256.convert(bytes).toString(); // Hash and return as a string
}

/// Function to create an admin account in Firestore with a hashed password
Future<void> createAdminAccount(String adminId, String password) async {
  try {
    final hashedPassword = hashPassword(password);
    await FirebaseFirestore.instance.collection('admin_acc').doc(adminId).set({
      'Admin_Id': adminId,
      'Password': hashedPassword,
    });
    print('Admin account created successfully!');
  } catch (e) {
    print('Failed to create admin account: $e');
  }
}
