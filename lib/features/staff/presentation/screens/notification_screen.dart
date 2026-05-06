import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // Dummy notifications
  static const List<Map<String, dynamic>> _notifications = [
    {
      'id': 1,
      'title': 'Pesanan Baru Masuk',
      'body': 'Pesanan #ORD-0925 menunggu konfirmasi Anda.',
      'time': '2 Menit lalu',
      'is_read': false,
      'type': 'ORDER',
    },
    {
      'id': 2,
      'title': 'Stok Hampir Habis',
      'body': 'Obat Paracetamol 500mg sisa 5 strip.',
      'time': '1 Jam lalu',
      'is_read': false,
      'type': 'STOCK',
    },
    {
      'id': 3,
      'title': 'Sesi Berakhir',
      'body': 'Sesi login Anda akan berakhir dalam 30 menit.',
      'time': '5 Jam lalu',
      'is_read': true,
      'type': 'SYSTEM',
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
          'Notifikasi',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text('Tandai Dibaca', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 12)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationItem(context, notification);
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Belum ada notifikasi',
            style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, Map<String, dynamic> item) {
    final bool isRead = item['is_read'] ?? true;
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
            // Handle notification tap
            if (item['type'] == 'ORDER') {
              context.push('/staff/orders');
            } else if (item['type'] == 'STOCK') {
              context.push('/staff/inventory');
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getIconBgColor(item['type']),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(item['type']), 
                    color: _getIconColor(item['type']), 
                    size: 20
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['title'],
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight.w700 : FontWeight.w900,
                                fontSize: 14,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['body'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          height: 1.4,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'ORDER': return Icons.shopping_bag_outlined;
      case 'STOCK': return Icons.inventory_2_outlined;
      default: return Icons.info_outline_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'ORDER': return const Color(0xFF1D70F5);
      case 'STOCK': return const Color(0xFFF59E0B);
      default: return const Color(0xFF64748B);
    }
  }

  Color _getIconBgColor(String type) {
    return _getIconColor(type).withOpacity(0.1);
  }
}
