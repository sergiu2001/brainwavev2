import 'dart:typed_data';

class AppUserUsage{
  final String appName;
  final String appPackageName;
  final String appType;
  final String appUsage;
  final DateTime appDate;
  final Uint8List? appIcon;

  const AppUserUsage({
    required this.appName,
    required this.appPackageName,
    required this.appType,
    required this.appUsage,
    required this.appDate,
    this.appIcon,
  });

  factory AppUserUsage.fromMap(Map<String, dynamic> map){
    print('map');
    print(map);
    return AppUserUsage(
      appName: map['appName'],
      appPackageName: map['appPackageName'],
      appType: map['appType'],
      appUsage: map['appUsage'],
      appDate: DateTime.parse(map['appDate']),
      appIcon: map['appIcon'],
    );
  }

  
  

  Map<String, dynamic> toMap(){
    return {
      'appName': appName,
      'appPackageName': appPackageName,
      'appType': appType,
      'appUsage': appUsage,
      'appDate': appDate.toIso8601String(),
      'appIcon': appIcon,
    };
  }
}