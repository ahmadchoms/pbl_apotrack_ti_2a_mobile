import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import 'home_screen.dart';
import 'notification.dart';
import 'customer_profile_screen.dart';
import 'order_history_screen.dart';
import 'scanner_screen.dart';
import 'scan_result.dart';

class CustomerMainScreen extends ConsumerStatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  ConsumerState<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends ConsumerState<CustomerMainScreen> {
  int _currentIndex = 0;
  int _unreadNotifCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final dio = ref.read(dioProvider);
      final service = NotificationService(dio);
      final data = await service.getNotifications();
      if (mounted) {
        final models = data.map((e) => NotificationModel.fromJson(e)).toList();
        setState(() => _unreadNotifCount = models.where((n) => !n.isRead).length);
      }
    } catch (_) {}
  }

  final List<Widget> _screens = [
    const CustomerHomeScreen(),
    const NotificationScreen(showBack: false),
    const OrderHistoryScreen(),
    const AccountHubScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _buildFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Future<void> _onScan() async {
    HapticFeedback.mediumImpact();
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
    );
    if (code == null || !mounted) return;

    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/orders/$code');
      final order = response.data['data'] as Map<String, dynamic>;
      final rawItems = order['items'] as List<dynamic>? ?? [];
      final items = rawItems.map((e) {
        final item = e as Map<String, dynamic>;
        final medicine = item['medicine'] as Map<String, dynamic>?;
        return ScannedItem(
          name: item['medicine_name'] as String? ?? '',
          quantity: item['quantity'] as int? ?? 0,
          unit: medicine?['unit'] as String? ?? 'pcs',
          pricePerUnit: (item['price'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScanResultScreen(
              scanCode: code,
              items: items.isNotEmpty ? items : const [
                ScannedItem(name: 'Tidak ada item ditemukan', quantity: 0, unit: '', pricePerUnit: 0),
              ],
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data pesanan')),
        );
      }
    }
  }

  Widget _buildFloatingButton() {
    return GestureDetector(
      onTap: _onScan,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      elevation: 0,
      padding: EdgeInsets.zero,
      color: Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Beranda'),
                _navItem(1, Icons.notifications_rounded,
                    Icons.notifications_none_rounded, 'Notifikasi'),
                const SizedBox(width: 60),
                _navItem(2, Icons.assignment_rounded, Icons.assignment_outlined, 'Riwayat'),
                _navItem(3, Icons.person_rounded,
                    Icons.person_outline_rounded, 'Profil'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData activeIcon, IconData inactiveIcon,
      String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? AppColors.primary : AppColors.textLight,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
