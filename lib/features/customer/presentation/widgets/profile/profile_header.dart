import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';

class ProfileHeader extends StatelessWidget {
  final String name;
  final String phone;
  final String email;
  final String initials;
  final String? avatarUrl;

  const ProfileHeader({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.initials,
    this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
          top: 80, bottom: 40, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.surfaceLight,
            backgroundImage: avatarUrl != null
                ? NetworkImage(avatarUrl!)
                : null,
            child: avatarUrl == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            phone,
            style: const TextStyle(
              color: AppColors.textSlate,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            email,
            style: const TextStyle(
              color: AppColors.textSlate,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}