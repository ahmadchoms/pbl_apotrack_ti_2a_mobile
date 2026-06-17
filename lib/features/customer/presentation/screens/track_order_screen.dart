import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../staff/data/models/order.dart';
import '../providers/customer_order_provider.dart';
import '../widgets/order_history/track_order_eta_card.dart';
import '../widgets/order_history/track_order_courier_card.dart';
import '../widgets/order_history/track_order_stepper.dart';

class TrackOrderScreen extends ConsumerWidget {
  final Order order;

  const TrackOrderScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingAsync = ref.watch(orderTrackingProvider(order.id));
    final detailAsync = ref.watch(orderDetailProvider(order.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDark, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Lacak Pesanan',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.primary),
            onPressed: () {
              ref.invalidate(orderTrackingProvider(order.id));
              ref.invalidate(orderDetailProvider(order.id));
            },
          ),
        ],
      ),
      body: trackingAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            _buildErrorState(context, ref, e.toString()),
        data: (tracking) => detailAsync.when(
          loading: () =>
              _buildContent(context, ref, tracking, null),
          error: (e, _) =>
              _buildContent(context, ref, tracking, null),
          data: (detail) =>
              _buildContent(context, ref, tracking, detail),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref,
      DeliveryTracking tracking, Order? detail) {
    final pharmacyName =
        order.pharmacy['name']?.toString() ?? '—';
    final pharmacyAddress =
        order.pharmacy['address']?.toString() ?? '—';

    final addressData = detail?.address ?? order.address;
    final deliveryAddress =
        addressData?['address_detail']?.toString() ??
            addressData?['complete_address']?.toString() ??
            '—';
    final deliveryLabel =
        addressData?['label']?.toString() ?? 'Tujuan';

    // Tombol konfirmasi hanya muncul saat DELIVERED
    final isDelivered = tracking.status == 'delivered';

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TrackOrderEtaCard(tracking: tracking),
              const SizedBox(height: 12),
              TrackOrderCourierCard(tracking: tracking),
              const SizedBox(height: 20),
              TrackOrderStepper(trackingStatus: tracking.status),
              const SizedBox(height: 20),
              _buildAddressCard(
                icon: Icons.store_rounded,
                label: 'ASAL APOTEK',
                title: pharmacyName,
                subtitle: pharmacyAddress,
              ),
              const SizedBox(height: 12),
              _buildAddressCard(
                icon: Icons.location_on_rounded,
                label: 'ALAMAT PENGIRIMAN',
                title: deliveryLabel,
                subtitle: deliveryAddress,
                iconColor: AppColors.danger,
              ),
              const SizedBox(height: 24),

              // Tombol konfirmasi diterima (hanya saat DELIVERED)
              if (isDelivered)
                _ConfirmReceivedButton(orderId: order.id)
              else
                // Tombol tutup biasa saat belum DELIVERED
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.pop(),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        color: AppColors.textSlate,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_shipping_outlined,
                size: 56, color: AppColors.textMuted),
            const SizedBox(height: 16),
            const Text(
              'Data tracking belum tersedia',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSlate, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(orderTrackingProvider(order.id));
                ref.invalidate(orderDetailProvider(order.id));
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard({
    required IconData icon,
    required String label,
    required String title,
    required String subtitle,
    Color iconColor = AppColors.primary,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSlate,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget tombol konfirmasi dengan dialog ────────────────────────

class _ConfirmReceivedButton extends ConsumerStatefulWidget {
  final String orderId;

  const _ConfirmReceivedButton({required this.orderId});

  @override
  ConsumerState<_ConfirmReceivedButton> createState() =>
      _ConfirmReceivedButtonState();
}

class _ConfirmReceivedButtonState
    extends ConsumerState<_ConfirmReceivedButton> {
  bool _isLoading = false;

  Future<void> _showConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.successLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.success,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pesanan Diterima?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Konfirmasi bahwa pesanan sudah kamu terima dengan lengkap dan dalam kondisi baik.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSlate,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(
                            color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Belum',
                        style: TextStyle(
                          color: AppColors.textSlate,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        'Ya, Diterima',
                        style:
                            TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(customerOrderProvider.notifier)
        .confirmReceived(widget.orderId);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil dikonfirmasi diterima!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Pop kembali ke order history
      if (mounted) context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengkonfirmasi pesanan'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _showConfirmDialog,
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: AppColors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.check_circle_outline_rounded,
                size: 20),
        label: Text(
          _isLoading ? 'Memproses...' : 'Pesanan Diterima',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}