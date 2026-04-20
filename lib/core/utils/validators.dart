class Validators {
  Validators._();

  static String? validateRequired(
    String? value, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final cleaned = value.replaceAll(RegExp(r'\s+'), '');

    if (cleaned.length < 10) {
      return 'Enter a valid phone number';
    }

    return null;
  }

  static String? validateLaundryServiceName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Laundry service name is required';
    }

    final cleaned = value.trim();

    if (cleaned.length < 2) {
      return 'Enter a valid laundry service name';
    }

    return null;
  }

  static String? validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email or phone is required';
    }

    final input = value.trim();

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');

    final phoneRegex = RegExp(r'^\+?[0-9\s]{10,15}$');

    if (!emailRegex.hasMatch(input) && !phoneRegex.hasMatch(input)) {
      return 'Enter a valid email or phone number';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }

  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }

    if (value.trim().length < 2) {
      return 'Enter a valid full name';
    }

    return null;
  }
}
