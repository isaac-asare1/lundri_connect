// class Validators {
//   Validators._();

//   static String? validateRequired(
//     String? value, {
//     String fieldName = 'This field',
//   }) {
//     if (value == null || value.trim().isEmpty) {
//       return '$fieldName is required';
//     }
//     return null;
//   }

//   static String? validateEmail(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'Email is required';
//     }

//     final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');

//     if (!emailRegex.hasMatch(value.trim())) {
//       return 'Enter a valid email address';
//     }

//     return null;
//   }

//   static String? validatePhone(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'Phone number is required';
//     }

//     final cleaned = value.replaceAll(RegExp(r'\s+'), '');

//     if (cleaned.length < 10) {
//       return 'Enter a valid phone number';
//     }

//     return null;
//   }

//   static String? validateLaundryServiceName(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'Laundry service name is required';
//     }

//     final cleaned = value.trim();

//     if (cleaned.length < 2) {
//       return 'Enter a valid laundry service name';
//     }

//     return null;
//   }

//   static String? validateEmailOrPhone(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'Email or phone is required';
//     }

//     final input = value.trim();

//     final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');

//     final phoneRegex = RegExp(r'^\+?[0-9\s]{10,15}$');

//     if (!emailRegex.hasMatch(input) && !phoneRegex.hasMatch(input)) {
//       return 'Enter a valid email or phone number';
//     }

//     return null;
//   }

//   static String? validatePassword(String? value) {
//     if (value == null || value.isEmpty) {
//       return 'Password is required';
//     }

//     if (value.length < 6) {
//       return 'Password must be at least 6 characters';
//     }

//     return null;
//   }

//   static String? validateFullName(String? value) {
//     if (value == null || value.trim().isEmpty) {
//       return 'Full name is required';
//     }

//     if (value.trim().length < 2) {
//       return 'Enter a valid full name';
//     }

//     return null;
//   }
// }

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

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }

    return null;
  }

  /// Validates Ghana phone numbers in any of these common forms:
  ///
  /// 0241234567
  /// 241234567
  /// 233241234567
  /// +233241234567
  ///
  /// The value is normalized before validation so spaces, hyphens and
  /// brackets do not affect the result.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }

    final normalized = normalizeGhanaPhoneNumber(value);

    if (normalized == null) {
      return 'Enter a valid Ghana phone number';
    }

    return null;
  }

  /// Returns a Firebase-ready Ghana phone number such as:
  /// +233241234567
  ///
  /// Returns null when the input cannot be normalized into a valid
  /// Ghana phone number.
  static String? normalizeGhanaPhoneNumber(String? value) {
    if (value == null) return null;

    String input = value.trim();

    if (input.isEmpty) return null;

    // Remove spaces, dashes, brackets and other non-numeric characters,
    // while allowing us to normalize numbers that originally started with +.
    input = input.replaceAll(RegExp(r'[^0-9]'), '');

    String nationalNumber;

    if (input.startsWith('233')) {
      nationalNumber = input.substring(3);
    } else if (input.startsWith('0')) {
      nationalNumber = input.substring(1);
    } else {
      nationalNumber = input;
    }

    // Ghana national numbers contain 9 digits after +233.
    if (!RegExp(r'^\d{9}$').hasMatch(nationalNumber)) {
      return null;
    }

    return '+233$nationalNumber';
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

    final emailRegex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$');

    final isValidEmail = emailRegex.hasMatch(input);
    final isValidPhone = normalizeGhanaPhoneNumber(input) != null;

    if (!isValidEmail && !isValidPhone) {
      return 'Enter a valid email or Ghana phone number';
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
