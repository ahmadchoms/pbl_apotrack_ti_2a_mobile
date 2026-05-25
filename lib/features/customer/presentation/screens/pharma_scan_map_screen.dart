import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile/features/customer/data/models/pharmacy_model.dart';
import 'package:mobile/features/customer/data/services/pharmacy_service.dart';
import 'medicine_list_screen.dart';

class PharmaScanMapScreen extends ConsumerStatefulWidget {
  const PharmaScanMapScreen({super.key});

  @override
  ConsumerState<PharmaScanMapScreen> createState() =>
      _PharmaScanMapScreenState();
}

class _PharmaScanMapScreenState extends ConsumerState<PharmaScanMapScreen> {
  String _search = '';
  final Set<String> _activeFilters = {};
  final MapController _mapController = MapController();

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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationLoading = false;
        _locationError = 'Gagal mendapatkan lokasi: $e';
      });
    }
  }

  double _hitungJarak(PharmacyModel p) {
    if (_userPosition == null) return double.infinity;
    final userPoint = LatLng(_userPosition!.latitude, _userPosition!.longitude);
    final pharmPoint = LatLng(p.latitude, p.longitude);
    return const Distance().distance(userPoint, pharmPoint) / 1000;
  }

  String _formatJarak(double km) {
    if (km == double.infinity) return '-';
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  List<PharmacyModel> _filtered(List<PharmacyModel> pharmacies) {
    final filtered = pharmacies.where((p) {
      final matchSearch = _search.isEmpty ||
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

    if (_activeFilters.contains('Terdekat')) {
      filtered.sort((a, b) => _hitungJarak(a).compareTo(_hitungJarak(b)));
    } else {
      filtered.sort((a, b) => (b.isOpen ? 1 : 0) - (a.isOpen ? 1 : 0));
    }
    return filtered;
  }

  void _goToPharmacy(PharmacyModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicineListScreen(
          pharmacyId: p.id,
          pharmacyName: p.name,
          pharmacyRating: p.rating,
          isOpen: p.isOpen,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pharmaciesAsync = ref.watch(activePharmaciesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildSearchBar(),
            _buildFilterChips(),
            Expanded(
              child: pharmaciesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFF2563EB)),
                ),
                error: (e, _) => _buildErrorState(e.toString()),
                data: (pharmacies) {
                  final filtered = _filtered(pharmacies);
                  return Stack(
                    children: [
                      _buildMap(filtered),
                      _buildBottomSheet(filtered),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          const Text(
            'ApoTrack',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const Spacer(),
          if (_locationLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF2563EB),
              ),
            )
          else if (_locationError != null)
            GestureDetector(
              onTap: _getUserLocation,
              child: const Icon(Icons.location_off,
                  color: Color(0xFFEF4444), size: 22),
            )
          else
            const Icon(Icons.my_location,
                color: Color(0xFF2563EB), size: 22),
          const SizedBox(width: 12),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEFF6FF),
            child: ClipOval(
              child: Container(
                color: const Color(0xFF2563EB).withOpacity(0.15),
                child: const Icon(Icons.person,
                    color: Color(0xFF2563EB), size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Cari Apotek...',
                  hintStyle:
                      TextStyle(color: Color(0xFF9E9E9E), fontSize: 14),
                  prefixIcon:
                      Icon(Icons.search, color: Color(0xFF9E9E9E), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.tune, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: _filters.map((f) {
          final isActive = _activeFilters.contains(f);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() =>
                  isActive ? _activeFilters.remove(f) : _activeFilters.add(f)),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFF2563EB) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFD1D5DB),
                  ),
                ),
                child: Text(
                  f,
                  style: TextStyle(
                    color:
                        isActive ? Colors.white : const Color(0xFF374151),
                    fontSize: 12,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMap(List<PharmacyModel> pharmacies) {
    if (_locationLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2563EB)),
            SizedBox(height: 12),
            Text('Mendapatkan lokasi...',
                style: TextStyle(color: Color(0xFF6B7280))),
          ],
        ),
      );
    }

    if (_locationError != null) {
      return _buildLocationError();
    }

    final markers = <Marker>[];

    if (_userPosition != null) {
      markers.add(
        Marker(
          point: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          width: 30,
          height: 30,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.my_location, color: Colors.white, size: 16),
          ),
        ),
      );
    }

    for (final p in pharmacies) {
      markers.add(
        Marker(
          point: LatLng(p.latitude, p.longitude),
          width: 44,
          height: 44,
          child: GestureDetector(
            onTap: () => _goToPharmacy(p),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: p.isOpen ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.local_pharmacy,
                      color: Colors.white, size: 18),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    p.name.length > 12
                        ? '${p.name.substring(0, 12)}...'
                        : p.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _userPosition != null
            ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
            : const LatLng(-6.2088, 106.8456),
        initialZoom: 13,
        minZoom: 10,
        maxZoom: 17,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.apotrack.mobile',
        ),
        MarkerLayer(markers: markers),
      ],
    );
  }

  Widget _buildBottomSheet(List<PharmacyModel> filtered) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.35,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Apotek Terdekat',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF111827),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filtered.length} ditemukan',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF3F4F6)),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off,
                              size: 32, color: Color(0xFF9CA3AF)),
                          SizedBox(height: 8),
                          Text('Apotek tidak ditemukan',
                              style: TextStyle(color: Color(0xFF6B7280))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        final jarak = _hitungJarak(p);
                        return _PharmacyCard(
                          pharmacy: p,
                          jarakText: _formatJarak(jarak),
                          onTap: () => _goToPharmacy(p),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 48, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(
            'Gagal memuat data:\n$msg',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => ref.invalidate(activePharmaciesProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child:
                const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off, size: 48, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(
            '$_locationError',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _getUserLocation,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Coba Lagi',
                style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                _locationError = null;
                _locationLoading = false;
              });
            },
            child: const Text('Lanjutkan tanpa lokasi',
                style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
          ),
        ],
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
        color: const Color(0xFFEFF6FF),
        child: const Center(
          child: Icon(Icons.local_pharmacy,
              color: Color(0xFF2563EB), size: 36),
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
          color: const Color(0xFFEFF6FF),
          child: const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF2563EB),
            ),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        width: 72,
        height: 72,
        color: const Color(0xFFEFF6FF),
        child: const Icon(Icons.local_pharmacy,
            color: Color(0xFF2563EB), size: 36),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = pharmacy;
    final isOpen = p.isOpen;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: ColorFiltered(
                    colorFilter: !isOpen
                        ? const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0, 0, 0, 1, 0,
                          ])
                        : ColorFilter.mode(
                            Colors.transparent, BlendMode.multiply),
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
                        bottom: Radius.circular(12)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      color: Colors.black.withOpacity(0.45),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star,
                              color: isOpen ? Colors.amber : Colors.grey[400],
                              size: 10),
                          const SizedBox(width: 2),
                          Text(
                            p.rating.toStringAsFixed(1),
                            style: TextStyle(
                              color:
                                  isOpen ? Colors.white : Colors.grey[400],
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
            const SizedBox(width: 12),
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
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isOpen
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF9CA3AF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOpen ? 'BUKA' : 'TUTUP',
                            style: TextStyle(
                              color: isOpen
                                  ? const Color(0xFF065F46)
                                  : const Color(0xFF9CA3AF),
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star,
                            color: isOpen ? Colors.amber : Colors.grey[400],
                            size: 12),
                        const SizedBox(width: 2),
                        Text(
                          '${p.rating.toStringAsFixed(1)} (${p.totalReviews})',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOpen
                                ? const Color(0xFF6B7280)
                                : Colors.grey[400],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.location_on,
                            color: isOpen
                                ? const Color(0xFF2563EB)
                                : Colors.grey[400],
                            size: 12),
                        const SizedBox(width: 2),
                        Text(
                          jarakText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOpen
                                ? const Color(0xFF2563EB)
                                : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.address,
                      style: TextStyle(
                        fontSize: 10,
                        color: isOpen
                            ? const Color(0xFF9CA3AF)
                            : Colors.grey[300],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                color: isOpen ? const Color(0xFFD1D5DB) : Colors.grey[300],
                size: 20),
          ],
        ),
      ),
    );
  }
}
