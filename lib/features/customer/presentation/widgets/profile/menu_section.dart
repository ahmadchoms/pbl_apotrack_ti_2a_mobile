import 'package:flutter/material.dart';

class MenuSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const MenuSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(children: items),
          ),
        ],
      ),
    );
  }
}

// ── Menu Item standar ─────────────────────────────
class MenuItemTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const MenuItemTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive
            ? const Color(0xFFEF4444)
            : const Color(0xFF64748B),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDestructive
              ? const Color(0xFFEF4444)
              : const Color(0xFF1E293B),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDestructive
            ? const Color(0xFFEF4444).withOpacity(0.3)
            : const Color(0xFFCBD5E1),
      ),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}

// ── Menu Item custom (untuk widget khusus) ────────
class MenuItemCustom extends StatelessWidget {
  final Widget child;

  const MenuItemCustom({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: child,
    );
  }
}