import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/medicine.dart';

class PosProductCard extends StatelessWidget {
  final Medicine medicine;
  final int cartQty;
  final VoidCallback onAdd;

  const PosProductCard({
    super.key,
    required this.medicine,
    required this.cartQty,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final isInCart = cartQty > 0;
    final stock = medicine.totalActiveStock;
    final isCritical = stock <= 5;
    final isLowStock = stock <= 10;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onAdd();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isInCart ? AppColors.primary : AppColors.divider.withOpacity(0.5),
            width: isInCart ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isInCart ? AppColors.primary.withOpacity(0.1) : Colors.black.withOpacity(0.02),
              blurRadius: isInCart ? 12 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      color: AppColors.background,
                      child: medicine.imageUrl != null && medicine.imageUrl!.isNotEmpty
                          ? Image.network(
                              medicine.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  // Content
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStockTag(stock, isCritical, isLowStock, medicine.unit ?? 'Unit'),
                          const SizedBox(height: 8),
                          Text(
                            medicine.name,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          Text(
                            _formatRupiah(medicine.price),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Quantity Badge Overlay
              if (isInCart)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      '${cartQty}x',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),

              // Type Badge Bottom
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.divider.withOpacity(0.3)),
                  ),
                  child: Text(
                    (medicine.type ?? 'Umum').toUpperCase(),
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textMid),
                  ),
                ),
              ),

              // Ripple effect
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onAdd();
                    },
                    splashColor: AppColors.primary.withOpacity(0.1),
                    highlightColor: Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.medication_outlined,
        color: AppColors.textLight.withOpacity(0.3),
        size: 32,
      ),
    );
  }

  Widget _buildStockTag(int stock, bool isCritical, bool isLow, String unit) {
    Color color = AppColors.success;
    if (isCritical) color = AppColors.danger;
    else if (isLow) color = AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 4, height: 4, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(
            '$stock $unit',
            style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  String _formatRupiah(num value) {
    final str = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    final len = str.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write('.');
      buffer.write(str[i]);
    }
    return 'Rp ${buffer.toString()}';
  }
}
