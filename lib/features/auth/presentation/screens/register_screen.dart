import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  // --- CONTROLLERS ---
  final PageController _pageController = PageController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _isObscure = true;
  final _otpCtrl = TextEditingController();

  // --- FOCUS NODES ---
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _otpFocus = FocusNode();

  // --- STATE ---
  int _currentStep = 0;
  String? _emailError;

  // --- ANIMATION ---
  late AnimationController _progressAnimCtrl;

  final _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _progressAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_nameFocus);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressAnimCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _otpCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // NAVIGASI ANTAR STEP
  // ─────────────────────────────────────────────
  void _animateToStep(int nextStep) {
    print("DEBUG: Mencoba berpindah ke Step Index $nextStep...");
    
    // 1. Update state
    if (mounted) {
      setState(() => _currentStep = nextStep);
    }

    try {
      // 2. Update progress bar
      _progressAnimCtrl.animateTo(
        (nextStep + 1) / _totalSteps,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );

      // 3. Pindah halaman dengan animasi halus
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          nextStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        ).then((_) {
          print("DEBUG: Berhasil berpindah ke halaman $nextStep");
        });
      } else {
        print("DEBUG ERROR: PageController tidak memiliki client!");
      }
    } catch (e) {
      print("DEBUG ERROR di _animateToStep: $e");
    }
  }

  /// Dipanggil saat tombol "Lanjut" ditekan.
  /// Step 1 memanggil API, step lain hanya animasi.
  Future<void> _goToNextStep() async {
    if (_currentStep == 0) {
      // Step 0 → 1: hanya validasi lokal + animasi
      _animateToStep(1);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FocusScope.of(context).requestFocus(_emailFocus);
      });
      return;
    }

    if (_currentStep == 1) {
      // Step 1 → 2: validasi + panggil API requestOtp
      final email = _emailCtrl.text.trim();
      if (!email.endsWith('@gmail.com')) {
        setState(() => _emailError = 'Email harus menggunakan @gmail.com');
        return;
      }
      setState(() => _emailError = null);
      await _handleRequestOtp();
      return;
    }

    if (_currentStep == 2) {
      // Step 2: panggil API verifyOtp
      await _handleVerifyOtp();
    }
  }

  void _goToPrevStep() {
    if (_currentStep > 0) {
      _animateToStep(_currentStep - 1);
    } else {
      context.pop();
    }
  }

  bool get _isNextEnabled {
    switch (_currentStep) {
      case 0:
        return _nameCtrl.text.trim().isNotEmpty;
      case 1:
        return _emailCtrl.text.trim().isNotEmpty &&
            _phoneCtrl.text.trim().isNotEmpty &&
            _passwordCtrl.text.isNotEmpty;
      case 2:
        return _otpCtrl.text.trim().length ==
            6; // OTP harus 6 digit sesuai backend
      default:
        return false;
    }
  }

  // ─────────────────────────────────────────────
  // API HANDLERS
  // ─────────────────────────────────────────────
  Future<void> _handleRequestOtp() async {
    try {
      debugPrint("DEBUG: Memulai Request OTP untuk ${ _emailCtrl.text.trim()}");
      await ref.read(authNotifierProvider.notifier).requestOtp(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            password: _passwordCtrl.text,
          );
      
      debugPrint("DEBUG: Request OTP Berhasil, Berpindah ke Step 2 (OTP)");
      if (!mounted) return;
      
      // Sukses → animasi ke step OTP
      _animateToStep(2);
      
      // Beri sedikit delay sebelum request focus agar widget sempat render
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _currentStep == 2) {
          FocusScope.of(context).requestFocus(_otpFocus);
          print("DEBUG: Focus requested on OTP field");
        }
      });
    } catch (e) {
      debugPrint("DEBUG ERROR OTP: $e");
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _handleVerifyOtp() async {
    try {
      await ref
          .read(authNotifierProvider.notifier)
          .verifyOtp(email: _emailCtrl.text.trim(), otp: _otpCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Pendaftaran berhasil! Silakan masuk.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      context.go(AppRouter.login);
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepName(),
                  _buildStepContact(),
                  _buildStepOtp(),
                ],
              ),
            ),
            _buildBottomBar(isLoading),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HEADER: Back + Progress bar + Dots
  // ─────────────────────────────────────────────
  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: _goToPrevStep,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textDark,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Langkah ${_currentStep + 1} dari $_totalSteps',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textLight,
                          ),
                        ),
                        Text(
                          '${(((_currentStep + 1) / _totalSteps) * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedBuilder(
                      animation: _progressAnimCtrl,
                      builder: (context, child) {
                        final targetProgress = (_currentStep + 1) / _totalSteps;
                        return TweenAnimationBuilder<double>(
                          tween: Tween<double>(
                            begin: _currentStep / _totalSteps,
                            end: targetProgress,
                          ),
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          builder: (context, value, _) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: value,
                                minHeight: 6,
                                backgroundColor: AppColors.divider,
                                valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalSteps, (i) {
              final isActive = i == _currentStep;
              final isDone = i < _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDone || isActive
                      ? AppColors.primary
                      : AppColors.divider,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 0: Nama
  // ─────────────────────────────────────────────
  Widget _buildStepName() {
    return _StepWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepEmoji(emoji: '👋'),
          const SizedBox(height: 24),
          const Text(
            'Siapa namamu?',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Nama ini akan digunakan sebagai identitasmu di aplikasi.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _buildInputField(
            controller: _nameCtrl,
            focusNode: _nameFocus,
            hint: 'Contoh: Ahmad Fauzi',
            label: 'Nama Lengkap',
            icon: Icons.person_outline_rounded,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _goToNextStep(),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 1: Kontak (Email + Telepon)
  // ─────────────────────────────────────────────
  Widget _buildStepContact() {
    return _StepWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepEmoji(emoji: '📱'),
          const SizedBox(height: 24),
          const Text(
            'Masukkan\nkontakmu',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Kami butuh email dan nomor teleponmu untuk keamanan akun.',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textLight,
              fontWeight: FontWeight.w500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _buildInputField(
            controller: _emailCtrl,
            focusNode: _emailFocus,
            hint: 'contoh@gmail.com',
            label: 'Alamat Email',
            icon: Icons.mail_outline_rounded,
            type: TextInputType.emailAddress,
            errorText: _emailError,
            onChanged: (v) {
              setState(() {
                if (v.trim().endsWith('@gmail.com')) _emailError = null;
              });
            },
            onSubmitted: (_) =>
                FocusScope.of(context).requestFocus(_phoneFocus),
          ),
          const SizedBox(height: 16),
          _buildInputField(
            controller: _phoneCtrl,
            focusNode: _phoneFocus,
            hint: '+62 812 3456 7890',
            label: 'Nomor Telepon',
            icon: Icons.phone_outlined,
            type: TextInputType.phone,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _goToNextStep(),
          ),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Kata Sandi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMid,
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _passwordFocus.hasFocus
                        ? AppColors.primary
                        : AppColors.divider,
                    width: 1.5,
                  ),
                  boxShadow: _passwordFocus.hasFocus
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.12),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: TextField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _isObscure,
                  textInputAction: TextInputAction.done,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => _goToNextStep(),
                  style: const TextStyle(
                    color: AppColors.textDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    hintText: '••••••••',
                    hintStyle: const TextStyle(
                      color: AppColors.textSubtle,
                      fontWeight: FontWeight.w400,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      color: _passwordFocus.hasFocus
                          ? AppColors.primary
                          : AppColors.textLight,
                      size: 20,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () => setState(() => _isObscure = !_isObscure),
                      icon: Icon(
                        _isObscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textLight,
                        size: 20,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // STEP 2: OTP
  // ─────────────────────────────────────────────
  Widget _buildStepOtp() {
    return _StepWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepEmoji(emoji: '🔐'),
          const SizedBox(height: 24),
          const Text(
            'Masukkan\nkode OTP',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: -0.8,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textLight,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'Kode 6 digit telah dikirim ke '),
                TextSpan(
                  text: _emailCtrl.text.trim(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Bungkus dengan GestureDetector agar saat kotak diklik, keyboard muncul
          GestureDetector(
            onTap: () => _otpFocus.requestFocus(),
            child: Stack(
              children: [
                _buildOtpBoxes(),
                // TextField Tersembunyi berada tepat di atas kotak agar mudah dipicu
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: _otpCtrl,
                      focusNode: _otpFocus,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      autofillHints: const [AutofillHints.oneTimeCode],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Text(
                  'Tidak menerima kode?',
                  style: TextStyle(
                    color: AppColors.textLight,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () => _handleRequestOtp(),
                  child: const Text(
                    'Kirim Ulang Kode',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
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

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(6, (i) {
        final char = i < _otpCtrl.text.length ? _otpCtrl.text[i] : '';
        final isActive = i == _otpCtrl.text.length;
        final isFilled = i < _otpCtrl.text.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 58,
          decoration: BoxDecoration(
            color: isFilled
                ? AppColors.primaryLight
                : isActive
                ? Colors.white
                : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFilled
                  ? AppColors.primary.withOpacity(0.5)
                  : isActive
                  ? AppColors.primary
                  : AppColors.divider,
              width: isActive ? 2 : 1.5,
            ),
          ),
          child: Center(
            child: Text(
              char,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ),
        );
      }),
    );
  }

  // ─────────────────────────────────────────────
  // BOTTOM BAR
  // ─────────────────────────────────────────────
  Widget _buildBottomBar(bool isLoading) {
    final buttonLabel = _currentStep == 2 ? 'Selesaikan Pendaftaran' : 'Lanjut';
    final buttonIcon = _currentStep == 2
        ? Icons.check_circle_outline_rounded
        : Icons.arrow_forward_rounded;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // TextField dipindah ke _buildStepOtp
          AnimatedOpacity(
            opacity: _isNextEnabled ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: _isNextEnabled
                      ? const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                        )
                      : LinearGradient(
                          colors: [Colors.grey.shade400, Colors.grey.shade500],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isNextEnabled
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: ElevatedButton(
                  onPressed: (_isNextEnabled && !isLoading)
                      ? _goToNextStep
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              buttonLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(buttonIcon, color: Colors.white, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // INPUT FIELD REUSABLE
  // ─────────────────────────────────────────────
  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required String label,
    required IconData icon,
    TextInputType? type,
    String? errorText,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textMid,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError
                  ? AppColors.danger
                  : focusNode.hasFocus
                  ? AppColors.primary
                  : AppColors.divider,
              width: 1.5,
            ),
            boxShadow: focusNode.hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: type,
            textInputAction: TextInputAction.next,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: AppColors.textSubtle,
                fontWeight: FontWeight.w400,
                fontSize: 15,
              ),
              prefixIcon: Icon(
                icon,
                color: focusNode.hasFocus
                    ? AppColors.primary
                    : AppColors.textLight,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.danger,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  errorText,
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// HELPER WIDGETS
// ─────────────────────────────────────────────

class _StepWrapper extends StatelessWidget {
  const _StepWrapper({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: child,
    );
  }
}

class _StepEmoji extends StatelessWidget {
  const _StepEmoji({required this.emoji});
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
    );
  }
}
