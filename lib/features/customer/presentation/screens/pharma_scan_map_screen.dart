import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/features/customer/data/models/pharmacy_model.dart';
import 'package:mobile/features/customer/data/services/pharmacy_service.dart';
import 'package:mobile/features/customer/presentation/providers/customer_profile_provider.dart';
import 'medicine_list_screen.dart';

class PharmaScanMapScreen extends ConsumerStatefulWidget {
  final String? categoryId;
  final String? categoryName;

  const PharmaScanMapScreen({super.key, this.categoryId, this.categoryName});

  @override
  ConsumerState<PharmaScanMapScreen> createState() =>
      _PharmaScanMapScreenState();
}

class _PharmaScanMapScreenState extends ConsumerState<PharmaScanMapScreen> {
  String _search = '';
  final Set<String> _activeFilters = {};

  Position? _userPosition;
  bool _locationLoading = true;
  String? _locationError;

  final List<String> _filters = ['Buka 24 Jam', 'Terdekat', 'Rating 4.5+'];

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    setState(() {
      _locationLoading = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationLoading = false;
          _locationError = 'Layanan lokasi tidak aktif. Aktifkan GPS.';
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationLoading = false;
            _locationError = 'Izin lokasi ditolak.';
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationLoading = false;
          _locationError =
              'Izin lokasi ditolak permanen. Aktifkan di pengaturan.';
        });
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 50,
        ),
      );

      if (!mounted) return;
      setState(() {
        _userPosition = pos;
        _locationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationError = 'Gagal mendapatkan lokasi: $e';
      });
    }
  }

  Position? get _activePosition {
    final profileState = ref.read(customerProfileProvider);
    final activeAddr = profileState.tempGpsAddress ??
        profileState.addresses.where((a) => a.isPrimary).firstOrNull;
    if (activeAddr != null) {
      return Position(
        latitude: activeAddr.latitude,
        longitude: activeAddr.longitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );
    }
    return _userPosition;
  }

  double _hitungJarak(PharmacyModel p) {
    final pos = _activePosition;
    if (pos == null) return double.infinity;
    return Geolocator.distanceBetween(
          pos.latitude,
          pos.longitude,
          p.latitude,
          p.longitude,
        ) /
        1000;
  }

  String _formatJarak(double km) {
    if (km == double.infinity) return '-';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static const double _maxRadiusKm = 20.0;

  List<PharmacyModel> _filtered(List<PharmacyModel> pharmacies) {
    var filtered = pharmacies.where((p) {
      final matchSearch =
          _search.isEmpty ||
          p.name.toLowerCase().contains(_search.toLowerCase()) ||
          p.address.toLowerCase().contains(_search.toLowerCase());

      bool matchFilter = true;
      if (_activeFilters.contains('Buka 24 Jam')) {
        matchFilter = matchFilter && p.isOpen;
      }
      if (_activeFilters.contains('Rating 4.5+')) {
        matchFilter = matchFilter && (p.rating >= 4.5);
      }

      return matchSearch && matchFilter;
    }).toList();

    final pos = _activePosition;
    if (pos != null) {
      filtered.removeWhere((p) => _hitungJarak(p) > _maxRadiusKm);
    }

    if (_activeFilters.contains('Terdekat')) {
      filtered.sort((a, b) => _hitungJarak(a).compareTo(_hitungJarak(b)));
    } else {
      filtered.sort((a, b) => (b.isOpen ? 1 : 0) - (a.isOpen ? 1 : 0));
    }
    return filtered;
  }

  void _goToPharmacy(PharmacyModel p) {
    final jarak = _hitungJarak(p);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineListScreen(
          pharmacyId: p.id,
          pharmacyName: p.name,
          pharmacyRating: p.rating,
          pharmacyDistance: _formatJarak(jarak),
          pharmacyArea: p.address,
          isOpen: p.isOpen,
          categoryId: widget.categoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pharmaciesAsync = ref.watch(
      activePharmaciesProvider(widget.categoryId),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: pharmaciesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => _buildErrorState(e.toString()),
                data: (pharmacies) {
                  final filtered = _filtered(pharmacies);
                  return filtered.isEmpty
                      ? _buildEmptyState()
                      : _buildPharmacyList(filtered);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => context.go("/customer"),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.divider, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textDark,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_pharmacy_rounded,
                          color: AppColors.white,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'APOTRACK',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cari Apotek',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.fmd_good_rounded,
                      color: AppColors.primary,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Radius ${_maxRadiusKm.toInt()} km dari lokasimu',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSlate,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _locationError != null
                  ? AppColors.dangerLight
                  : AppColors.surfaceLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: _locationError != null
                    ? AppColors.danger.withOpacity(0.2)
                    : AppColors.divider,
                width: 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _locationLoading ? null : _getUserLocation,
                child: Center(child: _buildLocationIndicator()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationIndicator() {
    if (_locationLoading) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      );
    } else if (_locationError != null) {
      return const Icon(
        Icons.location_off_rounded,
        color: AppColors.danger,
        size: 20,
      );
    } else {
      return const Icon(
        Icons.my_location_rounded,
        color: AppColors.primary,
        size: 20,
      );
    }
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Cari Apotek...',
            hintStyle: const TextStyle(
              color: AppColors.textSubtle,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppColors.textLight,
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            if (widget.categoryName != null &&
                widget.categoryName!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_pharmacy_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.categoryName!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
            ],
            ..._filters.map((f) {
              final isActive = _activeFilters.contains(f);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(
                    () => isActive
                        ? _activeFilters.remove(f)
                        : _activeFilters.add(f),
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isActive ? AppColors.primary : AppColors.divider,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      f,
                      style: TextStyle(
                        color: isActive ? Colors.white : AppColors.textMid,
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyList(List<PharmacyModel> filtered) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final p = filtered[i];
        final jarak = _hitungJarak(p);
        return _PharmacyCard(
          pharmacy: p,
          jarakText: _formatJarak(jarak),
          onTap: () => _goToPharmacy(p),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    String message = 'Apotek tidak ditemukan';
    String detail = _activePosition != null
        ? 'Tidak ada apotek dalam radius ${_maxRadiusKm.toInt()} km'
        : 'Coba ubah kata kunci pencarian';

    if (widget.categoryName != null && widget.categoryName!.isNotEmpty) {
      message = 'Jenis Obat Tidak Tersedia';
      detail =
          'Tidak ada apotek di daerah sekitar Anda yang menjual jenis obat "${widget.categoryName}"';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: AppColors.textSubtle),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              detail,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSubtle,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.textSubtle,
            ),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat data',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSubtle),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => ref.invalidate(
                    activePharmaciesProvider(widget.categoryId),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final String jarakText;
  final VoidCallback onTap;

  const _PharmacyCard({
    required this.pharmacy,
    required this.jarakText,
    required this.onTap,
  });

  Widget _buildImage(String? url) {
    if (url == null || url.isEmpty) {
      return Container(
        color: AppColors.primaryLight,
        child: const Center(
          child: Icon(
            Icons.local_pharmacy_rounded,
            color: AppColors.primary,
            size: 36,
          ),
        ),
      );
    }
    return Image.network(
      url,
      width: 72,
      height: 72,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          width: 72,
          height: 72,
          color: AppColors.primaryLight,
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: 72,
        height: 72,
        color: AppColors.primaryLight,
        child: const Icon(
          Icons.local_pharmacy_rounded,
          color: AppColors.primary,
          size: 36,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = pharmacy;
    final isOpen = p.isOpen;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: ColorFiltered(
                      colorFilter: !isOpen
                          ? const ColorFilter.matrix([
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0.2126,
                              0.7152,
                              0.0722,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ])
                          : ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.multiply,
                            ),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: _buildImage(p.logoUrl),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(14),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        color: Colors.black.withValues(alpha: 0.45),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: isOpen ? Colors.amber : Colors.grey,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              p.rating.toStringAsFixed(1),
                              style: TextStyle(
                                color: isOpen ? Colors.white : Colors.grey,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Opacity(
                  opacity: isOpen ? 1.0 : 0.5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: isOpen
                                    ? AppColors.textDark
                                    : AppColors.textLight,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isOpen
                                  ? AppColors.successLight
                                  : AppColors.divider,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isOpen ? 'BUKA' : 'TUTUP',
                              style: TextStyle(
                                color: isOpen
                                    ? AppColors.success
                                    : AppColors.textLight,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            color: isOpen ? Colors.amber : Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '${p.rating.toStringAsFixed(1)} (${p.totalReviews})',
                            style: TextStyle(
                              fontSize: 11,
                              color: isOpen ? AppColors.textLight : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.location_on_rounded,
                            color: isOpen ? AppColors.primary : Colors.grey,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            jarakText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isOpen ? AppColors.primary : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        p.address,
                        style: TextStyle(
                          fontSize: 10,
                          color: isOpen
                              ? AppColors.textSubtle
                              : Colors.grey.shade300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: isOpen ? AppColors.divider : Colors.grey.shade300,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
