import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/staff_provider.dart';
import 'home_screen.dart';
import 'staff_orders_screen.dart';
import 'staff_inventory_screen.dart';
import 'staff_profile_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(staffTabIndexProvider.notifier).state = widget.initialIndex;
    });
  }

  final List<Widget> _screens = const [
    HomeScreen(),
    StaffOrdersScreen(),
    StaffInventoryScreen(),
    StaffProfileScreen(),
  ];

  void _onItemTapped(int index) {
    ref.read(staffTabIndexProvider.notifier).state = index;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(staffTabIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: selectedIndex, children: _screens),
      bottomNavigationBar: _buildCustomBottomNav(selectedIndex),
    );
  }

  Widget _buildCustomBottomNav(int selectedIndex) {
    return Container(
      height: 85,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, selectedIndex, Icons.grid_view_rounded, 'Beranda'),
          _buildNavItem(1, selectedIndex, Icons.shopping_bag_outlined, 'Pesanan'),
          _buildNavItem(2, selectedIndex, Icons.inventory_2_outlined, 'Obat'),
          _buildNavItem(3, selectedIndex, Icons.person_outline_rounded, 'Profil'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, int selectedIndex, IconData icon, String label) {
    final bool isActive = selectedIndex == index;
    const Color primaryColor = AppColors.primary;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? primaryColor : Colors.grey[400], size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive ? primaryColor : Colors.grey[400],
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
