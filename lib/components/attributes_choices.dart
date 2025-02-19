import 'package:flutter/material.dart';

class AttributesChoices extends StatelessWidget {
  final List<String> selectedAttributes;
  final Function(String, bool) onAttributeSelected;

  const AttributesChoices({
    super.key,
    required this.selectedAttributes,
    required this.onAttributeSelected,
  });

  @override
  Widget build(BuildContext context) {
    const possibleAttributes = [
      'Home',
      'Work',
      'Public Place',
      'On the Go',
      'Happy',
      'Sad',
      'Anxious',
      'Stressed',
      'Calm',
      'Bored',
      'Excited',
      'Entertainment',
      'Communication',
      'Productivity',
      'Information',
      'Relaxation',
    ];

    return Wrap(
      spacing: 6,
      runSpacing: 2,
      children: possibleAttributes.map((attr) {
        final isSelected = selectedAttributes.contains(attr);
        return ChoiceChip(
          label: Text(attr),
          selected: isSelected,
          onSelected: (val) => onAttributeSelected(attr, val),
        );
      }).toList(),
    );
  }
}