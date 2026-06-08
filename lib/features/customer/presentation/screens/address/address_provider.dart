import 'package:flutter/material.dart';
import 'address_model.dart';

/// Simple ChangeNotifier untuk state alamat.
class AddressProvider extends ChangeNotifier {
  AddressModel? _selectedAddress;
  List<AddressModel> _favorites = [];
  List<AddressModel> _recents = [];

  AddressModel? get selectedAddress => _selectedAddress;
  List<AddressModel> get favorites => List.unmodifiable(_favorites);
  List<AddressModel> get recents => List.unmodifiable(_recents);

  void loadFromApi(List<AddressModel> addresses) {
    _favorites = List.from(addresses);
    _recents = [];

    // Auto-select alamat primary, fallback ke pertama kalo gak ada
    _selectedAddress = addresses.cast<AddressModel?>().firstWhere(
      (a) => a!.isPrimary,
      orElse: () => addresses.isNotEmpty ? addresses.first : null,
    );

    notifyListeners();
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void updatePrimaryFlags(String primaryId) {
    _favorites = _favorites.map((a) => a.copyWith(isPrimary: a.id == primaryId)).toList();
    if (_selectedAddress != null) {
      _selectedAddress = _selectedAddress!.copyWith(isPrimary: _selectedAddress!.id == primaryId);
    }
    notifyListeners();
  }

  void clearAddress() {
    _selectedAddress = null;
    notifyListeners();
  }

  void addFavorite(AddressModel address) {
    _favorites.add(address);
    notifyListeners();
  }

  void updateFavorite(AddressModel updated) {
    final idx = _favorites.indexWhere((a) => a.id == updated.id);
    if (idx != -1) {
      _favorites[idx] = updated;
      if (_selectedAddress?.id == updated.id) {
        _selectedAddress = updated;
      }
      notifyListeners();
    }
  }

  void deleteFavorite(String id) {
    _favorites.removeWhere((a) => a.id == id);
    if (_selectedAddress?.id == id) _selectedAddress = null;
    notifyListeners();
  }
}
