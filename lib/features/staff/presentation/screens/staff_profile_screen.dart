import 'package:flutter/material.dart';

class StaffProfileScreen extends StatelessWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1D70F5);
    const Color backgroundColor = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- PROFILE HEADER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 40, left: 24, right: 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFFF1F5F9),
                    child: Text(
                      'AS',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Ahmad Setiawan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Kepala Apoteker',
                          style: TextStyle(color: primaryColor, fontSize: 11, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Apotek Jaya Farma Center',
                    style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- MENU GROUPS ---
            _buildMenuSection('PENGATURAN AKUN', [
              _buildMenuItem(Icons.person_outline_rounded, 'Edit Profil'),
              _buildMenuItem(Icons.lock_outline_rounded, 'Ubah Password'),
            ]),

            _buildMenuSection('OPERASIONAL APOTEK', [
              _buildMenuItem(Icons.bar_chart_rounded, 'Laporan Shift / Kasir'),
              _buildMenuItem(Icons.print_outlined, 'Pengaturan Printer Struk'),
              _buildMenuItem(Icons.history_rounded, 'Riwayat Aktivitas Stok'),
            ]),

            _buildMenuSection('LAINNYA', [
              _buildMenuItem(Icons.help_outline_rounded, 'Pusat Bantuan'),
              _buildMenuItem(Icons.logout_rounded, 'Keluar / Logout', isDestructive: true),
            ]),

            const SizedBox(height: 40),
            const Text(
              'ApoTrack Staff v1.0.2',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
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
            child: Column(
              children: items,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {bool isDestructive = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF64748B),
        size: 22,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDestructive ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDestructive ? const Color(0xFFEF4444).withOpacity(0.3) : const Color(0xFFCBD5E1),
      ),
      onTap: () {},
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
