import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class MedicineFormBatchCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> batch;
  final bool canDelete;
  final VoidCallback onDelete;
  final void Function(String field, String value) onChanged;

  const MedicineFormBatchCard({
    super.key,
    required this.index,
    required this.batch,
    required this.canDelete,
    required this.onDelete,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.warning,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Batch ${index + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (canDelete)
                  GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: MedicineFormBatchField(
                        label: 'No. Batch',
                        initialValue: batch['number'] ?? '',
                        hint: 'Contoh: B2024001',
                        onChanged: (v) => onChanged('number', v),
                        icon: Icons.tag_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: MedicineFormBatchField(
                        label: 'Kadaluarsa',
                        initialValue: batch['exp'] ?? '',
                        hint: 'MM/YYYY',
                        onChanged: (v) => onChanged('exp', v),
                        icon: Icons.event_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                MedicineFormBatchField(
                  label: 'Jumlah Stok Batch',
                  initialValue: batch['stock']?.toString() ?? '',
                  hint: 'Masukkan jumlah stok...',
                  onChanged: (v) => onChanged('stock', v),
                  keyboard: TextInputType.number,
                  icon: Icons.add_box_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MedicineFormBatchField extends StatefulWidget {
  final String label;
  final String initialValue;
  final String? hint;
  final Function(String) onChanged;
  final TextInputType? keyboard;
  final IconData? icon;

  const MedicineFormBatchField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.keyboard,
    this.icon,
  });

  @override
  State<MedicineFormBatchField> createState() => _MedicineFormBatchFieldState();
}

class _MedicineFormBatchFieldState extends State<MedicineFormBatchField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _focused ? AppColors.primary : AppColors.textMid,
          ),
        ),
        const SizedBox(height: 5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          decoration: BoxDecoration(
            color: _focused ? AppColors.primaryLight.withOpacity(0.6) : AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _focused ? AppColors.primary.withOpacity(0.4) : AppColors.divider,
              width: 1.5,
            ),
          ),
          child: TextField(
            focusNode: _focus,
            controller: TextEditingController(text: widget.initialValue),
            onChanged: widget.onChanged,
            keyboardType: widget.keyboard,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 12),
              prefixIcon: widget.icon != null
                  ? Icon(
                      widget.icon,
                      size: 15,
                      color: _focused ? AppColors.primary : AppColors.textLight,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
        ),
      ],
    );
  }
}
