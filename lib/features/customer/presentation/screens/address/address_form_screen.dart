import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../core/theme/app_colors.dart';
import 'address_model.dart';
import 'address_provider.dart';

/// Screen Tambah / Edit Alamat
/// Dipanggil dari AddressPickerSheet maupun FavoriteAddressScreen
class AddressFormScreen extends StatefulWidget {
  final AddressModel? existing; // null = tambah baru, non-null = edit
  final AddressProvider provider;
  final Future<void> Function(AddressModel address, bool isEdit)? onSaved;

  const AddressFormScreen({
    super.key,
    this.existing,
    required this.provider,
    this.onSaved,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _landmarkCtrl;
  late AddressType _type;
  double? _latitude;
  double? _longitude;
  bool _locating = true;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _addressCtrl = TextEditingController(text: e?.fullAddress ?? '');
    _landmarkCtrl = TextEditingController(text: e?.landmark ?? '');
    _type = e?.type ?? AddressType.personal;
    _latitude = e?.latitude;
    _longitude = e?.longitude;
    if (!_isEdit) _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _landmarkCtrl.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      setState(() => _locating = false);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        setState(() => _locating = false);
        return;
      }
    }

    if (!mounted) return;
    if (permission == LocationPermission.deniedForever) {
      setState(() => _locating = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _latitude = pos.latitude;
      _longitude = pos.longitude;
    } catch (e) {
      debugPrint('Gagal dapat lokasi: $e');
    }
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty || _addressCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama alamat dan alamat wajib diisi')),
      );
      return;
    }

    final address = AddressModel(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim(),
      fullAddress: _addressCtrl.text.trim(),
      landmark: _landmarkCtrl.text.trim().isEmpty ? null : _landmarkCtrl.text.trim(),
      type: _type,
      latitude: _latitude ?? -6.208800,
      longitude: _longitude ?? 106.845600,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await widget.onSaved?.call(address, _isEdit);
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      if (_isEdit) {
        widget.provider.updateFavorite(address);
      } else {
        widget.provider.addFavorite(address);
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // dismiss loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan alamat: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Ubah Alamat' : 'Tambah Alamat',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Map placeholder ──────────────────────────────────────
          _buildMapPlaceholder(),
          const SizedBox(height: 20),

          // ── Alamat terdeteksi ────────────────────────────────────
          _buildDetectedAddress(),
          const SizedBox(height: 20),

          // ── Form fields ──────────────────────────────────────────
          _fieldLabel('Nama Alamat *'),
          const SizedBox(height: 8),
          _textField(
            controller: _nameCtrl,
            hint: 'Cth: Sekolah, Rumah nenek',
          ),
          const SizedBox(height: 16),

          _fieldLabel('Alamat Lengkap *'),
          const SizedBox(height: 8),
          _textField(
            controller: _addressCtrl,
            hint: 'Jalan, nomor, kecamatan, kota...',
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          _fieldLabel('Patokan (Opsional)'),
          const SizedBox(height: 8),
          _textField(
            controller: _landmarkCtrl,
            hint: 'Cth: Depan minimarket, cat merah...',
            prefixIcon: Icons.flag_rounded,
          ),
          const SizedBox(height: 20),

          // ── Tipe alamat ──────────────────────────────────────────
          _fieldLabel('Tipe Alamat *'),
          const SizedBox(height: 12),
          Row(
            children: [
              _typeChip(AddressType.personal, Icons.person_rounded, 'Personal'),
              const SizedBox(width: 12),
              _typeChip(AddressType.bisnis, Icons.business_rounded, 'Bisnis'),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  // ── Map placeholder (simulasi Google Maps) ───────────────────────
  Widget _buildMapPlaceholder() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          Container(
            height: 180,
            color: const Color(0xFFE8EEF4),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_locating)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(Icons.map_rounded, size: 48, color: Color(0xFFBBC6CF)),
                  const SizedBox(height: 8),
                  Text(
                    _locating
                        ? 'Mendapatkan lokasi...'
                        : _latitude != null
                            ? 'Lokasi: $_latitude, $_longitude'
                            : 'Peta lokasi',
                    style: const TextStyle(color: Color(0xFFBBC6CF), fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          // Pin tengah
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_upward_rounded,
                        color: Colors.white, size: 22),
                  ),
                  Container(
                    width: 2,
                    height: 10,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
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
        child: Icon(icon, size: 18, color: AppColors.textDark),
      ),
    );
  }

  // ── Alamat terdeteksi ────────────────────────────────────────────
  Widget _buildDetectedAddress() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _addressCtrl.text.isEmpty
                      ? 'Pilih lokasi di peta'
                      : _addressCtrl.text,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _landmarkCtrl,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.flag_rounded,
                  color: AppColors.textLight, size: 18),
              hintText: 'Tambah patokan',
              hintStyle: const TextStyle(
                  color: AppColors.textLight, fontSize: 13),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────
  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(fontSize: 13, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: AppColors.textLight, fontSize: 13),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, size: 18, color: AppColors.textLight)
              : null,
          contentPadding: const EdgeInsets.all(14),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _typeChip(AddressType type, IconData icon, String label) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () => setState(() => _type = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : AppColors.textLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _isEdit ? 'Simpan Perubahan' : 'Simpan Alamat',
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15),
          ),
        ),
      ),
    );
  }
}