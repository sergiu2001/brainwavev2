import 'dart:typed_data';
import 'package:brainwave/animations/star_background.dart';
import 'package:brainwave/providers/app_user_usage_provider.dart';
import 'package:brainwave/providers/user_report_provider.dart';
import 'package:brainwave/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:device_apps/device_apps.dart';
import 'package:firebase_ml_model_downloader/firebase_ml_model_downloader.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:brainwave/models/report_models.dart';
import 'package:brainwave/components/daily_activity_checkbox.dart';
import 'package:brainwave/components/app_usage_card.dart';
import 'package:brainwave/components/mental_health_questions_dropdown.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  List<AppUsageWithIcon> _apps = [];
  final List<DailyActivityModel> _dailyActivities = DailyActivityCheckbox.defaultActivities();
  final List<MentalHealthQuestionModel> _mentalHealthQuestions = MentalHealthQuestionDropdown.defaultQuestions();

  bool _isLoading = true;
  bool _isSending = false;
  Interpreter? _interpreter;

  @override
  void initState() async {
    super.initState();
    await _fetchRecentAppUsage();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchRecentAppUsage() async {
    final usageProvider = context.read<AppUserUsageProvider>();
    await usageProvider.getAppUsage();
    final usageList = usageProvider.appUsage;

    final updated = <AppUsageWithIcon>[];
    for (final app in usageList) {
      final icon = await _fetchAppIcon(app.appPackageName);
      updated.add(
        AppUsageWithIcon(appModel: app, iconBytes: icon, attributes: []),
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
            : _buildReportContent(),
      ),
    );
  }

  Widget _buildReportContent() {
    return ListView(
      children: [
        _buildAppUsageSection(),
        _buildDailyActivitiesSection(),
        _buildMentalHealthSection(),
        _buildSubmitButton(),
      ],
    );
  }

  Widget _buildAppUsageSection() {
    return Column(
      children: [
        const ListTile(
          title: Text('Apps Used'),
          subtitle: Text('Assign attributes to each app used.'),
        ),
        ..._apps.map((appItem) => AppUsageCard(
              appItem: appItem,
              onAttributeSelected: (attribute, selected) {
                setState(() {
                  if (selected) {
                    appItem.attributes.add(attribute);
                  } else {
                    appItem.attributes.remove(attribute);
                  }
                });
              },
            )),
      ],
    );
  }

  Widget _buildDailyActivitiesSection() {
    return Column(
      children: [
        const ListTile(
          title: Text('Today\'s Activities'),
          subtitle: Text('Select activities you did today.'),
        ),
        ..._dailyActivities.map(
          (activity) => DailyActivityCheckbox(
            activity: activity,
            onChanged: (val) =>
                setState(() => activity.selected = val ?? false),
          ),
        ),
      ],
    );
  }

  Widget _buildMentalHealthSection() {
    return Column(
      children: [
        const ListTile(
          title: Text('Mental Health Questions'),
          subtitle: Text('Rate from 1 to 5.'),
        ),
        ..._mentalHealthQuestions.map(
          (question) => MentalHealthQuestionDropdown(
            question: question,
            onRatingChanged: (val) =>
                setState(() => question.rating = val ?? 1),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
    );
  }
}
