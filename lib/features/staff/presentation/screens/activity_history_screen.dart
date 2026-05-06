import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  // Dummy activity data for the user
  static const List<Map<String, dynamic>> _userActivities = [
    {
      'id': 1,
      'action': 'Update Stok',
      'description': 'Update stok Amoxicillin 500mg (+50 unit)',
      'time': '10 Menit lalu',
      'type': 'STOCK',
    },
    {
      'id': 2,
      'action': 'Pesanan Selesai',
      'description': 'Menyelesaikan pesanan #ORD-0917',
      'time': '1 Jam lalu',
      'type': 'ORDER',
    },
    {
      'id': 3,
      'action': 'Login Berhasil',
      'description': 'Masuk ke sistem ApoTrack Staff',
      'time': '4 Jam lalu',
      'type': 'SYSTEM',
    },
    {
      'id': 4,
      'action': 'Edit Profil',
      'description': 'Memperbarui nomor telepon akun',
      'time': 'Kemarin, 14:20',
      'type': 'SYSTEM',
    },
    {
      'id': 5,
      'action': 'Hapus Produk',
      'description': 'Menghapus produk kadaluwarsa: Sirup ABC',
      'time': 'Kemarin, 09:15',
      'type': 'STOCK',
    },
  ];

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1D70F5);
    const Color backgroundColor = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Riwayat Aktivitas',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: _userActivities.length,
        itemBuilder: (context, index) {
          final activity = _userActivities[index];
          return _buildActivityItem(context, activity);
        },
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Map<String, dynamic> item) {
    const Color primaryColor = Color(0xFF1D70F5);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Re-using AuditLogDetailScreen format
            context.push('/staff/audit-log-detail', extra: {
              ...item,
              'user_name': 'Ahmad Setiawan', // Context is user's own history
              'created_at_formatted': item['time'],
            });
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getBgColor(item['type']),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(item['type']), 
                    color: _getColor(item['type']), 
                    size: 20
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['action'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['description'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['time'],
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'STOCK': return Icons.inventory_2_outlined;
      case 'ORDER': return Icons.shopping_bag_outlined;
      default: return Icons.person_outline_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case 'STOCK': return const Color(0xFF1D70F5);
      case 'ORDER': return const Color(0xFF10B981);
      default: return const Color(0xFF64748B);
    }
  }

  Color _getBgColor(String type) {
    return _getColor(type).withOpacity(0.1);
  }
}
