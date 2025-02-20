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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 10,
                children: [
                  Container(
                    width: 48,
                    alignment: Alignment.topCenter,
                    child: appItem.iconBytes != null
                        ? Image.memory(
                            appItem.iconBytes!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                          )
                        : const Icon(Icons.apps, size: 48),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appItem.appModel.appName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Row(
                          children: [
                            Text('Category: ${appItem.appModel.appType}'),
                            const SizedBox(width: 16),
                            Text(
                              'Usage: ${formatDuration(appItem.appModel.appUsage)}',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: AttributesChoices(
                  selectedAttributes: appItem.attributes,
                  onAttributeSelected: (attribute, selected) =>
                      onAttributeSelected(attribute, selected),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
