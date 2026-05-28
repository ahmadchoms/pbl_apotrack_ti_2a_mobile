import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../routes/app_router.dart';
import '../../../data/models/customer_address.dart';
import '../../providers/customer_profile_provider.dart';

class AddressSection extends ConsumerWidget {
  final List<CustomerAddress> addresses;
  final CustomerAddress? primaryAddress;
  final List<CustomerAddress> otherAddresses;
  final VoidCallback? onRefresh;

  const AddressSection({
    super.key,
    required this.addresses,
    this.primaryAddress,
    this.otherAddresses = const [],
    this.onRefresh,
  });

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String id,
    String label,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.dangerLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.danger,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hapus Alamat?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Alamat "$label" akan dihapus permanen dan tidak bisa dikembalikan.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMid,
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Hapus',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(customerProfileProvider.notifier).deleteAddress(id);
      onRefresh?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 12),
            child: Text(
              'ALAMAT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.textMuted,
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _AddressTile(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.textSlate,
                  title: 'Alamat Utama',
                  subtitle: primaryAddress?.displayAddress,
                  isFirst: true,
                  onTap: () => context
                      .push(
                        AppRouter.customerEditAddress,
                        extra: {
                          'isAdd': primaryAddress == null,
                          if (primaryAddress != null)
                            'address': primaryAddress,
                        },
                      )
                      .then((_) => onRefresh?.call()),
                  onDelete: primaryAddress != null
                      ? () => _confirmDelete(
                            context,
                            ref,
                            primaryAddress!.id,
                            primaryAddress!.label,
                          )
                      : null,
                ),
                ...otherAddresses.map(
                  (addr) => Column(
                    children: [
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      _AddressTile(
                        icon: Icons.location_on_outlined,
                        iconColor: AppColors.textMuted,
                        title: addr.label,
                        subtitle: addr.displayAddress,
                        onTap: () => context
                            .push(
                              AppRouter.customerEditAddress,
                              extra: {'isAdd': false, 'address': addr},
                            )
                            .then((_) => onRefresh?.call()),
                        onDelete: () => _confirmDelete(
                          context,
                          ref,
                          addr.id,
                          addr.label,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _AddressTile(
                  icon: Icons.add_location_alt_outlined,
                  iconColor: AppColors.primary,
                  title: 'Tambah Alamat',
                  titleColor: AppColors.primary,
                  isLast: true,
                  onTap: () => context
                      .push(
                        AppRouter.customerEditAddress,
                        extra: {'isAdd': true},
                      )
                      .then((_) => onRefresh?.call()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isFirst;
  final bool isLast;

  const _AddressTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    this.subtitle,
    this.onTap,
    this.onDelete,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: titleColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSlate,
                height: 1.4,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onDelete != null)
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 18,
                ),
              ),
            ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textSubtle,
          ),
        ],
      ),
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
          topRight: isFirst ? const Radius.circular(20) : Radius.zero,
          bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
        ),
      ),
    );
  }
}