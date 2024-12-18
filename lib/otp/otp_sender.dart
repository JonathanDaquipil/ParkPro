import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

const serviceId = 'service_bqz8d65';
const templateId = 'template_gj4m487';
const userId = 'jFuamMswjQsazs5eg';

final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

Future<void> sendEmail({
  required String email,
  required String otpCode,
  required String userName,
}) async {
  // Construct email message content for OTP
  String message = 'Hello $userName,\n\nYour OTP code is: $otpCode\n\n'
      'Please do not share this code with anyone.\n\n'
      'Thank you,\nUser';

  final data = {
    'service_id': serviceId,
    'template_id': templateId,
    'user_id': userId,
    'template_params': {
      'subject': 'Your OTP Code',
      'message': message,
      'to_email': email,
    },
  };

  final response = await http.post(
    url,
    headers: {'origin': 'http://localhost', 'Content-Type': 'application/json'},
    body: jsonEncode(data),
  );

  if (response.statusCode == 200) {
    if (kDebugMode) {
      print('Email sent successfully');
    }
  } else {
    if (kDebugMode) {
      print('Failed to send email. Status code: ${response.statusCode}');
    }
  }
}
