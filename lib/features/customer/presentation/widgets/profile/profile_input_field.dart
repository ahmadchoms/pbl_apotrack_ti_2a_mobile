import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class ProfileInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType keyboardType;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const ProfileInputField({
    super.key,
    required this.label,
    required this.controller,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasError = errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: hasError ? AppColors.danger : AppColors.textSlate,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasError ? AppColors.danger : AppColors.surfaceLight,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              prefixIcon: Icon(
                icon,
                color: hasError ? AppColors.danger : AppColors.textMuted,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 13,
                  color: AppColors.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  errorText!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}