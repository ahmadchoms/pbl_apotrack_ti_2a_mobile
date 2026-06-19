import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/utils/location_helper.dart';
import '../../widgets/profile/map_picker_dialog.dart';
import '../../providers/customer_profile_provider.dart';
import 'address_model.dart';
import 'address_provider.dart';
import 'address_form_screen.dart';

/// Bottom sheet full-layar untuk memilih alamat pengiriman.
/// Berisi: search, lokasimu saat ini, pilih lewat peta, dan list alamat tersimpan.
void showAddressPickerSheet(
  BuildContext context,
  AddressProvider provider, {
  required VoidCallback onSelected,
  Future<void> Function(AddressModel address, bool isEdit)? onAddressSaved,
  void Function(AddressModel address)? onSetPrimary,
  void Function(String id)? onAddressDeleted,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => AddressPickerSheet(
      provider: provider,
      onSelected: onSelected,
      onAddressSaved: onAddressSaved,
      onSetPrimary: onSetPrimary,
      onAddressDeleted: onAddressDeleted,
    ),
  );
}

class AddressPickerSheet extends ConsumerStatefulWidget {
  final AddressProvider provider;
  final VoidCallback onSelected;
  final Future<void> Function(AddressModel address, bool isEdit)?
  onAddressSaved;
  final void Function(AddressModel address)? onSetPrimary;
  final void Function(String id)? onAddressDeleted;

  const AddressPickerSheet({
    super.key,
    required this.provider,
    required this.onSelected,
    this.onAddressSaved,
    this.onSetPrimary,
    this.onAddressDeleted,
  });

  @override
  ConsumerState<AddressPickerSheet> createState() => _AddressPickerSheetState();
}

class _AddressPickerSheetState extends ConsumerState<AddressPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileState = ref.read(customerProfileProvider);
      if (profileState.addresses.isEmpty && !profileState.isLoading) {
        ref.read(customerProfileProvider.notifier).loadAll();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _selectAddress(AddressModel address) {
    widget.provider.selectAddress(address);
    widget.onSetPrimary?.call(address);
    if (address.id != 'gps_session') {
      ref.read(customerProfileProvider.notifier).clearTempGpsLocation();
    }
    Navigator.pop(context);
    widget.onSelected();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      final position = await LocationHelper.determinePosition(context);
      if (position == null) {
        setState(() => _isFetchingLocation = false);
        return;
      }

      final addressText = await LocationHelper.getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );

      final savedAddr = await ref.read(customerProfileProvider.notifier).addAddress(
        label: 'Lokasi Sekarang',
        addressDetail: addressText,
        latitude: position.latitude,
        longitude: position.longitude,
        isPrimary: false,
      );

      final activeAddr = AddressModel.fromCustomerAddress(savedAddr);
      _selectAddress(activeAddr);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mendapatkan lokasi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  Future<void> _pickFromMap() async {
    double initialLat = -6.208800;
    double initialLng = 106.845600;

    final profileState = ref.read(customerProfileProvider);
    final activeAddr =
        profileState.tempGpsAddress ??
        profileState.addresses.where((a) => a.isPrimary).firstOrNull;

    if (activeAddr != null) {
      initialLat = activeAddr.latitude;
      initialLng = activeAddr.longitude;
    } else {
      try {
        final pos = await LocationHelper.determinePosition(context);
        if (pos != null) {
          initialLat = pos.latitude;
          initialLng = pos.longitude;
        }
      } catch (_) {}
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => MapPickerDialog(
        latitude: initialLat,
        longitude: initialLng,
        onLocationSelected: (lat, lng) async {
          setState(() => _isFetchingLocation = true);
          try {
            final addressText = await LocationHelper.getAddressFromLatLng(
              lat,
              lng,
            );

            final savedAddr = await ref.read(customerProfileProvider.notifier).addAddress(
              label: 'Lokasi Terpilih',
              addressDetail: addressText,
              latitude: lat,
              longitude: lng,
              isPrimary: false,
            );

            final mapAddr = AddressModel.fromCustomerAddress(savedAddr);
            _selectAddress(mapAddr);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Gagal mendapatkan alamat dari peta: $e'),
                ),
              );
            }
          } finally {
            if (mounted) {
              setState(() => _isFetchingLocation = false);
            }
          }
        },
      ),
    );
  }

  Future<void> _openForm({AddressModel? existing}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(
          existing: existing,
          provider: widget.provider,
          onSaved: (address, isEdit) async {
            if (widget.onAddressSaved != null) {
              await widget.onAddressSaved!(address, isEdit);
            } else {
              final notifier = ref.read(customerProfileProvider.notifier);
              if (isEdit) {
                await notifier.updateAddress(
                  id: address.id,
                  label: address.name,
                  addressDetail: address.fullAddress,
                  latitude: address.latitude ?? -6.208800,
                  longitude: address.longitude ?? 106.845600,
                  isPrimary: address.isPrimary,
                );
              } else {
                final newAddr = await notifier.addAddress(
                  label: address.name,
                  addressDetail: address.fullAddress,
                  latitude: address.latitude ?? -6.208800,
                  longitude: address.longitude ?? 106.845600,
                  isPrimary: address.isPrimary,
                );
                widget.provider.updateAddressId(address.id, newAddr.id);
              }
            }
          },
        ),
      ),
    );
    if (result == true) setState(() {});
  }

  void _showFavoriteOptions(AddressModel address) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address.fullAddress,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              _optionTile(Icons.edit_rounded, 'Ubah', () {
                Navigator.pop(context);
                _openForm(existing: address);
              }),
              const SizedBox(height: 10),
              _optionTile(Icons.delete_outline_rounded, 'Hapus', () async {
                Navigator.pop(context);
                if (widget.onAddressDeleted != null) {
                  widget.onAddressDeleted!.call(address.id);
                } else {
                  await ref
                      .read(customerProfileProvider.notifier)
                      .deleteAddress(address.id);
                }
                widget.provider.deleteFavorite(address.id);
                setState(() {});
              }, isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFEF4444) : AppColors.textDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(customerProfileProvider);
    final savedAddresses = profileState.addresses
        .map(AddressModel.fromCustomerAddress)
        .toList();

    final filteredFav = _query.isEmpty
        ? savedAddresses
        : savedAddresses
              .where(
                (a) =>
                    a.name.toLowerCase().contains(_query.toLowerCase()) ||
                    a.fullAddress.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.96,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Pilih Lokasi',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v),
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Cari alamat...',
                    hintStyle: const TextStyle(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(10),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6B35),
                        shape: BoxShape.circle,
                      ),
                    ),
                    suffixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 4,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _quickAction(
                      icon: Icons.my_location_rounded,
                      label: 'Lokasimu saat ini',
                      color: AppColors.primary,
                      onTap: _isFetchingLocation ? () {} : _getCurrentLocation,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _quickAction(
                      icon: Icons.map_rounded,
                      label: 'Pilih lewat peta',
                      color: AppColors.primary,
                      onTap: _isFetchingLocation ? () {} : _pickFromMap,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_isFetchingLocation)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Mendapatkan lokasi...',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Alamat Tersimpan',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppColors.textDark,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _openForm(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '+ Tambah Baru',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (profileState.isLoading && savedAddresses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (filteredFav.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'Tidak ada alamat ditemukan',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    ...filteredFav.map((a) => _favoriteCard(a)),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _favoriteCard(AddressModel address) {
    return GestureDetector(
      onTap: () => _selectAddress(address),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.home_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    address.fullAddress,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.more_vert_rounded,
                size: 18,
                color: AppColors.textLight,
              ),
              onPressed: () => _showFavoriteOptions(address),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Halaman Alamat Favorit (Lihat Semua)
// ─────────────────────────────────────────────────────────────────────────────

class FavoriteAddressScreen extends StatefulWidget {
  final AddressProvider provider;
  final void Function(AddressModel) onSelectAddress;
  final Future<void> Function(AddressModel address, bool isEdit)?
  onAddressSaved;
  final void Function(String id)? onAddressDeleted;

  const FavoriteAddressScreen({
    super.key,
    required this.provider,
    required this.onSelectAddress,
    this.onAddressSaved,
    this.onAddressDeleted,
  });

  @override
  State<FavoriteAddressScreen> createState() => _FavoriteAddressScreenState();
}

class _FavoriteAddressScreenState extends State<FavoriteAddressScreen> {
  AddressType _tab = AddressType.personal;

  List<AddressModel> get _filtered =>
      widget.provider.favorites.where((a) => a.type == _tab).toList();

  Future<void> _openForm({AddressModel? existing}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddressFormScreen(
          existing: existing,
          provider: widget.provider,
          onSaved: widget.onAddressSaved,
        ),
      ),
    );
    if (result == true) setState(() {});
  }

  void _showOptions(AddressModel address) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                address.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                address.fullAddress,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              _optionTile(Icons.edit_rounded, 'Ubah', () {
                Navigator.pop(context);
                _openForm(existing: address);
              }),
              const SizedBox(height: 10),
              _optionTile(Icons.delete_outline_rounded, 'Hapus', () {
                Navigator.pop(context);
                widget.onAddressDeleted?.call(address.id);
                widget.provider.deleteFavorite(address.id);
                setState(() {});
              }, isDestructive: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? const Color(0xFFEF4444) : AppColors.textDark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDestructive
                ? const Color(0xFFEF4444).withValues(alpha: 0.2)
                : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: AppColors.textDark,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Alamat Favorit',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: false,
        actions: [
          TextButton(
            onPressed: () => _openForm(),
            child: Text(
              'Tambah baru',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.grey.shade100),
        ),
      ),
      body: Column(
        children: [
          // ── Tab: Personal / Bisnis ───────────────────────────────
          Container(
            color: Colors.white,
            child: Row(
              children: [
                _tabItem(
                  AddressType.personal,
                  Icons.person_rounded,
                  'Personal',
                ),
                _tabItem(AddressType.bisnis, Icons.business_rounded, 'Bisnis'),
              ],
            ),
          ),

          // ── List ─────────────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bookmark_border_rounded,
                            size: 48,
                            color: AppColors.textLight.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada alamat favorit',
                          style: TextStyle(
                            color: AppColors.textLight,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => _openForm(),
                          child: Text(
                            'Tambah alamat baru',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _addressCard(_filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(AddressType type, IconData icon, String label) {
    final isActive = _tab == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = type),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isActive ? AppColors.primary : AppColors.textLight,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: isActive ? AppColors.primary : AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 2,
              color: isActive ? AppColors.primary : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _addressCard(AddressModel address) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 4),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.bookmark_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    size: 16,
                    color: AppColors.textLight,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(
                    Icons.more_horiz_rounded,
                    size: 18,
                    color: AppColors.textLight,
                  ),
                  onPressed: () => _showOptions(address),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────
          Divider(height: 1, color: Colors.grey.shade100),

          // ── Body ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address.fullAddress,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                  ),
                ),
                if (address.landmark != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.flag_rounded,
                        size: 12,
                        color: AppColors.textLight,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address.landmark!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      widget.onSelectAddress(address);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Gunakan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
