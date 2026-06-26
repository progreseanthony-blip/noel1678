import 'package:flutter/material.dart';

class DialogValidators {
  static const String requiredMessage = 'This field is required';
  static const String invalidEmail = 'Enter a valid email';

  static FormFieldValidator<String> required() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return requiredMessage;
      return null;
    };
  }

  static FormFieldValidator<String> requiredPositive() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return requiredMessage;
      final num = double.tryParse(value.trim());
      if (num == null || num < 0) return 'Enter a positive number';
      return null;
    };
  }

  static FormFieldValidator<String> email() {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return requiredMessage;
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(value.trim())) return invalidEmail;
      return null;
    };
  }

  static FormFieldValidator<T> requiredDropdown<T>() {
    return (T? value) {
      if (value == null) return requiredMessage;
      return null;
    };
  }
}
