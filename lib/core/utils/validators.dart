/// Input validation helpers for forms
class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Phone number is required';
    // Remove any spaces or dashes for validation
    final digitsOnly = value.replaceAll(RegExp(r'[\s-]'), '');
    if (digitsOnly.length != 10)
      return 'Phone number must be exactly 10 digits';
    if (!RegExp(r'^\d{10}$').hasMatch(digitsOnly)) return 'Enter only digits';
    return null;
  }

  /// Validator for phone number that allows empty (optional field)
  static String? phoneOptional(String? value) {
    if (value == null || value.isEmpty) return null;
    final digitsOnly = value.replaceAll(RegExp(r'[\s-]'), '');
    if (digitsOnly.length != 10)
      return 'Phone number must be exactly 10 digits';
    if (!RegExp(r'^\d{10}$').hasMatch(digitsOnly)) return 'Enter only digits';
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? minLength(
    String? value,
    int min, [
    String fieldName = 'This field',
  ]) {
    if (value == null || value.length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  static String? maxLength(
    String? value,
    int max, [
    String fieldName = 'This field',
  ]) {
    if (value != null && value.length > max) {
      return '$fieldName must be at most $max characters';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.isEmpty) return 'Price is required';
    final parsed = double.tryParse(value);
    if (parsed == null || parsed <= 0) return 'Enter a valid price';
    if (parsed > 100000) return 'Price is too high';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6) return 'OTP must be 6 digits';
    if (int.tryParse(value) == null) return 'OTP must contain only numbers';
    return null;
  }

  static String? name(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (value.trim().length > 50) return 'Name is too long';
    return null;
  }

  static String? durationDays(String? value) {
    if (value == null || value.isEmpty) return 'Duration is required';
    final days = int.tryParse(value);
    if (days == null || days < 1) return 'Enter a valid number of days';
    if (days > 30) return 'Maximum rental is 30 days';
    return null;
  }
}
