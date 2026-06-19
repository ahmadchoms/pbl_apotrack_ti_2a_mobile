import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationHelper {
  static Future<Position?> determinePosition(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!context.mounted) return null;
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

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showPermissionDeniedDialog(context);
      }
      return null;
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  static Future<String> getAddressFromLatLng(
    double latitude,
    double longitude,
  ) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        final name = place.name ?? '';
        final thoroughfare = place.thoroughfare ?? '';
        final subThoroughfare = place.subThoroughfare ?? '';
        final subLocality = place.subLocality ?? '';
        final locality = place.locality ?? '';

        final List<String> parts = [];

        if (name.isNotEmpty && !name.contains('+') && name != subThoroughfare) {
          parts.add(name);
        }

        if (thoroughfare.isNotEmpty) {
          if (subThoroughfare.isNotEmpty) {
            parts.add('$thoroughfare No. $subThoroughfare');
          } else {
            parts.add(thoroughfare);
          }
        }

        if (subLocality.isNotEmpty) {
          parts.add(subLocality);
        }

        if (locality.isNotEmpty) {
          parts.add(locality);
        }

        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
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
