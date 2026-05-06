import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class _C {
  static const primary = Color(0xFF1D70F5);
  static const primaryLight = Color(0xFFEEF4FF);
  static const bg = Color(0xFFF4F7FE);
  static const surface = Colors.white;
  static const textDark = Color(0xFF0F1828);
  static const textMid = Color(0xFF4B5563);
  static const textLight = Color(0xFF9CA3AF);
  static const divider = Color(0xFFE5EAF2);
  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFFFBEB);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEF2F2);
}

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

//  MODEL — field names match Laravel API response
class _MedItem {
  final int id;
  final String name;
  final String? genericName; // generic_name
  final double price;
  final bool requiresPrescription; // requires_prescription
  final bool isActive; // is_active
  final String? category; // category.name
  final String? form; // form.name  (Tablet, Kapsul, Sirup…)
  final String? type; // type.name  (Strip isi 10, Botol 60ml…)
  final String? unit; // unit.name  (Pcs, Strip, Botol…)
  final String? imageUrl; // image_url
  final int totalActiveStock; // total_active_stock

  // UI helpers — not from API, assigned locally per category
  final Color accentColor;

  const _MedItem({
    required this.id,
    required this.name,
    this.genericName,
    required this.price,
    this.requiresPrescription = false,
    this.isActive = true,
    this.category,
    this.form,
    this.type,
    this.unit,
    this.imageUrl,
    required this.totalActiveStock,
    required this.accentColor,
  });

  // Stock thresholds — replace with real minStock from API if available
  static const int _lowThreshold = 20;
  static const int _criticalThreshold = 10;

  bool get isLow => totalActiveStock <= _lowThreshold;
  bool get isCritical => totalActiveStock <= _criticalThreshold;

  // Progress bar ratio — caps at 1.0 using 3× low threshold as "full"
  double get stockRatio =>
      (totalActiveStock / (_lowThreshold * 3)).clamp(0.0, 1.0);
}

//  DUMMY DATA — mirrors Laravel toArray() shape
final List<_MedItem> _medicines = [
  _MedItem(
    id: 1,
    name: 'Amoxicillin 500mg',
    genericName: 'Amoxicillin',
    price: 15000,
    requiresPrescription: true,
    category: 'Antibiotik',
    form: 'Kapsul',
    type: 'Strip isi 10',
    unit: 'Strip',
    totalActiveStock: 45,
    accentColor: Color(0xFF6366F1),
  ),
  _MedItem(
    id: 2,
    name: 'Paracetamol 500mg',
    genericName: 'Paracetamol',
    price: 2500,
    category: 'Analgesik',
    form: 'Tablet',
    type: 'Pcs',
    unit: 'Pcs',
    totalActiveStock: 8,
    accentColor: Color(0xFF10B981),
  ),
  _MedItem(
    id: 3,
    name: 'OBH Combi Anak',
    genericName: 'Succus Liquiritiae',
    price: 18500,
    category: 'Ekspektoran',
    form: 'Sirup',
    type: 'Botol 60ml',
    unit: 'Botol',
    totalActiveStock: 22,
    accentColor: Color(0xFFF59E0B),
  ),
  _MedItem(
    id: 4,
    name: 'Betadine Antiseptik',
    genericName: 'Povidone Iodine',
    price: 22000,
    category: 'Antiseptik',
    form: 'Cairan',
    type: 'Botol 15ml',
    unit: 'Botol',
    totalActiveStock: 4,
    accentColor: Color(0xFFEF4444),
  ),
  _MedItem(
    id: 5,
    name: 'Vitamin C 500mg',
    genericName: 'Ascorbic Acid',
    price: 5000,
    category: 'Suplemen',
    form: 'Tablet',
    type: 'Strip isi 10',
    unit: 'Strip',
    totalActiveStock: 80,
    accentColor: Color(0xFFEC4899),
  ),
  _MedItem(
    id: 6,
    name: 'Antasida Doen',
    genericName: 'Al. Hidroksida + Mg. Hidroksida',
    price: 4500,
    category: 'Antasida',
    form: 'Tablet',
    type: 'Strip isi 10',
    unit: 'Strip',
    totalActiveStock: 33,
    accentColor: Color(0xFF8B5CF6),
  ),
];

class StaffInventoryScreen extends StatefulWidget {
  const StaffInventoryScreen({super.key});

  @override
  State<StaffInventoryScreen> createState() => _StaffInventoryScreenState();
}

class _StaffInventoryScreenState extends State<StaffInventoryScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedFilter = 'Semua';
  List<_MedItem> _filtered = _medicines;

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
            m.name.toLowerCase().contains(q) ||
            (m.genericName?.toLowerCase().contains(q) ?? false) ||
            (m.category?.toLowerCase().contains(q) ?? false) ||
            (m.form?.toLowerCase().contains(q) ?? false);
        final matchFilter = switch (_selectedFilter) {
          'Stok Kritis' => m.isCritical,
          'Stok Rendah' => m.isLow && !m.isCritical,
          'Normal' => !m.isLow,
          _ => true,
        };
        return matchSearch && matchFilter;
      }).toList();
    });
  }

  int get _lowStockCount => _medicines.where((m) => m.isLow).length;
  int get _criticalCount => _medicines.where((m) => m.isCritical).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.bg,
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
      decoration: const BoxDecoration(color: _C.primary),
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
              const Spacer(),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.sort_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => _showCategoryFilter(context),
                  padding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.swap_vert_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  onPressed: () => _showSortOptions(context),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertBanner() {
    final isCritical = _criticalCount > 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isCritical ? _C.dangerLight : _C.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCritical
              ? _C.danger.withOpacity(0.3)
              : _C.warning.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCritical
                ? Icons.error_outline_rounded
                : Icons.warning_amber_rounded,
            color: isCritical ? _C.danger : _C.warning,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCritical
                  ? '$_criticalCount produk hampir habis! Segera restock.'
                  : '$_lowStockCount produk stok rendah. Perlu perhatian.',
              style: TextStyle(
                color: isCritical ? _C.danger : _C.warning,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = isCritical ? 'Stok Kritis' : 'Stok Rendah';
                _applyFilter();
              });
            },
            child: Text(
              'Lihat',
              style: TextStyle(
                color: isCritical ? _C.danger : _C.warning,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
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
              color: _C.surface,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _C.primary.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                fontSize: 14,
                color: _C.textDark,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Cari nama obat atau kategori...',
                hintStyle: const TextStyle(color: _C.textLight, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: _C.primary,
                  size: 20,
                ),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          _applyFilter();
                        },
                        child: const Icon(
                          Icons.close_rounded,
                          color: _C.textLight,
                          size: 18,
                        ),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
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
    Color chipColor = _C.primary;
    Color chipBg = _C.primaryLight;
    if (filter == 'Stok Kritis') {
      chipColor = _C.danger;
      chipBg = _C.dangerLight;
    } else if (filter == 'Stok Rendah') {
      chipColor = _C.warning;
      chipBg = _C.warningLight;
    } else if (filter == 'Normal') {
      chipColor = _C.success;
      chipBg = _C.successLight;
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
        _applyFilter();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : _C.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? chipColor : _C.divider,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : _C.textMid,
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
            style: const TextStyle(
              fontSize: 12,
              color: _C.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (_filtered.length != _medicines.length)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = 'Semua';
                  _searchCtrl.clear();
                });
                _applyFilter();
              },
              child: const Text(
                'Reset filter',
                style: TextStyle(
                  fontSize: 12,
                  color: _C.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: _C.textLight.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada obat ditemukan',
              style: TextStyle(
                color: _C.textLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _MedicineCard(med: _filtered[i]),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/staff/medicine-form');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _C.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _C.primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Tambah Produk',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryFilter(BuildContext context) {
    final categories = [
      'Semua',
      'Tablet',
      'Kapsul',
      'Sirup',
      'Antibiotik',
      'Analgesik',
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Filter Kategori',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _C.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories
                  .map((cat) => _buildCategoryChip(cat))
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return ActionChip(
      label: Text(category),
      onPressed: () => Navigator.pop(context),
      backgroundColor: _C.bg,
      labelStyle: const TextStyle(
        fontWeight: FontWeight.w700,
        color: _C.textMid,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide.none,
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    final options = ['A-Z', 'Z-A', 'Harga Terendah', 'Stok Sedikit'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _C.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Urutkan Obat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: _C.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ...options.map(
              (opt) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.radio_button_off_rounded,
                  color: _C.textLight,
                  size: 20,
                ),
                title: Text(
                  opt,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _C.textDark,
                    fontSize: 14,
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.med});
  final _MedItem med;

  @override
  Widget build(BuildContext context) {
    Color stockColor = _C.success;
    Color stockBg = _C.successLight;
    String stockLabel = 'Normal';
    if (med.isCritical) {
      stockColor = _C.danger;
      stockBg = _C.dangerLight;
      stockLabel = 'Kritis';
    } else if (med.isLow) {
      stockColor = _C.warning;
      stockBg = _C.warningLight;
      stockLabel = 'Rendah';
    }

    return GestureDetector(
      onTap: () => context.push('/staff/medicine-detail', extra: med.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: _C.surface,
          borderRadius: BorderRadius.circular(18),
          border: med.isCritical
              ? Border.all(color: _C.danger.withOpacity(0.22), width: 1.5)
              : med.isLow
              ? Border.all(color: _C.warning.withOpacity(0.22), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: med.isCritical
                  ? _C.danger.withOpacity(0.07)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _MedicineAvatar(med: med),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Name + stock status badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            med.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: _C.textDark,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (med.isCritical || med.isLow) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: stockBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stockLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: stockColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Row 2: Generic name (italic, subtle)
                    if (med.genericName != null)
                      Text(
                        med.genericName!,
                        style: const TextStyle(
                          color: _C.textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 5),

                    // Row 3: Metadata pills — category · form · unit
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (med.category != null)
                          _MetaPill(
                            label: med.category!,
                            color: med.accentColor,
                          ),
                        if (med.form != null) _MetaPill(label: med.form!),
                        if (med.unit != null)
                          _MetaPill(label: '/ ${med.unit!}'),
                        if (med.requiresPrescription)
                          _MetaPill(
                            label: 'Resep',
                            color: const Color(0xFFF97316),
                            icon: Icons.description_outlined,
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Row 5: Price + stock count + edit btn
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          _formatRupiah(med.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: _C.primary,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stockBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${med.totalActiveStock} ${med.unit ?? 'unit'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: stockColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _ActionBtn(
                          icon: Icons.edit_outlined,
                          color: _C.textLight,
                          onTap: () {
                            context.push(
                              '/staff/medicine-form',
                              extra: {
                                'id': med.id,
                                'name': med.name,
                                'generic_name': med.genericName,
                                'category': med.category,
                                'form': med.form,
                                'type': med.type,
                                'unit': med.unit,
                                'price': med.price,
                                'total_active_stock': med.totalActiveStock,
                                'requires_prescription':
                                    med.requiresPrescription,
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineAvatar extends StatelessWidget {
  const _MedicineAvatar({required this.med});
  final _MedItem med;

  // Fallback icon based on form
  IconData get _fallbackIcon {
    switch (med.form?.toLowerCase()) {
      case 'sirup':
      case 'cairan':
        return Icons.water_drop_rounded;
      case 'kapsul':
        return Icons.local_pharmacy_rounded;
      case 'salep':
      case 'krim':
        return Icons.sanitizer_rounded;
      default:
        return Icons.medication_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: med.accentColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: med.imageUrl != null
          ? Image.network(
              med.imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(_fallbackIcon, color: med.accentColor, size: 26),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: med.accentColor,
                        ),
                      ),
                    ),
            )
          : Icon(_fallbackIcon, color: med.accentColor, size: 26),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label, this.color, this.icon});
  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _C.textLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color != null ? c.withOpacity(0.08) : _C.bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: c),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.color,
    this.bgColor,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color? bgColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor ?? _C.bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
