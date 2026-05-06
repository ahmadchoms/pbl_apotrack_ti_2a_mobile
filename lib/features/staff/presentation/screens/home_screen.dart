import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/recent_activity_item.dart';
import '../widgets/urgent_task_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // --- DUMMY DATA (API-READY STRUCTURE) ---
  static const Map<String, dynamic> profileResponse = {
    'status': 'success',
    'message': 'Profile retrieved successfully',
    'data': {
      'id': 1,
      'username': 'Ahmad Fauzi',
      'email': 'ahmad.fauzi@example.com',
      'phone': '081234567890',
      'role': 'STAFF',
      'is_active': true,
      'avatar_url': null,
      'pharmacy_name': 'Apotek Jaya Farma',
      'pharmacy_id': 10,
      'created_at': '2026-01-01T10:00:00Z',
    }
  };

  static const Map<String, dynamic> todayStats = {
    'total_orders': 12,
    'pending_orders': 3,
  };

  static const int unreadNotifications = 2;

  static const List<Map<String, dynamic>> urgentTasks = [
    {
      'id': 1,
      'type': 'STOCK',
      'title': 'Stok Paracetamol Menipis',
      'subtitle': 'Sisa 5 Strip di gudang',
    },
    {
      'id': 2,
      'type': 'ORDER',
      'title': 'Ada 2 Pesanan Baru',
      'subtitle': 'Menunggu konfirmasi Anda',
    },
  ];

  static const List<Map<String, dynamic>> recentActivities = [
    {
      'id': 1,
      'action': 'Update Stok',
      'description': 'Update stok Amoxicillin oleh Budi (Staff)',
      'status': 'success',
      'created_at': '2026-05-06 07:25:00',
      'relative_time': '10 Menit lalu',
    },
    {
      'id': 2,
      'action': 'Pesanan Selesai',
      'description': 'Pesanan #ORD-0917 telah diserahkan',
      'status': 'success',
      'created_at': '2026-05-06 06:35:00',
      'relative_time': '1 Jam lalu',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final userData = profileResponse['data'] as Map<String, dynamic>;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${userData['username'].toString().split(' ')[0]}!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userData['pharmacy_name'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      _buildNotificationBadge(unreadNotifications, context),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _buildSummaryItem(
                        'Pesanan Hari Ini', 
                        todayStats['total_orders'].toString()
                      ),
                      const SizedBox(width: 16),
                      _buildSummaryItem(
                        'Perlu Diproses', 
                        todayStats['pending_orders'].toString(), 
                        isWarning: true
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- QUICK ACTIONS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Scan QR\nCustomer',
                      Icons.qr_code_scanner_rounded,
                      AppColors.primary,
                      Colors.white,
                      true,
                      () => context.push('/staff/scanner'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      'POS /\nKasir',
                      Icons.point_of_sale_rounded,
                      Colors.white,
                      AppColors.primary,
                      false,
                      () => context.push('/staff/pos'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- URGENT TASKS SECTION ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'TINDAKAN DIPERLUKAN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textLight,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: urgentTasks.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final task = urgentTasks[index];
                  final isStock = task['type'] == 'STOCK';
                  return UrgentTaskCard(
                    title: task['title'],
                    subtitle: task['subtitle'],
                    icon: isStock ? Icons.warning_amber_rounded : Icons.shopping_cart_outlined,
                    color: isStock ? AppColors.warning : AppColors.primary,
                    onTap: () {
                      if (isStock) {
                        context.push('/staff/inventory');
                      } else {
                        context.push('/staff/orders');
                      }
                    },
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // --- RECENT ACTIVITY SECTION ---
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'AKTIVITAS TERAKHIR',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textLight,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: recentActivities.length,
              itemBuilder: (context, index) {
                final activity = recentActivities[index];
                return RecentActivityItem(
                  activity: activity,
                  onTap: () => context.push('/staff/audit-log-detail', extra: activity),
                );
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationBadge(int count, BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/staff/notifications'),
      child: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Colors.white),
          ),
          if (count > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isWarning = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: isWarning ? AppColors.accentOrange : Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color bgColor, Color textColor, bool isSolid, VoidCallback onTap) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        border: isSolid ? null : Border.all(color: textColor.withOpacity(0.2), width: 2),
        boxShadow: isSolid ? [
          BoxShadow(
            color: bgColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: textColor, size: 32),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
