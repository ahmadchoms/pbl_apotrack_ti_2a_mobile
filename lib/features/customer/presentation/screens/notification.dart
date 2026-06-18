import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/models/notification_model.dart';
import '../../data/services/notification_service.dart';
import 'order_detail_screen.dart';
import 'order_history_screen.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  final bool showBack;

  const NotificationScreen({super.key, this.showBack = true});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  late final NotificationService _notificationService;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(ref.read(dioProvider));
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final data = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = data
              .map((e) => NotificationModel.fromJson(e))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Tambahkan feedback jika error (optional)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal memuat notifikasi: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.showBack
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textDark,
                  size: 18,
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notif = _notifications[index];
                  // Oper objek NotificationModel ke item builder
                  return _buildNotificationItem(context, notif);
                },
              ),
            ),
    );
  }

  // UPDATE: Parameter menggunakan NotificationModel
  Widget _buildNotificationItem(BuildContext context, NotificationModel notif) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleNotificationTap(context, notif),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getIconBgColor(notif.type),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getIcon(notif.type),
                    color: _getIconColor(notif.type),
                    size: 20,
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
                              notif.title, // Pakai notif.title
                              style: TextStyle(
                                fontWeight: notif.isRead
                                    ? FontWeight.w700
                                    : FontWeight.w900,
                                fontSize: 14,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.message, // Pakai notif.message
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(
                          notif.createdAt,
                        ), // Gunakan DateTime dari model
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

  void _handleNotificationTap(BuildContext context, NotificationModel notif) {
    if (!notif.isRead) {
      _notificationService.markAsRead(notif.id);
      setState(() {
        notif = NotificationModel(
          id: notif.id,
          title: notif.title,
          message: notif.message,
          type: notif.type,
          isRead: true,
          referenceId: notif.referenceId,
          createdAt: notif.createdAt,
        );
        final index = _notifications.indexWhere((n) => n.id == notif.id);
        if (index != -1) _notifications[index] = notif;
      });
    }
    if (notif.referenceId != null && notif.referenceId!.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CustomerOrderDetailScreen(orderId: notif.referenceId!),
        ),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_rounded,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada notifikasi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda akan melihat notifikasi di sini',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIconBgColor(String type) {
    switch (type) {
      case 'ORDER':
        return AppColors.primary.withValues(alpha: 0.1);
      case 'SYSTEM':
        return Colors.orange.withValues(alpha: 0.1);
      case 'PROMO':
        return Colors.purple.withValues(alpha: 0.1);
      default:
        return Colors.blue.withValues(alpha: 0.1);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'ORDER':
        return Icons.shopping_bag_rounded;
      case 'SYSTEM':
        return Icons.info_rounded;
      case 'PROMO':
        return Icons.discount_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'ORDER':
        return AppColors.primary;
      case 'SYSTEM':
        return Colors.orange;
      case 'PROMO':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  // Update format time agar menerima DateTime
  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${diff.inDays} hari lalu';
  }
}
