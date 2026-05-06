import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class MedicineInventoryCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final String Function(num) formatRupiah;

  const MedicineInventoryCard({
    super.key,
    required this.medicine,
    required this.onTap,
    required this.onEdit,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final int stock = (medicine['total_active_stock'] as num?)?.toInt() ?? 0;
    final bool isCritical = stock <= 10;
    final bool isLow = stock <= 20 && stock > 10;

    final Color accentColor =
        medicine['accentColor'] as Color? ?? AppColors.primary;
    final String name = medicine['name'] as String? ?? 'Tidak Diketahui';
    final String? genericName =
        medicine['generic_name'] as String?; // Bisa null
    final String? category = medicine['category'] as String?;
    final String? form = medicine['form'] as String?;
    final String? unit = medicine['unit'] as String?;
    final bool requiresPrescription =
        medicine['requires_prescription'] as bool? ?? false;
    final num price = medicine['price'] as num? ?? 0;
    final String? imageUrl = medicine['image_url'] as String?;

    Color stockColor = AppColors.success;
    Color stockBg = AppColors.success.withOpacity(0.1);
    String stockLabel = 'Normal';

    if (isCritical) {
      stockColor = AppColors.danger;
      stockBg = AppColors.danger.withOpacity(0.1);
      stockLabel = 'Kritis';
    } else if (isLow) {
      stockColor = AppColors.warning;
      stockBg = AppColors.warning.withOpacity(0.1);
      stockLabel = 'Rendah';
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white, // Equivalent to _C.surface
          borderRadius: BorderRadius.circular(18),
          border: isCritical
              ? Border.all(
                  color: AppColors.danger.withOpacity(0.22),
                  width: 1.5,
                )
              : isLow
              ? Border.all(
                  color: AppColors.warning.withOpacity(0.22),
                  width: 1.5,
                )
              : null,
          boxShadow: [
            BoxShadow(
              color: isCritical
                  ? AppColors.danger.withOpacity(0.07)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(accentColor, imageUrl, form),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1: Nama + badge stok status
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: AppColors.textDark,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCritical || isLow) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: stockBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              stockLabel.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: stockColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 2),

                    // Row 2: Nama Generik (italic, subtle)
                    if (genericName != null && genericName.isNotEmpty)
                      Text(
                        genericName,
                        style: const TextStyle(
                          color: AppColors.textLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 5),

                    // Row 3: Metadata pills — kategori · bentuk · unit
                    Wrap(
                      spacing: 5,
                      runSpacing: 4,
                      children: [
                        if (category != null && category.isNotEmpty)
                          _buildMetaPill(label: category, color: accentColor),
                        if (form != null && form.isNotEmpty)
                          _buildMetaPill(label: form),
                        if (unit != null && unit.isNotEmpty)
                          _buildMetaPill(label: '/ $unit'),
                        if (requiresPrescription)
                          _buildMetaPill(
                            label: 'Resep',
                            color: const Color(0xFFF97316),
                            icon: Icons.description_outlined,
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Row 4: Harga + jumlah stok + edit btn
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          formatRupiah(price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: stockBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$stock ${unit ?? 'unit'}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: stockColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildActionBtn(
                          icon: Icons.edit_outlined,
                          color: AppColors.textLight,
                          onTap: onEdit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Color accentColor, String? imageUrl, String? form) {
    IconData fallbackIcon;
    switch (form?.toLowerCase()) {
      case 'sirup':
      case 'cairan':
        fallbackIcon = Icons.water_drop_rounded;
        break;
      case 'kapsul':
        fallbackIcon = Icons.local_pharmacy_rounded;
        break;
      case 'salep':
      case 'krim':
        fallbackIcon = Icons.sanitizer_rounded;
        break;
      default:
        fallbackIcon = Icons.medication_rounded;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(fallbackIcon, color: accentColor, size: 26),
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accentColor,
                        ),
                      ),
                    ),
            )
          : Icon(fallbackIcon, color: accentColor, size: 26),
    );
  }

  Widget _buildMetaPill({required String label, Color? color, IconData? icon}) {
    final c = color ?? AppColors.textLight;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color != null ? c.withOpacity(0.08) : AppColors.background,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 9, color: c),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: c,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required Color color,
    Color? bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bgColor ?? AppColors.background,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
