import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/order_service.dart';
import '../../data/services/pharmacy_service.dart';
import '../providers/customer_order_provider.dart';

class BeriUlasanScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String orderNumber;
  final String pharmacyId;
  final String pharmacyName;
  final List<Map<String, dynamic>> items;

  const BeriUlasanScreen({
    super.key,
    required this.orderId,
    required this.orderNumber,
    required this.pharmacyId,
    required this.pharmacyName,
    this.items = const [],
  });

  @override
  ConsumerState<BeriUlasanScreen> createState() => _BeriUlasanScreenState();
}

class _BeriUlasanScreenState extends ConsumerState<BeriUlasanScreen> {
  late final OrderService _orderService;
  int _rating = 0;
  final Set<String> _selectedTags = {};
  final TextEditingController _controller = TextEditingController();
  final FocusNode _fieldFocus = FocusNode();
  bool _sending = false;
  bool _berhasil = false;

  final List<String> _tags = [
    'Pengiriman Cepat',
    'Pelayanan Ramah',
    'Obat Lengkap',
    'Kemasan Aman',
  ];

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Sangat Puas';
      case 5:
        return 'Luar Biasa';
      default:
        return '';
    }
  }

  Future<void> _kirim() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih rating terlebih dahulu')),
      );
      return;
    }

    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis ulasan terlebih dahulu')),
      );
      return;
    }

    if (widget.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada item untuk diulas')),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      await _orderService.submitReview(
        orderId: widget.orderId,
        rating: _rating,
        comment: _controller.text.trim(),
      );

      ref.invalidate(activePharmaciesProvider(null));
      ref.invalidate(myOrdersProvider);
      ref.invalidate(activeOrdersProvider);
      ref.invalidate(customerOrderProvider);

      if (!mounted) return;
      setState(() {
        _sending = false;
        _berhasil = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _orderService = ref.read(orderServiceProvider);
    _fieldFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Beri Ulasan',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _berhasil ? _buildBerhasil() : _buildForm(),
    );
  }

  Widget _buildBerhasil() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(48),
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.success, size: 56),
            ),
            const SizedBox(height: 24),
            const Text(
              'Ulasan Terkirim!',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 24,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Terima kasih! Ulasan kamu\nmembantu pengguna lain.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
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
                  onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
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

  Widget _buildForm() {
    final isFocused = _fieldFocus.hasFocus;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildRatingCard(),
          const SizedBox(height: 16),
          _buildTagsCard(),
          const SizedBox(height: 16),
          _buildFieldCard(isFocused),
          const SizedBox(height: 28),
          _buildKirimButton(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.pharmacyName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      'Pesanan: ',
                      style: TextStyle(fontSize: 12, color: AppColors.textLight),
                    ),
                    Text(
                      widget.orderNumber,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMid,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          const Text(
            'Bagaimana kualitas pesanan Anda?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (i) => GestureDetector(
                onTap: () => setState(() => _rating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: AnimatedScale(
                    duration: const Duration(milliseconds: 150),
                    scale: i < _rating ? 1.1 : 1.0,
                    child: Icon(
                      i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: i < _rating ? Colors.amber : Colors.grey[300],
                      size: 38,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_rating > 0) ...[
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Container(
                key: ValueKey(_ratingLabel),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _ratingLabel,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apa yang paling Anda sukai?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              final sel = _selectedTags.contains(tag);
              return GestureDetector(
                onTap: () => setState(() => sel
                    ? _selectedTags.remove(tag)
                    : _selectedTags.add(tag)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : Colors.white,
                    border: Border.all(
                      color: sel ? AppColors.primary : AppColors.divider,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: sel ? Colors.white : AppColors.textMid,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(bool isFocused) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tulis Ulasan Anda',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
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
              controller: _controller,
              focusNode: _fieldFocus,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w500, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Bagaimana pengalaman Anda?',
                hintStyle: const TextStyle(color: AppColors.textSubtle, fontWeight: FontWeight.w400, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterStyle: const TextStyle(color: AppColors.textLight, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKirimButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _sending ? AppColors.primary.withValues(alpha: 0.6) : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: AppColors.primary.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8)),
          ],
        ),
        child: ElevatedButton(
          onPressed: _sending ? null : _kirim,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _sending
                ? const SizedBox(
                    key: ValueKey('loading'),
                    width: 24, height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Row(
                    key: ValueKey('label'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Kirim Ulasan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
