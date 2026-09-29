import 'package:flutter/foundation.dart';
import '../models/monitoring_event.dart';

class PermissionService extends ChangeNotifier {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  final Map<MonitoringEventType, bool> _permissions = {
    MonitoringEventType.sms: false,
    MonitoringEventType.url: true, // Typically shared intent, doesn't need Android permission
    MonitoringEventType.app: true, // Package visibility
    MonitoringEventType.email: false, // Optional/Share intent
    MonitoringEventType.device: true,
  };

  bool isGranted(MonitoringEventType type) {
    return _permissions[type] ?? false;
  }

  void grantPermission(MonitoringEventType type) {
    _permissions[type] = true;
    notifyListeners();
  }

  void revokePermission(MonitoringEventType type) {
    _permissions[type] = false;
    notifyListeners();
  }
}
