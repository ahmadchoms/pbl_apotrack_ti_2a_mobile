import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/recent_activity_item.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  // Dummy activity data for the user
  static const List<Map<String, dynamic>> _userActivities = [
    {
      'id': 1,
      'action': 'Update Stok',
      'description': 'Update stok Amoxicillin 500mg (+50 unit)',
      'relative_time': '10 Menit lalu',
      'created_at': '2026-05-06 07:25:00',
      'status': 'success',
      'type': 'STOCK',
    },
    {
      'id': 2,
      'action': 'Pesanan Selesai',
      'description': 'Menyelesaikan pesanan #ORD-0917',
      'relative_time': '1 Jam lalu',
      'created_at': '2026-05-06 06:35:00',
      'status': 'success',
      'type': 'ORDER',
    },
    {
      'id': 3,
      'action': 'Login',
      'description': 'Berhasil masuk ke sistem via Mobile',
      'relative_time': '4 Jam lalu',
      'created_at': '2026-05-06 03:35:00',
      'status': 'success',
      'type': 'SYSTEM',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Riwayat Aktivitas',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        itemCount: _userActivities.length,
        itemBuilder: (context, index) {
          final activity = _userActivities[index];
          return RecentActivityItem(
            activity: activity,
            onTap: () => context.push('/staff/audit-log-detail', extra: activity),
          );
        },
      ),
    );
  }
}
