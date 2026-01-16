import 'package:flutter/material.dart';

class ValidationUtils {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }

    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }

    if (value.length > 128) {
      return 'Password must be less than 128 characters';
    }

    // Check for at least one letter and one number
    if (!RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one letter and one number';
    }

    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }

    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (value.length > 50) {
      return 'Name must be less than 50 characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  // Circle name validation
  static String? validateCircleName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Circle name is required';
    }

    if (value.trim().length < 3) {
      return 'Circle name must be at least 3 characters long';
    }

    if (value.length > 30) {
      return 'Circle name must be less than 30 characters';
    }

    // Check for valid characters (letters, numbers, spaces, basic punctuation)
    if (!RegExp(r"^[a-zA-Z0-9\s\-_'.!?]+$").hasMatch(value)) {
      return 'Circle name contains invalid characters';
    }

    return null;
  }

  // Invite code validation
  static String? validateInviteCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Invite code is required';
    }

    // Remove spaces and convert to uppercase
    final cleanCode = value.replaceAll(' ', '').toUpperCase();

    if (cleanCode.length != 6) {
      return 'Invite code must be 6 characters long';
    }

    // Check for valid characters (letters and numbers only)
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(cleanCode)) {
      return 'Invite code can only contain letters and numbers';
    }

    return null;
  }

  // Post content validation
  static String? validatePostContent(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Post content cannot be empty';
    }

    if (value.length > 2000) {
      return 'Post content must be less than 2000 characters';
    }

    return null;
  }

  // Comment validation
  static String? validateComment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Comment cannot be empty';
    }

    if (value.length > 500) {
      return 'Comment must be less than 500 characters';
    }

    return null;
  }

  // Task title validation
  static String? validateTaskTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Task title is required';
    }

    if (value.trim().length < 3) {
      return 'Task title must be at least 3 characters long';
    }

    if (value.length > 100) {
      return 'Task title must be less than 100 characters';
    }

    return null;
  }

  // Task description validation
  static String? validateTaskDescription(String? value) {
    if (value != null && value.length > 1000) {
      return 'Task description must be less than 1000 characters';
    }

    return null;
  }

  // Message validation
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Message cannot be empty';
    }

    if (value.length > 1000) {
      return 'Message must be less than 1000 characters';
    }

    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return 'Please enter a valid URL starting with http:// or https://';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }

  // Phone number validation (basic)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }

    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length < 10 || digitsOnly.length > 15) {
      return 'Please enter a valid phone number';
    }

    return null;
  }

  // Bio validation
  static String? validateBio(String? value) {
    if (value != null && value.length > 150) {
      return 'Bio must be less than 150 characters';
    }

    return null;
  }

  // Location validation
  static String? validateLocation(String? value) {
    if (value != null && value.length > 50) {
      return 'Location must be less than 50 characters';
    }

    return null;
  }

  // File name validation
  static String? validateFileName(String? value) {
    if (value == null || value.isEmpty) {
      return 'File name is required';
    }

    if (value.length > 255) {
      return 'File name must be less than 255 characters';
    }

    // Check for invalid characters
    if (RegExp(r'[<>:"/\\|?*]').hasMatch(value)) {
      return 'File name contains invalid characters';
    }

    return null;
  }

  // Generic required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  // Generic length validation
  static String? validateLength(
    String? value,
    String fieldName,
    int minLength,
    int maxLength,
  ) {
    if (value == null) return null;

    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }

    if (value.length > maxLength) {
      return '$fieldName must be less than $maxLength characters';
    }

    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(
    String? value,
    String? originalPassword,
  ) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != originalPassword) {
      return 'Passwords do not match';
    }

    return null;
  }

  // Search query validation
  static String? validateSearchQuery(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Search query cannot be empty';
    }

    if (value.trim().length < 2) {
      return 'Search query must be at least 2 characters long';
    }

    if (value.length > 100) {
      return 'Search query must be less than 100 characters';
    }

    return null;
  }

  // Age validation (for date of birth)
  static String? validateAge(DateTime? birthDate) {
    if (birthDate == null) {
      return null; // Age is optional
    }

    final now = DateTime.now();
    final age = now.year - birthDate.year;

    if (age < 13) {
      return 'You must be at least 13 years old to use this app';
    }

    if (age > 120) {
      return 'Please enter a valid birth date';
    }

    return null;
  }

  // Custom validation with regex
  static String? validateWithRegex(
    String? value,
    RegExp regex,
    String errorMessage,
  ) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (!regex.hasMatch(value)) {
      return errorMessage;
    }

    return null;
  }

  // Sanitize input (remove potentially harmful characters)
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(
          RegExp(
            r'[^\w\s\-_.,!?@#$%^&*()+={}[\]:;"'
            "'"
            r'\\`~]',
          ),
          '',
        ) // Remove special chars
        .trim();
  }

  // Check if string contains profanity (basic implementation)
  static bool containsProfanity(String text) {
    final profanityWords = [
      // Add your profanity filter words here
      // This is a basic implementation - in production, use a proper profanity filter service
    ];

    final lowerText = text.toLowerCase();
    return profanityWords.any((word) => lowerText.contains(word));
  }

  // Validate profanity
  static String? validateProfanity(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (containsProfanity(value)) {
      return '$fieldName contains inappropriate content';
    }

    return null;
  }
}

// Form validation helper
class FormValidationHelper {
  static bool validateForm(GlobalKey<FormState> formKey) {
    return formKey.currentState?.validate() ?? false;
  }

  static void saveForm(GlobalKey<FormState> formKey) {
    formKey.currentState?.save();
  }

  static void resetForm(GlobalKey<FormState> formKey) {
    formKey.currentState?.reset();
  }

  static Map<String, String> getFormErrors(GlobalKey<FormState> formKey) {
    final errors = <String, String>{};
    // This would require custom implementation to extract field-specific errors
    return errors;
  }
}

// Input formatters for common use cases
class InputFormatters {
  // Phone number formatter
  static String formatPhoneNumber(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length >= 10) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6, 10)}';
    }
    return input;
  }

  // Credit card formatter
  static String formatCreditCard(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }
    return buffer.toString();
  }

  // Currency formatter
  static String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
}
