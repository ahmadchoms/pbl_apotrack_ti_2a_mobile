import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../widgets/medicine_inventory_card.dart';

class StaffInventoryScreen extends StatefulWidget {
  const StaffInventoryScreen({super.key});

  @override
  State<StaffInventoryScreen> createState() => _StaffInventoryScreenState();
}

class _StaffInventoryScreenState extends State<StaffInventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'Semua';
  List<Map<String, dynamic>> _filtered = _medicines;

  final _filters = ['Semua', 'Stok Kritis', 'Stok Rendah', 'Normal'];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _medicines.where((m) {
        final matchSearch =
            m['name'].toString().toLowerCase().contains(q) ||
            (m['category']?.toString().toLowerCase().contains(q) ?? false);
        
        final stock = m['total_active_stock'] as int;
        final isCritical = stock <= 10;
        final isLow = stock <= 20;

        final matchFilter = switch (_selectedFilter) {
          'Stok Kritis' => isCritical,
          'Stok Rendah' => isLow && !isCritical,
          'Normal' => !isLow,
          _ => true,
        };
        return matchSearch && matchFilter;
      }).toList();
    });
  }

  int get _lowStockCount => _medicines.where((m) => (m['total_active_stock'] as int) <= 20).length;
  int get _criticalCount => _medicines.where((m) => (m['total_active_stock'] as int) <= 10).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(),
          if (_criticalCount > 0 || _lowStockCount > 0) _buildAlertBanner(),
          _buildSearchAndFilter(),
          _buildStatRow(),
          Expanded(child: _buildList()),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(color: AppColors.primary),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stok Obat',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    '${_medicines.length} produk terdaftar',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              _buildHeaderIcon(Icons.filter_list_rounded, () {
                _showFilterSheet(context);
              }),
              const SizedBox(width: 8),
              _buildHeaderIcon(Icons.sort_rounded, () {}),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, VoidCallback onTap) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 18),
        onPressed: onTap,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildAlertBanner() {
    final isCritical = _criticalCount > 0;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = isCritical ? 'Stok Kritis' : 'Stok Rendah');
        _applyFilter();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isCritical ? AppColors.dangerLight : AppColors.warningLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCritical
                ? AppColors.danger.withOpacity(0.3)
                : AppColors.warning.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: (isCritical ? AppColors.danger : AppColors.warning).withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isCritical ? AppColors.danger : AppColors.warning).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCritical ? Icons.error_outline_rounded : Icons.warning_amber_rounded,
                color: isCritical ? AppColors.danger : AppColors.warning,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCritical ? 'TINDAKAN DIPERLUKAN' : 'PERINGATAN STOK',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isCritical ? AppColors.danger : AppColors.warning,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCritical
                        ? '$_criticalCount produk hampir habis! Ketuk untuk lihat.'
                        : '$_lowStockCount produk stok rendah. Perlu perhatian.',
                    style: TextStyle(
                      color: isCritical ? AppColors.danger : AppColors.warning,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isCritical ? AppColors.danger : AppColors.warning),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cari nama obat atau kategori...',
                hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _applyFilter();
                        },
                        child: const Icon(Icons.close_rounded, color: AppColors.textLight, size: 18),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _buildFilterChip(_filters[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    Color chipColor = AppColors.primary;
    if (filter == 'Stok Kritis') chipColor = AppColors.danger;
    else if (filter == 'Stok Rendah') chipColor = AppColors.warning;
    else if (filter == 'Normal') chipColor = AppColors.success;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? chipColor : AppColors.divider, width: 1.5),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textMid,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          Text(
            '${_filtered.length} produk',
            style: const TextStyle(fontSize: 12, color: AppColors.textLight, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: _filtered.length,
      itemBuilder: (_, i) {
        final med = _filtered[i];
        return MedicineInventoryCard(
          medicine: med,
          onTap: () => context.push(AppRouter.staffMedicineDetail, extra: med),
          onEdit: () => context.push(AppRouter.staffMedicineForm, extra: med),
          formatRupiah: _formatRupiah,
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Filter Produk',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _filters.map((f) => _buildFilterChip(f)).toList(),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Terapkan Filter',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return FloatingActionButton.extended(
      onPressed: () => context.push(AppRouter.staffMedicineForm),
      backgroundColor: AppColors.primary,
      icon: const Icon(Icons.add_rounded, color: Colors.white),
      label: const Text('Tambah Produk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
    );
  }
}

// Dummy Data
final List<Map<String, dynamic>> _medicines = [
  {
    'id': 1,
    'name': 'Amoxicillin 500mg',
    'category': 'Antibiotik',
    'form': 'Kapsul',
    'unit': 'Strip',
    'price': 15000,
    'total_active_stock': 45,
    'accentColor': const Color(0xFF6366F1),
    'icon': Icons.local_pharmacy_rounded,
  },
  {
    'id': 2,
    'name': 'Paracetamol 500mg',
    'category': 'Analgesik',
    'form': 'Tablet',
    'unit': 'Pcs',
    'price': 2500,
    'total_active_stock': 8,
    'accentColor': const Color(0xFF10B981),
    'icon': Icons.medication_rounded,
  },
  {
    'id': 3,
    'name': 'OBH Combi Anak',
    'category': 'Ekspektoran',
    'form': 'Sirup',
    'unit': 'Botol',
    'price': 18500,
    'total_active_stock': 22,
    'accentColor': const Color(0xFFF59E0B),
    'icon': Icons.water_drop_rounded,
  },
];

String _formatRupiah(num value) {
  final str = value.toStringAsFixed(0);
  final buf = StringBuffer();
  final len = str.length;
  for (int i = 0; i < len; i++) {
    if (i > 0 && (len - i) % 3 == 0) buf.write('.');
    buf.write(str[i]);
  }
  return 'Rp ${buf.toString()}';
}
