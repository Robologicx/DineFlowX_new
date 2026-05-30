import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final bool isObsecure;
  final String hint;
  final TextInputType? keyBoardType;
  final TextEditingController controller;
  final int maxLines;
  final String? Function(String?)? validator; // ✅ Allow custom validation

  const CustomTextField({
    super.key,
    this.maxLines = 1,
    required this.controller,
    required this.hint,
    this.keyBoardType,
    this.isObsecure = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyBoardType,
      obscureText: isObsecure,
      validator: validator ?? _defaultValidator, // ✅ Fallback unified validator
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  // ✅ Unified, context-aware default validator
  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $hint';
    }

    if (keyBoardType == TextInputType.emailAddress) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
    }

    if (isObsecure && value.length < 6) {
      return 'Password must be at least 6 characters';
    }

    return null;
  }
}
