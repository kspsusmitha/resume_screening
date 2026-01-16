import 'package:flutter/material.dart';

class SkillChip extends StatelessWidget {
  final String skill;
  final bool isSelected;
  final VoidCallback? onTap;

  const SkillChip({
    super.key,
    required this.skill,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(skill),
      selected: isSelected,
      onSelected: onTap != null ? (_) => onTap!() : null,
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}

