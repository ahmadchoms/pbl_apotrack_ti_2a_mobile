import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../customer/data/models/customer_address.dart';
import '../providers/staff_provider.dart';
import '../../../customer/presentation/widgets/profile/map_picker_dialog.dart';

class EditAddressScreen extends ConsumerStatefulWidget {
  final bool isAdd;
  final CustomerAddress? address;

  const EditAddressScreen({
    super.key,
    this.isAdd = false,
    this.address,
  });

  @override
  ConsumerState<EditAddressScreen> createState() =>
      _EditAddressScreenState();
}

class _EditAddressScreenState extends ConsumerState<EditAddressScreen> {
  late final TextEditingController _labelController;
  late final TextEditingController _addressController;
  bool    _isPrimary = false;
  bool    _isSaving  = false;
  String? _labelError;
  String? _addressError;

  late double _latitude;
  late double _longitude;

  @override
  void initState() {
    super.initState();
    _labelController   = TextEditingController(text: widget.address?.label ?? '');
    _addressController = TextEditingController(
        text: widget.address?.addressDetail ?? '');
    _isPrimary  = widget.address?.isPrimary ?? false;
    _latitude   = widget.address?.latitude  ?? -6.2088;
    _longitude  = widget.address?.longitude ?? 106.8456;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  bool _validate() {
    bool valid = true;
    if (_labelController.text.trim().isEmpty) {
      _labelError = 'Label tidak boleh kosong';
      valid = false;
    } else {
      _labelError = null;
    }
    if (_addressController.text.trim().length < 10) {
      _addressError = 'Alamat minimal 10 karakter';
      valid = false;
    } else {
      _addressError = null;
    }
    setState(() {});
    return valid;
  }

  Future<void> _onSave() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);
    try {
      if (widget.isAdd) {
        await ref.read(profileProvider.notifier).addAddress(
              label: _labelController.text.trim(),
              addressDetail: _addressController.text.trim(),
              latitude: _latitude,
              longitude: _longitude,
              isPrimary: _isPrimary,
            );
      } else {
        await ref.read(profileProvider.notifier).updateAddress(
              id: widget.address!.id,
              label: _labelController.text.trim(),
              addressDetail: _addressController.text.trim(),
              latitude: _latitude,
              longitude: _longitude,
              isPrimary: _isPrimary,
            );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isAdd
                ? 'Alamat berhasil ditambahkan'
                : 'Alamat berhasil diperbarui'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMapPicker() {
    showDialog(
      context: context,
      builder: (_) => MapPickerDialog(
        latitude: _latitude,
        longitude: _longitude,
        onLocationSelected: (lat, lng) {
          setState(() {
            _latitude  = lat;
            _longitude = lng;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isAdd ? 'Tambah Alamat' : 'Edit Alamat',
          style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Map picker ────────────────────────────────────
            const Text(
              'LOKASI PRESISI',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textLight,
                  letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showMapPicker,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.mapGreen,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.mapGreenBorder),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        size: const Size(double.infinity, 140),
                        painter: _MapGridPainter(),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.black.withValues(alpha: 0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                size: 28, color: AppColors.primary),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Ketuk untuk pilih lokasi',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Label field ───────────────────────────────────
            _buildFieldLabel('Label Alamat', _labelError),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _labelController,
              hint: 'Contoh: Rumah, Kantor, Kos',
              icon: Icons.label_outline_rounded,
              hasError: _labelError != null,
              onChanged: (_) {
                if (_labelError != null) setState(() => _labelError = null);
              },
            ),
            if (_labelError != null) _buildErrorText(_labelError!),
            const SizedBox(height: 16),

            // ── Alamat lengkap ────────────────────────────────
            _buildFieldLabel('Alamat Lengkap', _addressError),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _addressError != null
                      ? AppColors.danger
                      : AppColors.divider,
                  width: _addressError != null ? 1.5 : 1,
                ),
              ),
              child: TextField(
                controller: _addressController,
                maxLines: 4,
                onChanged: (_) {
                  if (_addressError != null) {
                    setState(() => _addressError = null);
                  }
                },
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintText: 'Jl. Nama Jalan No. X, Kelurahan, Kecamatan...',
                  hintStyle: TextStyle(
                      fontSize: 13, color: AppColors.textLight),
                ),
              ),
            ),
            if (_addressError != null) _buildErrorText(_addressError!),
            const SizedBox(height: 16),

            // ── Toggle primary ────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: SwitchListTile(
                value: _isPrimary,
                onChanged: (v) => setState(() => _isPrimary = v),
                activeThumbColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                title: const Text(
                  'Jadikan Alamat Utama',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark),
                ),
                subtitle: const Text(
                  'Digunakan sebagai alamat utama',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textLight),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Info box ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isAdd
                          ? 'Alamat baru akan ditambahkan ke daftar alamat Anda.'
                          : 'Perubahan akan langsung diterapkan.',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          height: 1.4,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // ── Tombol simpan ─────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2))
                    : Text(
                        widget.isAdd ? 'Tambah Alamat' : 'Simpan Alamat',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text, String? error) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: error != null ? AppColors.danger : AppColors.textLight,
          ),
        ),
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool hasError,
    required ValueChanged<String> onChanged,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasError ? AppColors.danger : AppColors.divider,
            width: hasError ? 1.5 : 1,
          ),
        ),
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.textMid, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            hintText: hint,
            hintStyle:
                const TextStyle(fontSize: 13, color: AppColors.textLight),
          ),
        ),
      );

  Widget _buildErrorText(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 6),
        child: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 13, color: AppColors.danger),
            const SizedBox(width: 4),
            Text(
              text,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.mapGrid.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}