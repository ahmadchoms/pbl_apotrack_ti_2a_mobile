import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationHelper {
  /// Memeriksa izin & mengembalikan posisi saat ini jika diizinkan
  static Future<Position?> determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Cek apakah layanan GPS aktif di HP
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return null;
      // Minta pengguna mengaktifkan GPS lewat pengaturan sistem
      final bool? openSettings = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('GPS Tidak Aktif'),
          content: const Text(
            'Layanan lokasi GPS di perangkat Anda dinonaktifkan. Silakan aktifkan GPS untuk mencari apotek terdekat.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Buka Pengaturan'),
            ),
          ],
        ),
      );
      if (openSettings == true) {
        await Geolocator.openLocationSettings();
      }
      return null;
    }

    // 2. Cek izin akses lokasi saat ini
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Izin ditolak oleh pengguna
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Izin ditolak permanen, minta pengguna membuka Pengaturan Aplikasi
      if (context.mounted) {
        _showPermissionDeniedDialog(context);
      }
      return null;
    }

    // 3. Ambil lokasi koordinat
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  /// Konversi Lat/Lng menjadi Alamat Fisik (Reverse Geocoding)
  static Future<String> getAddressFromLatLng(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Susun alamat sederhana yang pas untuk Header Home Screen
        final street = place.street ?? '';
        final subLocality = place.subLocality ?? '';
        final locality = place.locality ?? '';
        final name = place.name ?? '';
        
        final list = [street, subLocality, locality]
            .where((s) => s.isNotEmpty)
            .toList();
            
        if (list.isEmpty && name.isNotEmpty) {
          list.add(name);
        }
        
        return list.join(', ');
      }
    } catch (e) {
      debugPrint('Gagal geocoding: $e');
    }
    return 'Lokasi Terdeteksi GPS';
  }

  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Izin Lokasi Dibutuhkan'),
        content: const Text(
          'ApoTrack mendeteksi bahwa izin lokasi telah dinonaktifkan secara permanen. '
          'Silakan aktifkan izin lokasi di pengaturan perangkat Anda untuk mencari apotek terdekat.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }
}
