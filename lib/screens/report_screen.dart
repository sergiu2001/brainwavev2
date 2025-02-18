import 'dart:typed_data';
import 'package:brainwave/animations/star_background.dart';
import 'package:brainwave/models/app_user_usage.dart';
import 'package:brainwave/providers/app_user_usage_provider.dart';
import 'package:brainwave/providers/user_report_provider.dart';
import 'package:brainwave/screens/welcome_screen.dart';
import 'package:brainwave/utils/usage_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_apps/device_apps.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DailyActivityModel {
  String activity;
  bool selected;
  DailyActivityModel(this.activity, this.selected);
}

class MentalHealthQuestionModel {
  String question;
  int rating;
  MentalHealthQuestionModel(this.question, this.rating);
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<_AppUsageWithIcon> _apps = [];
  List<DailyActivityModel> _dailyActivities = [];
  List<MentalHealthQuestionModel> _mentalHealthQuestions = [];

  bool _isLoading = true;
  bool _isSending = false;
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  Future<void> _initPage() async {
    setState(() => _isLoading = true);

    await _fetchRecentAppUsage();

    _initDailyActivities();
    _initMentalHealthQuestions();

    setState(() => _isLoading = false);
  }

  Future<void> _fetchRecentAppUsage() async {
    final usageProvider = context.read<AppUserUsageProvider>();
    await usageProvider.getAppUsage();
    final usageList = usageProvider.appUsage;

    final updated = <_AppUsageWithIcon>[];
    for (final app in usageList) {
      final icon = await _fetchAppIcon(app.appPackageName);
      updated.add(
        _AppUsageWithIcon(appModel: app, iconBytes: icon, attributes: []),
      );
    }

    setState(() {
      _apps = updated;
    });
  }

  Future<Uint8List?> _fetchAppIcon(String packageName) async {
    final app =
        await DeviceApps.getApp(packageName, true) as ApplicationWithIcon?;
    return app?.icon;
  }

  void _initDailyActivities() {
    final activities = [
      'Going for a walk',
      'Reading a book',
      'Going out',
      'Working out',
      'Meditating',
      'Socializing',
      'Relaxing',
      'Working',
    ];
    _dailyActivities =
        activities.map((a) => DailyActivityModel(a, false)).toList();
  }

  void _initMentalHealthQuestions() {
    final questions = [
      'How was your overall mood today?',
      'How stressed did you feel today?',
      'How well did you sleep last night?',
      'How anxious did you feel today?',
      'How happy did you feel today?',
    ];
    _mentalHealthQuestions =
        questions.map((q) => MentalHealthQuestionModel(q, 1)).toList();
  }

  Future<void> _downloadMLModelAndPredict() async {
    setState(() => _isSending = true);

    final model = await FirebaseModelDownloader.instance.getModel(
      "BrainHealth",
      FirebaseModelDownloadType.localModel,
      FirebaseModelDownloadConditions(
        androidChargingRequired: false,
        androidWifiRequired: false,
        androidDeviceIdleRequired: false,
      ),
    );

    _interpreter = Interpreter.fromFile(model.file);
    final inputTensor = _interpreter!.getInputTensor(0);
    print('Interpreter input shape: ${inputTensor.shape}');
    print('Interpreter input type: ${inputTensor.type}');
    final predictions = _runInference();
    await _sendReport(predictions);

    setState(() => _isSending = false);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
      );
    }
  }

  List<double> _runInference() {
    if (_interpreter == null) {
      return [];
    }
    final inputFeatures = _preprocessData();
    if (inputFeatures.length != 336) {
      throw Exception(
        'Expected 336 floats, got ${inputFeatures.length}',
      );
    }
    final input = [inputFeatures];
    final output = List.filled(4, 0.0).reshape([1, 4]);
    _interpreter!.run(input, output);
    final predictions = output[0].cast<double>();
    return predictions.map((val) => val * 100).toList();
  }

  List<double> _preprocessData() {
    return List<double>.filled(336, 0.0);
  }

  Future<void> _sendReport(List<double> predictions) async {
    final reportProvider = context.read<UserReportProvider>();

    final appsData = _apps.map((a) {
      final am = a.appModel;
      return {
        'appName': am.appName,
        'appPackageName': am.appPackageName,
        'appType': am.appType,
        'appUsage': am.appUsage,
        'attributes': a.attributes,
      };
    }).toList();

    final dailyActivities = _dailyActivities
        .where((d) => d.selected)
        .map((d) => d.activity)
        .toList();

    final mentalHealthData = <String, int>{};
    for (var q in _mentalHealthQuestions) {
      mentalHealthData[q.question] = q.rating;
    }

    await reportProvider.sendReport(
      apps: appsData,
      dailyActivities: dailyActivities,
      mentalHealthQuestions: mentalHealthData,
      predictions: predictions,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Page')),
      body: StarryBackgroundWidget(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      children: [
        const ListTile(
          title: Text('Apps Used'),
          subtitle: Text('Assign attributes to each app used.'),
        ),
        ..._apps.map(
          (appItem) => Card(
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
                      _buildAttributesMultiSelect(appItem),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const ListTile(
          title: Text('Today\'s Activities'),
          subtitle: Text('Select activities you did today.'),
        ),
        ..._dailyActivities.map(
          (act) => CheckboxListTile(
            title: Text(act.activity),
            value: act.selected,
            onChanged: (val) {
              setState(() => act.selected = val ?? false);
            },
          ),
        ),
        const ListTile(
          title: Text('Mental Health Questions'),
          subtitle: Text('Rate from 1 to 5.'),
        ),
        ..._mentalHealthQuestions.map(
          (q) => ListTile(
            title: Text(q.question),
            trailing: DropdownButton<int>(
              value: q.rating,
              onChanged: (val) {
                setState(() => q.rating = val ?? 1);
              },
              items: List.generate(5, (i) => i + 1)
                  .map((v) => DropdownMenuItem(value: v, child: Text('$v')))
                  .toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ElevatedButton(
            onPressed: _isSending ? null : _downloadMLModelAndPredict,
            child: _isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Submit'),
          ),
        ),
      ],
    );
  }

  Widget _buildAttributesMultiSelect(_AppUsageWithIcon appItem) {
    final possibleAttributes = [
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
        final isSelected = appItem.attributes.contains(attr);
        return ChoiceChip(
          label: Text(attr),
          selected: isSelected,
          onSelected: (val) {
            setState(() {
              if (val) {
                appItem.attributes.add(attr);
              } else {
                appItem.attributes.remove(attr);
              }
            });
          },
        );
      }).toList(),
    );
  }
}

class _AppUsageWithIcon {
  final AppUserUsage appModel;
  final Uint8List? iconBytes;
  final List<String> attributes;

  _AppUsageWithIcon({
    required this.appModel,
    this.iconBytes,
    required this.attributes,
  });
}
