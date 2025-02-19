import 'package:flutter/material.dart';
import 'package:brainwave/models/report_models.dart';
import 'attributes_choices.dart';
import 'package:brainwave/utils/usage_formatter.dart';

class AppUsageCard extends StatelessWidget {
  final AppUsageWithIcon appItem;
  final Function(String, bool) onAttributeSelected;

  const AppUsageCard({
    super.key,
    required this.appItem,
    required this.onAttributeSelected,
  });
  

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: appItem.iconBytes != null
                ? Image.memory(appItem.iconBytes!)
                : const Icon(Icons.apps),
            title: Text(appItem.appModel.appName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${appItem.appModel.appType}'),
                Text(
                  'Usage Time: ${formatDuration(appItem.appModel.appUsage)}',
                ),
                AttributesChoices(
                  selectedAttributes: appItem.attributes,
                  onAttributeSelected: (attribute, selected) =>
                      onAttributeSelected(attribute, selected),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}