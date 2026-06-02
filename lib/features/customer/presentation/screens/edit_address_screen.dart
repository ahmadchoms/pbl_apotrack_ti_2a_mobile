import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/customer_address.dart';
import '../providers/customer_profile_provider.dart';
import '../widgets/profile/map_picker_dialog.dart';

class CustomerEditAddressScreen extends ConsumerStatefulWidget {
  final bool isAdd;
  final CustomerAddress? address;

  const CustomerEditAddressScreen({
    super.key,
    this.isAdd = false,
    this.address,
  });

  @override
  ConsumerState<CustomerEditAddressScreen> createState() =>
      _CustomerEditAddressScreenState();
}

class _CustomerEditAddressScreenState
    extends ConsumerState<CustomerEditAddressScreen> {
  late final TextEditingController _labelController;
  late final TextEditingController _addressController;
  bool _isPrimary = false;
  bool _isSaving = false;
  String? _labelError;
  String? _addressError;

  late double _latitude;
  late double _longitude;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.address?.label ?? '');
    _addressController = TextEditingController(
      text: widget.address?.addressDetail ?? '',
    );
    _isPrimary = widget.address?.isPrimary ?? false;
    _latitude = widget.address?.latitude ?? -6.2088;
    _longitude = widget.address?.longitude ?? 106.8456;
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
        await ref
            .read(customerProfileProvider.notifier)
            .addAddress(
              label: _labelController.text.trim(),
              addressDetail: _addressController.text.trim(),
              latitude: _latitude,
              longitude: _longitude,
              isPrimary: _isPrimary,
            );
      } else {
        await ref
            .read(customerProfileProvider.notifier)
            .updateAddress(
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
            content: Text(
              widget.isAdd
                  ? 'Alamat berhasil ditambahkan'
                  : 'Alamat berhasil diperbarui',
            ),
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

  // REVISI: ganti showDialog return value ke callback langsung
  void _showMapPicker() {
    showDialog(
      context: context,
      builder: (_) => MapPickerDialog(
        latitude: _latitude,
        longitude: _longitude,
        onLocationSelected: (lat, lng) {
          setState(() {
            _latitude = lat;
            _longitude = lng;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF1D70F5);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.isAdd ? 'Tambah Alamat' : 'Edit Alamat',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map picker thumbnail
            const Text(
              'LOKASI PRESISI',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 10),
            // REVISI: tampilan thumbnail peta tanpa koordinat, lebih bersih
            GestureDetector(
              onTap: _showMapPicker,
              child: Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4E9D3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBBD9B9)),
                ),
                child: Stack(
                  children: [
                    // Background grid peta simulasi
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        size: const Size(double.infinity, 140),
                        painter: _MapGridPainter(),
                      ),
                    ),
                    // Icon dan teks tengah
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              size: 28,
                              color: Color(0xFF1D70F5),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Ketuk untuk pilih lokasi',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1D70F5),
                                fontWeight: FontWeight.w700,
                              ),
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

            // Label field
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

            // Address field
            _buildFieldLabel('Alamat Lengkap', _addressError),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _addressError != null
                      ? AppColors.danger
                      : const Color(0xFFF1F5F9),
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
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                  hintText: 'Jl. Nama Jalan No. X, Kelurahan, Kecamatan...',
                  hintStyle: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            if (_addressError != null) _buildErrorText(_addressError!),
            const SizedBox(height: 16),

            // Toggle Primary
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: SwitchListTile(
                value: _isPrimary,
                onChanged: (v) => setState(() => _isPrimary = v),
                activeColor: primaryColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                title: const Text(
                  'Jadikan Alamat Utama',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                subtitle: const Text(
                  'Digunakan sebagai default pengiriman',
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Info box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.isAdd
                          ? 'Alamat baru akan ditambahkan ke daftar pengirimanmu.'
                          : 'Perubahan akan langsung diterapkan.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF0055a5),
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        widget.isAdd ? 'Tambah Alamat' : 'Simpan Alamat',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
        color: error != null ? AppColors.danger : const Color(0xFF64748B),
      ),
    ),
  );

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool hasError,
    required ValueChanged<String> onChanged,
  }) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: hasError ? AppColors.danger : const Color(0xFFF1F5F9),
        width: hasError ? 1.5 : 1,
      ),
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
      ),
    ),
  );

  Widget _buildErrorText(String text) => Padding(
    padding: const EdgeInsets.only(left: 4, top: 6),
    child: Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          size: 13,
          color: AppColors.danger,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

// REVISI: custom painter untuk background grid peta simulasi
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA8C8A8).withOpacity(0.5)
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