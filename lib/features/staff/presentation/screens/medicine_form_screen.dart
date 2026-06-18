import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/medicine_form/medicine_form_card.dart';
import '../widgets/medicine_form/medicine_form_fields.dart';
import '../widgets/medicine_form/medicine_form_batch.dart';
import '../../data/models/medicine.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/staff_provider.dart';
import '../../data/services/staff_service.dart';
import '../../../../shared/widgets/app_button.dart';

class MedicineFormScreen extends ConsumerStatefulWidget {
  final Medicine? medicine;
  const MedicineFormScreen({super.key, this.medicine});

  @override
  ConsumerState<MedicineFormScreen> createState() => _MedicineFormScreenState();
}

class _MedicineFormScreenState extends ConsumerState<MedicineFormScreen>
    with SingleTickerProviderStateMixin {
  late bool isEdit;
  XFile? _pickedFile;
  bool _isSaving = false;
  final _picker = ImagePicker();

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

  // Batches (Temporary storage as Map for form logic)
  final List<Map<String, dynamic>> _batches = [];

  // Options (from API in real app)
  final _categories = [
    'Antibiotik',
    'Analgesik',
    'Antipiretik',
    'Antihipertensi',
    'Antidiabetes',
    'Vitamin & Suplemen',
    'Antihistamin',
    'Antasida & GERD',
    'Batuk & Flu',
    'P3K & Antiseptik',
    'Kesehatan Mata',
    'Ibu & Bayi',
  ];
  final _types = [
    'Obat Bebas',
    'Obat Bebas Terbatas',
    'Obat Wajib Apotek',
    'Obat Keras',
    'Alat Kesehatan',
    'Herbal',
  ];
  final _forms = [
    'Tablet',
    'Kapsul',
    'Sirup',
    'Suspensi',
    'Tetes (mata/telinga)',
    'Salep / Krim',
    'Injeksi',
    'Botol',
    'Sachet',
  ];
  final _units = ['Strip', 'Box', 'Botol', 'Tube', 'Pcs', 'Sachet'];

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
      _nameCtrl.text = m.name;
      _genericNameCtrl.text = m.genericName ?? '';
      _manufacturerCtrl.text = m.manufacturer ?? '';
      _priceCtrl.text = m.price.toString();
      _weightCtrl.text = m.weightInGrams?.toString() ?? '';
      _descCtrl.text = m.description ?? '';
      _dosageCtrl.text = m.dosage ?? '';
      _category = m.category;
      _type = m.type;
      _form = m.form;
      _unit = m.unit;
      _requiresPrescription = m.requiresPrescription;
      _isActive = m.isActive;

      // Handle missing categories/types in lists to avoid Dropdown error
      if (_category != null && !_categories.contains(_category)) {
        _categories.add(_category!);
      }
      if (_type != null && !_types.contains(_type)) {
        _types.add(_type!);
      }
      if (_form != null && !_forms.contains(_form)) {
        _forms.add(_form!);
      }
      if (_unit != null && !_units.contains(_unit)) {
        _units.add(_unit!);
      }

      // Load existing batches into the form
      if (m.batches != null && m.batches!.isNotEmpty) {
        for (final b in m.batches!) {
          _batches.add({
            'id':
                b['id'], // Simpan ID agar Laravel tahu ini update batch lama, bukan buat baru
            'number': b['batch_number'],
            'exp': b['expired_date']?.toString().split(
              ' ',
            )[0], // Ambil format YYYY-MM-DD saja
            'stock': b['stock'].toString(),
          });
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

  Future<void> _pickImage() async {
    HapticFeedback.mediumImpact();
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (picked != null) {
        setState(() => _pickedFile = picked);
        ref.invalidate(staffMedicinesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _saveMedicine() async {
    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nama obat wajib diisi')));
      return;
    }

    setState(() => _isSaving = true);
    final service = ref.read(staffServiceProvider);

    try {
      final Map<String, dynamic> data = {
        'name': _nameCtrl.text,
        'generic_name': _genericNameCtrl.text,
        'category': _category,
        'type': _type,
        'form': _form,
        'unit': _unit,
        'price': num.tryParse(_priceCtrl.text) ?? 0,
        'is_active': _isActive ? 1 : 0,
        'manufacturer': _manufacturerCtrl.text.isEmpty
            ? 'ApoTrack'
            : _manufacturerCtrl.text,
        'description': _descCtrl.text,
        'dosage_info': _dosageCtrl.text,
        'weight_in_grams': num.tryParse(_weightCtrl.text) ?? 0,
        'requires_prescription': _requiresPrescription ? 1 : 0,
      };

      final formData = FormData.fromMap(data);

      // Add batches with indices for Laravel: batches[0][batch_number]
      for (var i = 0; i < _batches.length; i++) {
        final b = _batches[i];
        if (b['number'] != null && b['number'].toString().isNotEmpty) {
          if (b['id'] != null) {
            formData.fields.add(
              MapEntry('batches[$i][id]', b['id'].toString()),
            );
          }
          formData.fields.add(
            MapEntry('batches[$i][batch_number]', b['number'].toString()),
          );
          formData.fields.add(
            MapEntry('batches[$i][expired_date]', b['exp'].toString()),
          );
          formData.fields.add(
            MapEntry(
              'batches[$i][stock]',
              (int.tryParse(b['stock'].toString()) ?? 0).toString(),
            ),
          );
        }
      }

      if (_pickedFile != null) {
        if (kIsWeb) {
          formData.files.add(
            MapEntry(
              'image',
              MultipartFile.fromBytes(
                await _pickedFile!.readAsBytes(),
                filename: 'medicine.jpg',
              ),
            ),
          );
        } else {
          formData.files.add(
            MapEntry(
              'image',
              await MultipartFile.fromFile(
                _pickedFile!.path,
                filename: 'medicine.jpg',
              ),
            ),
          );
        }
      }

      dynamic payload = formData;

      if (isEdit) {
        await service.updateMedicine(widget.medicine!.id, payload);
      } else {
        await service.createMedicine(payload);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Perubahan berhasil disimpan'
                  : 'Obat berhasil ditambahkan',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(staffMedicinesProvider);
        if (isEdit) {
          context.go('/staff/inventory');
        } else {
          context.pop();
        }
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (e is DioException && e.response?.data != null) {
        final respData = e.response!.data;
        if (respData is Map && respData.containsKey('message')) {
          errorMessage = respData['message'];
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $errorMessage'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
            color: Colors.white.withValues(alpha: 0.15),
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
              color: Colors.white.withValues(alpha: 0.15),
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
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isEdit ? 'EDIT DATA OBAT' : 'TAMBAH OBAT BARU',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEdit
                        ? (widget.medicine?.name ?? 'Edit Obat')
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
        onTap: _pickImage,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.2),
              width: 1.5,
            ),
            image: _pickedFile != null
                ? DecorationImage(
                    image: kIsWeb
                        ? NetworkImage(_pickedFile!.path)
                        : FileImage(File(_pickedFile!.path)) as ImageProvider,
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.3),
                      BlendMode.darken,
                    ),
                  )
                : (isEdit && widget.medicine?.imageUrl != null)
                ? DecorationImage(
                    image: NetworkImage(widget.medicine!.imageUrl!),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.3),
                      BlendMode.darken,
                    ),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color:
                      (_pickedFile != null ||
                          (isEdit && widget.medicine?.imageUrl != null))
                      ? Colors.white.withValues(alpha: 0.2)
                      : AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add_photo_alternate_rounded,
                  color:
                      (_pickedFile != null ||
                          (isEdit && widget.medicine?.imageUrl != null))
                      ? Colors.white
                      : AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                (_pickedFile != null ||
                        (isEdit && widget.medicine?.imageUrl != null))
                    ? 'Ganti Foto Obat'
                    : 'Upload Foto Obat',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color:
                      (_pickedFile != null ||
                          (isEdit && widget.medicine?.imageUrl != null))
                      ? Colors.white
                      : AppColors.textDark,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _metaBadge(
                    'JPG',
                    inverted:
                        _pickedFile != null ||
                        (isEdit && widget.medicine?.imageUrl != null),
                  ),
                  const SizedBox(width: 5),
                  _metaBadge(
                    'PNG',
                    inverted:
                        _pickedFile != null ||
                        (isEdit && widget.medicine?.imageUrl != null),
                  ),
                  const SizedBox(width: 5),
                  _metaBadge(
                    'Max 2MB',
                    inverted:
                        _pickedFile != null ||
                        (isEdit && widget.medicine?.imageUrl != null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaBadge(String label, {bool inverted = false}) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: inverted
          ? Colors.white.withValues(alpha: 0.2)
          : AppColors.primaryLight,
      borderRadius: BorderRadius.circular(5),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: inverted ? Colors.white : AppColors.primary,
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
              label: 'Golongan Obat',
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
            activeBg: AppColors.accentOrange.withValues(alpha: 0.1),
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
            color: Colors.black.withValues(alpha: 0.07),
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
                child: AppButton(
                  label: _isSaving
                      ? 'Menyimpan...'
                      : (isEdit ? 'Simpan Perubahan' : 'Simpan Obat Baru'),
                  isLoading: _isSaving,
                  onPressed: _saveMedicine,
                  icon: Icons.save_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── DELETE LOGIC ──────────────────────────────
  Future<void> _deleteMedicine() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(staffServiceProvider).deleteMedicine(widget.medicine!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Obat berhasil dihapus'),
            backgroundColor: AppColors.success,
          ),
        );
        ref.invalidate(staffMedicinesProvider);
        context.pop(); // Kembali ke detail
        context
            .pop(); // Kembali ke list (karena detail akan error jika obat sudah dihapus)
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                    onTap: () async {
                      Navigator.pop(context); // Tutup bottom sheet
                      _deleteMedicine();
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
