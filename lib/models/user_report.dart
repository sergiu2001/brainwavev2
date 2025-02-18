import 'package:brainwave/models/app_user_usage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserReport{
  final List<AppUserUsage> apps;
  final List<String> dailyActivities;
  final Map<String,int> mentalHealthQuestions;
  final List<double> predictions;
  final Timestamp timestamp;

  const UserReport({
    required this.apps,
    required this.dailyActivities,
    required this.mentalHealthQuestions,
    required this.predictions,
    required this.timestamp,
  });

  factory UserReport.fromMap(Map<String, dynamic> map){
    return UserReport(
      apps: _parseApps(map['apps']),
      dailyActivities: List<String>.from(map['dailyActivities']),
      mentalHealthQuestions: Map<String,int>.from(map['mentalHealthQuestions']),
      predictions: _parsePredictions(map['predictions']),
      timestamp: map['timestamp']
    );
  }

  static List<AppUserUsage> _parseApps(dynamic apps){
    if(apps == null || apps is! List) return [];
    return apps.map((e) => AppUserUsage.fromMap(e as Map<String, dynamic>)).toList();
  }

  static List<double> _parsePredictions(dynamic predictions){
    if(predictions == null || predictions is! List) return [];
    return predictions.map((e) => e is num? e.toDouble(): 0.0).toList();
  }
}