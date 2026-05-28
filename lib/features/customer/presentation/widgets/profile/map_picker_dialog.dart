import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile/core/theme/app_colors.dart';

class MapPickerDialog extends StatefulWidget {
  final double latitude;
  final double longitude;
  final void Function(double latitude, double longitude) onLocationSelected;

  const MapPickerDialog({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.onLocationSelected,
  });

  @override
  State<MapPickerDialog> createState() => _MapPickerDialogState();
}

class _MapPickerDialogState extends State<MapPickerDialog> {
  late double _selectedLat;
  late double _selectedLng;
  late double _currentZoom;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.latitude;
    _selectedLng = widget.longitude;
    _currentZoom = 15;
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                color: AppColors.primary,
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppColors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Pilih Lokasi di Peta',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),

              // Map
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(_selectedLat, _selectedLng),
                        initialZoom: _currentZoom,
                        onTap: (tapPosition, point) {
                          setState(() {
                            _selectedLat = point.latitude;
                            _selectedLng = point.longitude;
                          });
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.apotrack.mobile',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(_selectedLat, _selectedLng),
                              width: 48,
                              height: 48,
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 48,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Zoom buttons
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withOpacity(0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ZoomButton(
                              icon: Icons.add,
                              onTap: () {
                                setState(() => _currentZoom += 1);
                                _mapController.move(
                                  LatLng(_selectedLat, _selectedLng),
                                  _currentZoom,
                                );
                              },
                            ),
                            const Divider(height: 1, thickness: 1),
                            _ZoomButton(
                              icon: Icons.remove,
                              onTap: () {
                                setState(() => _currentZoom -= 1);
                                _mapController.move(
                                  LatLng(_selectedLat, _selectedLng),
                                  _currentZoom,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Hint text
                    Positioned(
                      bottom: 12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.black.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Ketuk peta untuk memilih lokasi',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tombol aksi
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(color: AppColors.divider),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: const BorderSide(color: AppColors.divider),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: AppColors.textSlate,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onLocationSelected(
                            _selectedLat,
                            _selectedLng,
                          );
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Simpan Lokasi',
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700,
                          ),
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
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ZoomButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }
}