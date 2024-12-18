// otp_utils.dart
import 'dart:math';

/// Generates a 6-digit random OTP
String generateOTP() {
  final random = Random();
  return (random.nextInt(900000) + 100000).toString(); // Ensures 6 digits
}
