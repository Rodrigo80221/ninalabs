import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomDropdown extends StatelessWidget {
  final String? label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const CustomDropdown({
    super.key,
    this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    Widget dropdown = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.textLight),
          dropdownColor: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item),
            );
          }).toList(),
        ),
      ),
    );

    if (label != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12.0, bottom: 4.0),
            child: Text(
              label!,
              style: const TextStyle(
                color: AppColors.terracotta,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          dropdown,
        ],
      );
    }

    return dropdown;
  }
}
