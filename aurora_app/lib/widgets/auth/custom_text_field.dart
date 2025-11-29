import 'package:flutter/material.dart';

/// CustomTextField
/// Reusable labeled input with consistent styling (radius, colors, focus +
/// error borders). Supports expansion, multi-line, validation, suffix icon
/// (e.g. password visibility), and custom capitalization. Separates label from
/// field for flexible vertical spacing.

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onChanged;
  final int? minLines;
  final int? maxLines;
  final bool expands;
  final TextInputAction? textInputAction;

  /// Reusable text form field wrapper.
  ///
  /// Required: [controller], [label], [hintText].
  /// Common optional tweaks:
  /// - [obscureText] for passwords
  /// - [suffixIcon] (e.g. visibility toggle)
  /// - [minLines]/[maxLines]/[expands] for multi‑line notes
  /// - [validator] to integrate with form validation
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.onChanged,
    this.minLines,
    this.maxLines,
    this.expands = false,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2F2E2C),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          onChanged: onChanged,
          validator: validator,
          minLines: expands ? null : minLines,
          maxLines: expands ? null : (maxLines ?? (obscureText ? 1 : 1)),
          expands: expands,
          textInputAction: textInputAction,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF2F2E2C),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFFA6C0B5),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE8E4DC),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFF5C97B),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFF2B8A0),
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFF2B8A0),
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}