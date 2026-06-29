import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:mobile/core/models/medicine.dart';

class MedicineInventoryCard extends StatelessWidget {
  final Medicine medicine;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final String Function(num)? formatRupiah;

  const MedicineInventoryCard({
    super.key,
    required this.medicine,
    required this.onTap,
    required this.onEdit,
    this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final int stock = medicine.totalActiveStock;

    Color statusColor = medicine.isActive
        ? (stock <= 10
            ? AppColors.danger
            : (stock <= 20 ? AppColors.warning : AppColors.success))
        : Colors.grey;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.textDark.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Opacity(
                    opacity: medicine.isActive ? 1.0 : 0.6,
                    child: _buildProductImage(statusColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                medicine.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textDark,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            _buildStatusDot(statusColor),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          medicine.category ?? 'Uncategorized',
                          style: const TextStyle(
                            color: AppColors.textLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              "$stock ${medicine.unit ?? 'Unit'}",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                            if (!medicine.isActive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Nonaktif',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatRupiah?.call(medicine.price) ??
                            'Rp ${medicine.price}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionBtn(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(Color statusColor) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.1), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty
            ? Image.network(medicine.imageUrl!, fit: BoxFit.cover)
            : Icon(medicine.icon, color: AppColors.textSubtle, size: 24),
      ),
    );
  }

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4)],
      ),
    );
  }

  Widget _buildQuickActionBtn() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onEdit();
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(
          Icons.edit_document,
          size: 16,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
