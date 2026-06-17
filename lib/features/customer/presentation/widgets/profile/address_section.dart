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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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

  Future<void> _showOtherAddressesSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => _OtherAddressesSheet(
          scrollController: scrollController,
          otherAddresses: otherAddresses,
          onSelect: (addr) async {
            Navigator.pop(ctx);
            try {
              await ref
                  .read(customerProfileProvider.notifier)
                  .setPrimaryAddress(addr.id);
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
          },
          onEdit: (addr) {
            Navigator.pop(ctx);
            context
                .push(
                  AppRouter.customerEditAddress,
                  extra: {'isAdd': false, 'address': addr},
                )
                .then((_) => onRefresh?.call());
          },
          onDelete: (addr) {
            Navigator.pop(ctx);
            _confirmDelete(context, ref, addr.id, addr.label);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasOthers = otherAddresses.isNotEmpty;

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
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Primary address tile
                _AddressTile(
                  icon: Icons.location_on_outlined,
                  iconColor: AppColors.textSlate,
                  title: 'Alamat Utama',
                  subtitle: primaryAddress?.displayAddress,
                  isFirst: true,
                  isLast: !hasOthers,
                  onTap: () => context
                      .push(
                        AppRouter.customerEditAddress,
                        extra: {
                          'isAdd': primaryAddress == null,
                          if (primaryAddress != null) 'address': primaryAddress,
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

                // "Lihat Lainnya" button — only shown when other addresses exist
                if (hasOthers) ...[
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  _AddressTile(
                    icon: Icons.expand_circle_down_outlined,
                    iconColor: AppColors.primary,
                    title: 'Lihat Lainnya',
                    titleColor: AppColors.primary,
                    badge: otherAddresses.length,
                    isLast: true,
                    onTap: () => _showOtherAddressesSheet(context, ref),
                  ),
                ],

                // "Tambah Alamat" is shown via the edit screen, not here
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet: list of other addresses to pick as primary
// ---------------------------------------------------------------------------

class _OtherAddressesSheet extends StatelessWidget {
  final List<CustomerAddress> otherAddresses;
  final ValueChanged<CustomerAddress> onSelect;
  final ValueChanged<CustomerAddress> onEdit;
  final ValueChanged<CustomerAddress> onDelete;
  final ScrollController scrollController;

  const _OtherAddressesSheet({
    required this.otherAddresses,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding =
        MediaQuery.of(context).viewInsets.bottom +
        MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // ── Fixed header (not scrollable) ──────────────────────────────
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pilih Alamat Utama',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Text(
                  '${otherAddresses.length} alamat',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Pilih salah satu untuk dijadikan alamat utama.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMid,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          // ── Scrollable address list ─────────────────────────────────────
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: EdgeInsets.only(bottom: bottomPadding + 12),
              itemCount: otherAddresses.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 20, endIndent: 20),
              itemBuilder: (_, i) {
                final addr = otherAddresses[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    addr.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  subtitle: addr.displayAddress != null
                      ? Text(
                          addr.displayAddress!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSlate,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit
                      GestureDetector(
                        onTap: () => onEdit(addr),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.edit_outlined,
                            color: AppColors.textMuted,
                            size: 18,
                          ),
                        ),
                      ),
                      // Delete
                      GestureDetector(
                        onTap: () => onDelete(addr),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: AppColors.danger,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () => onSelect(addr),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Address tile (reusable row inside the card)
// ---------------------------------------------------------------------------

class _AddressTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final String? subtitle;
  final int? badge; // optional count badge
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
    this.badge,
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
          // Badge showing count of other addresses
          if (badge != null)
            Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$badge',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
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
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSubtle),
        ],
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
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
