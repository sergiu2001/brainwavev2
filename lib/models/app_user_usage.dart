import 'dart:typed_data';

class AppUserUsage {
  final String appName;
  final String appPackageName;
  final String appType;
  final String appUsage;
  final Uint8List? appIcon;
  final List<String> appAttributes;

  const AppUserUsage({
    required this.appName,
    required this.appPackageName,
    required this.appType,
    required this.appUsage,
    this.appIcon,
    this.appAttributes = const [],
  });

  factory AppUserUsage.fromMap(Map<String, dynamic> map) {
    return AppUserUsage(
      appName: map['appName'],
      appPackageName: map['appPackageName'],
      appType: map['appType'],
      appUsage: map['appUsage'],
      appIcon: map['appIcon'],
    );
  }

  factory AppUserUsage.fromMapwithAtt(Map<String, dynamic> map) {
    return AppUserUsage(
      appName: map['appName'],
      appPackageName: map['appPackageName'],
      appType: map['appType'],
      appUsage: map['appUsage'],
      appIcon: map['appIcon'],
      appAttributes: map['appAttributes'] != null
          ? List<String>.from(map['appAttributes'])
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'appName': appName,
      'appPackageName': appPackageName,
      'appType': appType,
      'appUsage': appUsage,
      'appIcon': appIcon,
      'appAttributes': appAttributes,
    };
  }
}
