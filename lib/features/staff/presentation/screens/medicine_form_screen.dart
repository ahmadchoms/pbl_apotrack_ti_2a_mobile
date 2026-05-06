import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/medicine_form/medicine_form_card.dart';
import '../widgets/medicine_form/medicine_form_fields.dart';
import '../widgets/medicine_form/medicine_form_batch.dart';

class MedicineFormScreen extends StatefulWidget {
  final Map<String, dynamic>? medicine;
  const MedicineFormScreen({super.key, this.medicine});

  @override
  State<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends State<MedicineFormScreen>
    with SingleTickerProviderStateMixin {
  late bool isEdit;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _genericNameCtrl = TextEditingController();
  final _manufacturerCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();

  // Selections
  String? _category;
  String? _type;
  String? _form;
  String? _unit;
  bool _requiresPrescription = false;
  bool _isActive = true;

  // Batches
  final List<Map<String, dynamic>> _batches = [];

  // Options (from API in real app)
  final _categories = [
    'Antibiotik',
    'Analgesik',
    'Ekspektoran',
    'Antiseptik',
    'Suplemen',
    'Antasida',
  ];
  final _types = ['Tablet', 'Pcs', 'Botol 60ml', 'Botol 15ml', 'Strip isi 10'];
  final _forms = ['Kapsul', 'Tablet', 'Sirup', 'Cairan', 'Salep', 'Krim'];
  final _units = ['Strip', 'Botol', 'Box', 'Tube', 'Pcs'];

  // Animation
  late AnimationController _headerAnimCtrl;

  @override
  void initState() {
    super.initState();
    _headerAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    isEdit = widget.medicine != null;
    if (isEdit) {
      final m = widget.medicine!;
      _nameCtrl.text = m['name'] ?? '';
      _genericNameCtrl.text = m['generic_name'] ?? '';
      _manufacturerCtrl.text = m['manufacturer'] ?? '';
      _priceCtrl.text = m['price']?.toString() ?? '';
      _weightCtrl.text = m['weight_in_grams']?.toString() ?? '';
      _descCtrl.text = m['description'] ?? '';
      _dosageCtrl.text = m['dosage_info'] ?? '';
      _category = m['category'];
      _type = m['type'];
      _form = m['form'];
      _unit = m['unit'];
      _requiresPrescription = m['requires_prescription'] ?? false;
      _isActive = m['is_active'] ?? true;

      if (m['batches'] != null) {
        for (var b in (m['batches'] as List)) {
          _batches.add(Map<String, dynamic>.from(b));
        }
      }
    } else {
      _addBatch();
    }
  }

  @override
  void dispose() {
    _headerAnimCtrl.dispose();
    _nameCtrl.dispose();
    _genericNameCtrl.dispose();
    _manufacturerCtrl.dispose();
    _priceCtrl.dispose();
    _weightCtrl.dispose();
    _descCtrl.dispose();
    _dosageCtrl.dispose();
    super.dispose();
  }

  void _addBatch() {
    HapticFeedback.lightImpact();
    setState(() => _batches.add({'number': '', 'exp': '', 'stock': ''}));
  }

  void _removeBatch(int index) {
    HapticFeedback.lightImpact();
    setState(() => _batches.removeAt(index));
  }

  // ── BUILD ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildSliverHeader(context),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildImageUpload(),
                    const SizedBox(height: 16),
                    _buildInfoSection(),
                    const SizedBox(height: 16),
                    _buildPriceSection(),
                    const SizedBox(height: 16),
                    _buildBatchSection(),
                    const SizedBox(height: 16),
                    _buildDescSection(),
                  ]),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildSaveBar(context),
          ),
        ],
      ),
    );
  }

  // ── SLIVER HEADER ─────────────────────────────
  Widget _buildSliverHeader(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      backgroundColor: AppColors.primary,
      leading: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
      actions: [
        if (isEdit)
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () => _showDeleteConfirm(context),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isEdit ? 'EDIT DATA OBAT' : 'TAMBAH OBAT BARU',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEdit
                        ? (widget.medicine?['name'] ?? 'Edit Obat')
                        : 'Tambah Produk Baru',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text(
        isEdit ? 'Edit Obat' : 'Tambah Obat',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 17,
        ),
      ),
    );
  }

  // ── IMAGE UPLOAD ──────────────────────────────
  Widget _buildImageUpload() {
    return MedicineFormCard(
      child: GestureDetector(
        onTap: () => HapticFeedback.lightImpact(),
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_photo_alternate_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Upload Foto Obat',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _metaBadge('JPG'),
                  const SizedBox(width: 5),
                  _metaBadge('PNG'),
                  const SizedBox(width: 5),
                  _metaBadge('Max 2MB'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaBadge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.primaryLight,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    ),
  );

  // ── SECTION: INFORMASI UMUM ───────────────────
  Widget _buildInfoSection() {
    return MedicineFormCard(
      header: const MedicineFormSectionHeader(
        icon: Icons.medication_rounded,
        iconColor: AppColors.primary,
        iconBg: AppColors.primaryLight,
        title: 'Informasi Umum',
      ),
      child: Column(
        children: [
          MedicineFormField(
            label: 'Nama Obat',
            controller: _nameCtrl,
            hint: 'Contoh: Amoxicillin 500mg',
            required: true,
            prefixIcon: Icons.local_pharmacy_rounded,
          ),
          MedicineFormField(
            label: 'Nama Generik',
            controller: _genericNameCtrl,
            hint: 'Contoh: Amoxicillin Trihydrate',
            prefixIcon: Icons.science_outlined,
          ),
          MedicineFormRow(
            left: MedicineFormDropdown(
              label: 'Kategori',
              value: _category,
              items: _categories,
              onChanged: (v) => setState(() => _category = v),
            ),
            right: MedicineFormDropdown(
              label: 'Sediaan (Form)',
              value: _form,
              items: _forms,
              onChanged: (v) => setState(() => _form = v),
            ),
          ),
          const SizedBox(height: 4),
          MedicineFormRow(
            left: MedicineFormDropdown(
              label: 'Satuan',
              value: _unit,
              items: _units,
              onChanged: (v) => setState(() => _unit = v),
            ),
            right: MedicineFormDropdown(
              label: 'Tipe Kemasan',
              value: _type,
              items: _types,
              onChanged: (v) => setState(() => _type = v),
            ),
          ),
          const SizedBox(height: 4),
          MedicineFormField(
            label: 'Produsen / Pabrik',
            controller: _manufacturerCtrl,
            hint: 'Contoh: Kimia Farma',
            prefixIcon: Icons.factory_outlined,
          ),
        ],
      ),
    );
  }

  // ── SECTION: HARGA & PENGATURAN ───────────────
  Widget _buildPriceSection() {
    return MedicineFormCard(
      header: const MedicineFormSectionHeader(
        icon: Icons.payments_outlined,
        iconColor: AppColors.success,
        iconBg: AppColors.successLight,
        title: 'Harga & Pengaturan',
      ),
      child: Column(
        children: [
          MedicineFormRow(
            left: MedicineFormField(
              label: 'Harga Jual',
              controller: _priceCtrl,
              hint: '0',
              prefix: 'Rp',
              keyboard: TextInputType.number,
              required: true,
            ),
            right: MedicineFormField(
              label: 'Berat (gram)',
              controller: _weightCtrl,
              hint: '0',
              prefixIcon: Icons.scale_outlined,
              keyboard: TextInputType.number,
            ),
          ),
          const SizedBox(height: 8),
          MedicineFormSwitch(
            title: 'Butuh Resep Dokter',
            subtitle: 'Hanya bisa dibeli dengan resep',
            value: _requiresPrescription,
            onChanged: (v) => setState(() => _requiresPrescription = v),
            icon: Icons.description_outlined,
            activeColor: AppColors.accentOrange,
            activeBg: AppColors.accentOrange.withOpacity(0.1),
          ),
          MedicineFormSwitch(
            title: 'Status Aktif',
            subtitle: 'Tampil di katalog & bisa dipesan',
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
            icon: Icons.visibility_outlined,
            activeColor: AppColors.success,
            activeBg: AppColors.successLight,
          ),
        ],
      ),
    );
  }

  // ── SECTION: BATCH & STOK ─────────────────────
  Widget _buildBatchSection() {
    return MedicineFormCard(
      header: MedicineFormSectionHeader(
        icon: Icons.inventory_2_outlined,
        iconColor: AppColors.warning,
        iconBg: AppColors.warningLight,
        title: 'Batch & Stok',
        trailing: GestureDetector(
          onTap: _addBatch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: AppColors.primary, size: 14),
                SizedBox(width: 4),
                Text(
                  'Tambah Batch',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      child: Column(
        children: _batches.asMap().entries.map((entry) {
          final i = entry.key;
          final batch = entry.value;
          return MedicineFormBatchCard(
            index: i,
            batch: batch,
            canDelete: _batches.length > 1,
            onDelete: () => _removeBatch(i),
            onChanged: (field, value) =>
                setState(() => _batches[i][field] = value),
          );
        }).toList(),
      ),
    );
  }

  // ── SECTION: DESKRIPSI & DOSIS ────────────────
  Widget _buildDescSection() {
    return MedicineFormCard(
      header: const MedicineFormSectionHeader(
        icon: Icons.menu_book_outlined,
        iconColor: AppColors.accentPurple,
        iconBg: Color(0xFFF5F3FF),
        title: 'Deskripsi & Dosis',
      ),
      child: Column(
        children: [
          MedicineFormField(
            label: 'Deskripsi Obat',
            controller: _descCtrl,
            hint: 'Jelaskan kegunaan dan indikasi utama obat...',
            maxLines: 3,
            prefixIcon: Icons.info_outline_rounded,
          ),
          MedicineFormField(
            label: 'Petunjuk Dosis',
            controller: _dosageCtrl,
            hint: 'Contoh: Dewasa 3x1 tablet sehari sesudah makan',
            maxLines: 2,
            prefixIcon: Icons.format_list_numbered_rounded,
          ),
        ],
      ),
    );
  }

  // ── SAVE BAR ──────────────────────────────────
  Widget _buildSaveBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textMid,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.heavyImpact();
                    context.pop();
                  },
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'Simpan Perubahan' : 'Simpan Obat Baru',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '${_batches.length} batch · ${_nameCtrl.text.isEmpty ? "Belum ada nama" : _nameCtrl.text}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DELETE CONFIRM ────────────────────────────
  void _showDeleteConfirm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hapus Data Obat?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tindakan ini tidak bisa dibatalkan. Semua data batch yang terkait juga akan ikut dihapus.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textLight,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMid,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      context.pop();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'Ya, Hapus',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
