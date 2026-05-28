// lib/features/customer/presentation/providers/customer_profile_provider.dart
// customer_service.dart dan customer_repository.dart sudah DIHAPUS.
// Semua fungsi (profil + alamat) sudah ada di staff_service.dart
// dan staff_repository.dart.
// File ini hanya alias agar import lama di screen customer tidak perlu diubah.

export '../../../../features/staff/presentation/providers/staff_provider.dart'
    show ProfileNotifier, ProfileState, profileProvider;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/staff/presentation/providers/staff_provider.dart';

/// Alias ke profileProvider — semua screen customer yang pakai
/// customerProfileProvider otomatis diarahkan tanpa ubah satu baris pun.
final customerProfileProvider = profileProvider;