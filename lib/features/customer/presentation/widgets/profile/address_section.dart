import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../data/models/customer_address.dart';
import '../../../presentation/screens/edit_address_screen.dart';
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

  Future<void> _deleteAddress(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    try {
      await ref.read(customerProfileProvider.notifier).deleteAddress(id);
      onRefresh?.call();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
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
                color: Color(0xFF94A3B8),
                letterSpacing: 1.5,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _AddressTile(
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFF64748B),
                  title: 'Alamat Utama',
                  subtitle: primaryAddress?.displayAddress,
                  isFirst: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerEditAddressScreen(
                        isAdd: primaryAddress == null,
                        address: primaryAddress,
                      ),
                    ),
                  ).then((_) => onRefresh?.call()),
                  onDelete: primaryAddress != null
                      ? () => _deleteAddress(context, ref, primaryAddress!.id)
                      : null,
                ),
                ...otherAddresses.map(
                  (addr) => Column(
                    children: [
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      _AddressTile(
                        icon: Icons.location_on_outlined,
                        iconColor: const Color(0xFF94A3B8),
                        title: addr.label,
                        subtitle: addr.displayAddress,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerEditAddressScreen(
                              isAdd: false,
                              address: addr,
                            ),
                          ),
                        ).then((_) => onRefresh?.call()),
                        onDelete: () => _deleteAddress(context, ref, addr.id),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                _AddressTile(
                  icon: Icons.add_location_alt_outlined,
                  iconColor: const Color(0xFF1D70F5),
                  title: 'Tambah Alamat',
                  titleColor: const Color(0xFF1D70F5),
                  isLast: true,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CustomerEditAddressScreen(isAdd: true),
                    ),
                  ).then((_) => onRefresh?.call()),
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
          color: titleColor ?? const Color(0xFF1E293B),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
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
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
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