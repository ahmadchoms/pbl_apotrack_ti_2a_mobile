import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _identifierFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 52),
                    _buildHeader(),
                    const SizedBox(height: 48),
                    _buildIdentifierField(),
                    const SizedBox(height: 16),
                    _buildPasswordField(),
                    const SizedBox(height: 10),
                    _buildForgotPassword(),
                    const SizedBox(height: 28),
                    _buildLoginButton(isLoading),
                    const SizedBox(height: 24),
                    _buildFooter(),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 14),
              SizedBox(width: 6),
              Text(
                'ApoTrack',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Selamat datang\nkembali! 👋',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.textDark,
            letterSpacing: -0.8,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Silakan masuk ke akun ApoTrack-mu.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // FIELDS
  // ─────────────────────────────────────────────
  Widget _buildIdentifierField() {
    final isFocused = _identifierFocus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Email atau Nomor Telepon'),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused ? AppColors.primary : AppColors.divider,
              width: isFocused ? 2 : 1.5,
            ),
            boxShadow: isFocused
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))]
                : [],
          ),
          child: TextField(
            controller: _identifierCtrl,
            focusNode: _identifierFocus,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'contoh@gmail.com',
              hintStyle: const TextStyle(color: AppColors.textSubtle, fontWeight: FontWeight.w400, fontSize: 15),
              prefixIcon: Icon(Icons.alternate_email_rounded,
                  color: isFocused ? AppColors.primary : AppColors.textLight, size: 20),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    final isFocused = _passwordFocus.hasFocus;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Password'),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused ? AppColors.primary : AppColors.divider,
              width: isFocused ? 2 : 1.5,
            ),
            boxShadow: isFocused
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 16, offset: const Offset(0, 4))]
                : [],
          ),
          child: TextField(
            controller: _passwordCtrl,
            focusNode: _passwordFocus,
            obscureText: _isObscure,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleLogin(),
            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 1),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(color: AppColors.textSubtle, fontWeight: FontWeight.w400, fontSize: 18, letterSpacing: 2),
              prefixIcon: Icon(Icons.lock_outline_rounded,
                  color: isFocused ? AppColors.primary : AppColors.textLight, size: 20),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _isObscure = !_isObscure),
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isObscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    key: ValueKey(_isObscure),
                    color: AppColors.textLight,
                    size: 20,
                  ),
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // ACTIONS
  // ─────────────────────────────────────────────
  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => context.push(AppRouter.forgotPassword),
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Text(
            'Lupa Password?',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isLoading) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isLoading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    key: ValueKey('label'),
                    'Masuk',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.3),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Center(
      child: GestureDetector(
        onTap: () => context.push(AppRouter.register),
        child: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            children: [
              TextSpan(text: 'Belum punya akun? ', style: TextStyle(color: AppColors.textLight)),
              TextSpan(text: 'Daftar sekarang',
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMid));
  }

  // ─────────────────────────────────────────────
  // HANDLER: Login dengan Riverpod
  // ─────────────────────────────────────────────
  Future<void> _handleLogin() async {
    final email = _identifierCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) return;
    FocusScope.of(context).unfocus();

    try {
      final user = await ref.read(authNotifierProvider.notifier).login(
        emailOrPhone: email,
        password: password,
      );

      if (!context.mounted) return;

      if (!kIsWeb) {
        final dio = ref.read(dioProvider);
        await PushNotificationService.updateDeviceToken(dio, user.id);
      }

      if (!context.mounted) return;

      if (user.isStaff || email.toLowerCase().contains('@apotek')) {
        // ignore: use_build_context_synchronously
        context.go(AppRouter.staffHome);
      } else {
        // ignore: use_build_context_synchronously
        context.go(AppRouter.customerHome);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }
}
