import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/staff_provider.dart';
import '../../../customer/presentation/providers/customer_order_provider.dart';
import '../../../customer/presentation/widgets/profile/address_section.dart';
import '../../../customer/presentation/widgets/profile/menu_section.dart';
import '../../../customer/presentation/widgets/profile/confirm_dialog.dart';
import '../../../customer/presentation/widgets/profile/delete_account_password_dialog.dart';
import '../../../customer/presentation/widgets/profile/scan_qr_invitation_card.dart';

class StaffProfileScreen extends ConsumerStatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  ConsumerState<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends ConsumerState<StaffProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadAll());
  }

  Future<void> _handleLogout() async {
    try {
      await ref.read(profileProvider.notifier).logout();
      // Invalidate semua provider agar data customer lama tidak tersisa
      ref.invalidate(customerOrderProvider);
      ref.invalidate(profileProvider);
      ref.invalidate(authNotifierProvider);
    } catch (e) {
      debugPrint('⚠️ Logout error: $e');
    } finally {
      if (mounted) context.go(AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final profile = state.profile;

    final isCustomer = profile?.isCustomer ?? true;

    final primaryAddr = isCustomer
        ? state.addresses.where((a) => a.isPrimary).firstOrNull
        : null;
    final otherAddrs = isCustomer
        ? state.addresses.where((a) => !a.isPrimary).toList()
        : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: state.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(profileProvider.notifier).loadAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    if (state.error != null)
                      Container(
                        width: double.infinity,
                        color: AppColors.dangerLight,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          state.error!,
                          style: const TextStyle(
                            color: AppColors.danger,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(
                        top: 80,
                        bottom: 40,
                        left: 24,
                        right: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.black.withValues(alpha: 0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.surfaceLight,
                              backgroundImage:
                                  (profile?.avatarUrl != null &&
                                      profile!.avatarUrl!.isNotEmpty)
                                  ? NetworkImage(profile.avatarUrl!)
                                        as ImageProvider
                                  : null,
                              child:
                                  (profile?.avatarUrl == null ||
                                      profile!.avatarUrl!.isEmpty)
                                  ? Text(
                                      profile?.username
                                              .trim()
                                              .split(' ')
                                              .take(2)
                                              .map((w) => w[0].toUpperCase())
                                              .join() ??
                                          '?',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 20),

                          Text(
                            profile?.username ?? '—',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),

                          Text(
                            profile?.email ?? '—',
                            style: const TextStyle(
                              color: AppColors.textMid,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              profile?.role ?? '—',
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),

                          if (!isCustomer && profile?.pharmacyName != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              profile!.pharmacyName!,
                              style: const TextStyle(
                                color: AppColors.textMid,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (isCustomer)
                      AddressSection(
                        addresses: state.addresses,
                        primaryAddress: primaryAddr,
                        otherAddresses: otherAddrs.cast(),
                        onRefresh: () =>
                            ref.read(profileProvider.notifier).loadAll(),
                      ),

                    if (isCustomer) const SizedBox(height: 8),

                    MenuSection(
                      title: 'PENGATURAN AKUN',
                      items: [
                        MenuItemTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Profil',
                          onTap: () {
                            final route = isCustomer
                                ? AppRouter.customerEditProfile
                                : AppRouter.staffEditProfile;
                            context
                                .push(route)
                                .then(
                                  (_) => ref
                                      .read(profileProvider.notifier)
                                      .fetchProfile(),
                                );
                          },
                        ),
                        MenuItemTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Ubah Kata Sandi',
                          onTap: () {
                            final route = isCustomer
                                ? AppRouter.customerChangePassword
                                : AppRouter.staffChangePassword;
                            context.push(route);
                          },
                        ),
                      ],
                    ),

                    if (!isCustomer)
                      MenuSection(
                        title: 'RIWAYAT AKTIVITAS',
                        items: [
                          MenuItemTile(
                            icon: Icons.history_rounded,
                            title: 'Riwayat Aktivitas Anda',
                            onTap: () =>
                                context.push(AppRouter.staffActivityHistory),
                          ),
                        ],
                      ),

                    if (isCustomer)
                      MenuSection(
                        title: 'JOIN SEBAGAI STAFF APOTEK',
                        items: [
                          MenuItemCustom(child: const ScanQrInvitationCard()),
                        ],
                      ),

                    MenuSection(
                      title: 'LAINNYA',
                      items: [
                        if (isCustomer)
                          MenuItemTile(
                            icon: Icons.delete_outline_rounded,
                            title: 'Hapus Akun',
                            isDestructive: true,
                            onTap: () => ConfirmDialog.show(
                              context,
                              icon: Icons.delete_forever_rounded,
                              iconColor: AppColors.danger,
                              iconBgColor: AppColors.dangerLight,
                              title: 'Hapus Akun?',
                              message:
                                  'Tindakan ini bersifat permanen. Seluruh '
                                  'data, riwayat pesanan, dan informasi '
                                  'akunmu akan dihapus dan tidak dapat '
                                  'dipulihkan.',
                              confirmLabel: 'Ya, Hapus Akun',
                              confirmColor: AppColors.danger,
                              onConfirm: () {
                                Navigator.pop(context);
                                DeleteAccountPasswordDialog.show(context);
                              },
                            ),
                          ),

                        MenuItemTile(
                          icon: Icons.logout_rounded,
                          title: 'Keluar / Logout',
                          isDestructive: true,
                          onTap: () => ConfirmDialog.show(
                            context,
                            icon: Icons.logout_rounded,
                            iconColor: AppColors.danger,
                            iconBgColor: AppColors.dangerLight,
                            title: 'Keluar Akun?',
                            message:
                                'Kamu akan keluar dari akunmu. '
                                'Kamu bisa login kembali kapan saja.',
                            confirmLabel: 'Ya, Keluar',
                            confirmColor: AppColors.danger,
                            onConfirm: () {
                              Navigator.pop(context);
                              _handleLogout();
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),
                    const Text(
                      'ApoTrack v1.0.0',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
