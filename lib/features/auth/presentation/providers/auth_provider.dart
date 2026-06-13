import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../data/models/user_model.dart';
import '../../data/services/auth_service.dart';

// ─────────────────────────────────────────────
// STATE
// ─────────────────────────────────────────────

class AuthState {
  const AuthState({this.user, this.isLoading = false, this.error});
  final UserModel? user;
  final bool isLoading;
  final String? error;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

// ─────────────────────────────────────────────
// NOTIFIER
// ─────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._authService) : super(const AuthState(isLoading: true)) {
    Future.delayed(Duration.zero, () => restoreSession());
  }

  final AuthService _authService;

  void _stopLoading() {
    if (mounted) {
      state = state.copyWith(isLoading: false);
    }
  }

  // ── CHECK SESSION (Startup) ────────────────────
  Future<void> restoreSession() async {
    state = state.copyWith(isLoading: true);
    try {
      final user = await _authService.restoreSession();
      if (mounted) {
        state = state.copyWith(user: user, isLoading: false);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(user: null, isLoading: false);
      }
    } finally {
      _stopLoading();
    }
  }

  // ── LOGIN ──────────────────────────────────────
  Future<UserModel> login({
    required String emailOrPhone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );
      state = state.copyWith(user: user, isLoading: false);
      return user;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  // ── LOGOUT ─────────────────────────────────────
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _authService.logout();
    } finally {
      state = const AuthState(isLoading: false);
      _stopLoading();
    }
  }

  // ── FORGOT PASSWORD ────────────────────────────
  Future<void> forgotPassword({required String email}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.forgotPassword(email: email);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  // ── REQUEST OTP ────────────────────────────────
  Future<void> requestOtp({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _authService.requestRegistrationOtp(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  // ── VERIFY OTP ─────────────────────────────────
  Future<bool> verifyOtp({required String email, required String otp}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _authService.finalizeRegistration(
        email: email,
        otp: otp,
      );
      if (user != null) {
        state = state.copyWith(user: user, isLoading: false);
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      _stopLoading();
    }
  }

  // ── UPDATE PROFILE ─────────────────────────────
  Future<void> updateProfileData({
    required String username,
    required String email,
    String? phone,
    dynamic imageFile, // Bisa XFile atau File
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final formData = FormData.fromMap({
        'username': username,
        'email': email,
        if (phone != null) 'phone': phone,
        '_method': 'PUT', // Penting untuk Laravel Multipart Update
      });

      if (imageFile != null) {
        final path = imageFile.path;
        formData.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(path, filename: 'profile.jpg'),
          ),
        );
      }

      final updatedData = await _authService.updateProfile(formData);
      final updatedUser = UserModel.fromJson(updatedData);

      if (mounted) {
        state = state.copyWith(user: updatedUser, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    } finally {
      _stopLoading();
    }
  }
}

// ─────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final service = ref.watch(authServiceProvider);
  return AuthNotifier(service);
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoading;
});
