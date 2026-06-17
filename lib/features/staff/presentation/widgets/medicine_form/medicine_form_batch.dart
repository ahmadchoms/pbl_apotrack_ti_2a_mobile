import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
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
                        hint: 'YYYY-MM-DD',
                        readOnly: true,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now().add(const Duration(days: 365)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 3650)),
                          );
                          if (date != null) {
                            onChanged('exp', date.toString().split(' ').first);
                          }
                        },
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
                  isDigitsOnly: true,
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
  final bool readOnly;
  final VoidCallback? onTap;
  final bool isDigitsOnly;

  const MedicineFormBatchField({
    super.key,
    required this.label,
    required this.initialValue,
    required this.onChanged,
    this.hint,
    this.keyboard,
    this.icon,
    this.readOnly = false,
    this.onTap,
    this.isDigitsOnly = false,
  });

  @override
  State<MedicineFormBatchField> createState() => _MedicineFormBatchFieldState();
}

class _MedicineFormBatchFieldState extends State<MedicineFormBatchField> {
  final _focus = FocusNode();
  late TextEditingController _controller;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void didUpdateWidget(MedicineFormBatchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && 
        widget.initialValue != _controller.text) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
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
            color: _focused ? AppColors.primaryLight.withValues(alpha: 0.6) : AppColors.surface,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _focused ? AppColors.primary.withValues(alpha: 0.4) : AppColors.divider,
              width: 1.5,
            ),
          ),
          child: TextField(
            focusNode: _focus,
            controller: _controller,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboard,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            inputFormatters: [
              if (widget.isDigitsOnly) FilteringTextInputFormatter.digitsOnly,
            ],
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 12),
              prefixIcon: widget.icon != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        widget.icon,
                        size: 16,
                        color: _focused ? AppColors.primary : AppColors.textLight,
                      ),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
      ],
    );
  }
}
