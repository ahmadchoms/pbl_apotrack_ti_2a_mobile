import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/customer_profile_provider.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/address_section.dart';
import '../widgets/profile/menu_section.dart';
import '../widgets/profile/confirm_dialog.dart';
import '../widgets/profile/delete_account_password_dialog.dart';
import '../widgets/profile/scan_qr_invitation_card.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

class AccountHubScreen extends ConsumerStatefulWidget {
  const AccountHubScreen({super.key});

  @override
  ConsumerState<AccountHubScreen> createState() => _AccountHubScreenState();
}

class _AccountHubScreenState extends ConsumerState<AccountHubScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(customerProfileProvider.notifier).loadAll(),
    );
  }

  Future<void> _handleLogout() async {
    try {
      // 1. Logout dari Riverpod provider
      await ref.read(customerProfileProvider.notifier).logout();

      // 2. Invalidate auth provider agar trigger GoRouter redirect logic
      ref.invalidate(authNotifierProvider);

      print('✅ Logout complete, redirecting to login...');
    } catch (e) {
      // Tetap lanjut redirect meski ada error
      print('⚠️ Logout error: $e');
    } finally {
      // 3. Direct redirect ke login (failsafe jika GoRouter redirect tidak trigger)
      if (mounted) {
        context.go(AppRouter.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customerProfileProvider);
    final profile = state.profile;
    final primaryAddr = state.addresses.where((a) => a.isPrimary).firstOrNull;
    final otherAddrs = state.addresses.where((a) => !a.isPrimary).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: state.isLoading && profile == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(customerProfileProvider.notifier).loadAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // ── Error banner ──────────────────
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

                    // ── Profile Header ──────────────
                    ProfileHeader(
                      name: profile?.username ?? '—',
                      phone: profile?.phone ?? '—',
                      email: profile?.email ?? '—',
                      initials: profile?.initials ?? '?',
                      avatarUrl: profile?.avatarUrl,
                    ),

                    const SizedBox(height: 24),

                    // ── Alamat ──────────────────────
                    AddressSection(
                      addresses: state.addresses,
                      primaryAddress: primaryAddr,
                      otherAddresses: otherAddrs,
                      onRefresh: () =>
                          ref.read(customerProfileProvider.notifier).loadAll(),
                    ),

                    const SizedBox(height: 8),

                    // ── Pengaturan Akun ─────────────
                    MenuSection(
                      title: 'PENGATURAN AKUN',
                      items: [
                        MenuItemTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Edit Profil',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerEditProfileScreen(),
                            ),
                          ).then(
                            (_) => ref
                                .read(customerProfileProvider.notifier)
                                .loadAll(),
                          ),
                        ),
                        MenuItemTile(
                          icon: Icons.lock_outline_rounded,
                          title: 'Ubah Password',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CustomerChangePasswordScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── Join Staff ──────────────────
                    MenuSection(
                      title: 'JOIN SEBAGAI STAFF APOTEK',
                      items: [
                        MenuItemCustom(child: const ScanQrInvitationCard()),
                      ],
                    ),

                    // ── Lainnya ─────────────────────
                    MenuSection(
                      title: 'LAINNYA',
                      items: [
                        MenuItemTile(
                          icon: Icons.help_outline_rounded,
                          title: 'Pusat Bantuan',
                          onTap: () {},
                        ),
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
                            iconColor: AppColors.warning,
                            iconBgColor: AppColors.warningLight,
                            title: 'Keluar Akun?',
                            message:
                                'Kamu akan keluar dari akunmu. '
                                'Kamu bisa login kembali kapan saja.',
                            confirmLabel: 'Ya, Keluar',
                            confirmColor: AppColors.warning,
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
                        color: Color(0xFF94A3B8),
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
