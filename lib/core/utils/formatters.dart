import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

String money(num value) => _currency.format(value);

String durationLabel(num seconds) {
  final d = Duration(seconds: seconds.round());
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

String parseError(Object e) {
  final s = e.toString().toLowerCase();
  if (s.contains('user-not-found') || s.contains('wrong-password') || s.contains('invalid-credential')) {
    return 'Invalid email or password.';
  } else if (s.contains('email-already-in-use')) {
    return 'This email is already in use.';
  } else if (s.contains('invalid-email')) {
    return 'Please enter a valid email address.';
  } else if (s.contains('weak-password')) {
    return 'Your password is too weak.';
  } else if (s.contains('network-request-failed') || s.contains('socketexception') || s.contains('dioexception') || s.contains('failed host lookup')) {
    return 'Network error. Please check your connection.';
  } else if (s.contains('passwords do not match')) {
    return 'Passwords do not match.';
  } else if (s.contains('phone number is required')) {
    return 'Phone number is required.';
  } else if (s.contains('google_sign_in')) {
    return 'Google Sign-In was cancelled or failed.';
  }
  return 'An error occurred. Please try again later.';
}
