import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/theme/app_colors.dart';

class MedicineFormField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final IconData? prefixIcon;
  final String? prefix;
  final TextInputType? keyboard;
  final bool required;
  final int maxLines;

  const MedicineFormField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.prefixIcon,
    this.prefix,
    this.keyboard,
    this.required = false,
    this.maxLines = 1,
  });

  @override
  State<MedicineFormField> createState() => _MedicineFormFieldState();
}

class _MedicineFormFieldState extends State<MedicineFormField> {
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _focused ? AppColors.primary : AppColors.textMid,
              ),
              children: [
                if (widget.required)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.danger),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: _focused ? AppColors.primaryLight.withOpacity(0.5) : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _focused ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              keyboardType: widget.keyboard,
              maxLines: widget.maxLines,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: widget.prefix != null
                    ? Container(
                        width: 46,
                        alignment: Alignment.center,
                        child: Text(
                          widget.prefix!,
                          style: TextStyle(
                            color: _focused ? AppColors.primary : AppColors.textMid,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      )
                    : widget.prefixIcon != null
                        ? Icon(
                            widget.prefixIcon,
                            color: _focused ? AppColors.primary : AppColors.textLight,
                            size: 18,
                          )
                        : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MedicineFormDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final Function(String?) onChanged;

  const MedicineFormDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? AppColors.primary : AppColors.textMid,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight.withOpacity(0.5) : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary.withOpacity(0.4) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: isSelected ? AppColors.primary : AppColors.textLight,
                size: 20,
              ),
              hint: const Text(
                'Pilih...',
                style: TextStyle(color: AppColors.textLight, fontSize: 13),
              ),
              items: items
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        e,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
              dropdownColor: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class MedicineFormRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const MedicineFormRow({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class MedicineFormSwitch extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final Function(bool) onChanged;
  final IconData icon;
  final Color activeColor;
  final Color activeBg;

  const MedicineFormSwitch({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.icon,
    required this.activeColor,
    required this.activeBg,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: value ? activeBg : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? activeColor.withOpacity(0.25) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: value ? activeColor.withOpacity(0.15) : AppColors.surface,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                color: value ? activeColor : AppColors.textLight,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: value ? activeColor : AppColors.textDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: value,
                onChanged: (v) {
                  HapticFeedback.selectionClick();
                  onChanged(v);
                },
                activeColor: activeColor,
                activeTrackColor: activeColor.withOpacity(0.25),
                inactiveThumbColor: AppColors.textLight,
                inactiveTrackColor: AppColors.divider,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
