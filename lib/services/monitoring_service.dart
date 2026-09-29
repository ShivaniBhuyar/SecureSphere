import 'package:flutter/foundation.dart';

class MonitoringService extends ChangeNotifier {
  static final MonitoringService _instance = MonitoringService._internal();
  factory MonitoringService() => _instance;
  MonitoringService._internal();

  bool _isProtectionActive = true;

  bool get isProtectionActive => _isProtectionActive;

  void toggleProtection(bool isActive) {
    _isProtectionActive = isActive;
    notifyListeners();
  }
}
