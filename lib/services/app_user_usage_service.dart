import 'package:app_usage/app_usage.dart';
import '../models/app_user_usage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_apps/device_apps.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppUserUsageService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  User? get currentUser => _firebaseAuth.currentUser;

  Future<List<AppUserUsage>> getAppUsage() async {
    if (_firebaseAuth.currentUser == null) return [];
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('getAppUsage');
      final result = await callable.call({
        'uid': _firebaseAuth.currentUser!.uid,
      });
      final rawList = result.data as List<dynamic>;
      return rawList.map((item) {
        final mapItem = Map<String, dynamic>.from(item as Map);
        return AppUserUsage.fromMap(mapItem);
      }).toList();
    } on FirebaseFunctionsException catch (e) {
      print(e);
      return [];
    }
  }

  Future<void> sendAppUsage(List<AppUsageInfo> infos) async {
    if (_firebaseAuth.currentUser == null) return;
    try {
      final List<List<String>> appList = [];
      for (var info in infos) {
        final app = await DeviceApps.getApp(info.packageName);
        if (app == null) continue;
        final appName = app.appName;
        final appPackageName = app.packageName;
        final appType = app.category.toString().split('.').last;
        final appUsage = info.usage.toString();
        final appDate = info.startDate.toString().split(' ')[0];
        appList.add([appName, appPackageName, appType, appUsage, appDate]);
      }
      final callable = FirebaseFunctions.instance.httpsCallable('sendAppUsage');
      await callable.call({
        'uid': _firebaseAuth.currentUser!.uid,
        'appList': appList,
      });
    } on FirebaseFunctionsException catch (e) {
      print(e);
    }
  }
}
