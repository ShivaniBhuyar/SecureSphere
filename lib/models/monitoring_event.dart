enum MonitoringEventType { sms, url, app, email, device }

enum MonitoringEventStatus { pending, queued, analyzing, completed }

class MonitoringEvent {
  final String id;
  final MonitoringEventType type;
  final String source;
  final DateTime timestamp;
  final MonitoringEventStatus status;
  final Map<String, dynamic>? metadata;

  MonitoringEvent({
    required this.id,
    required this.type,
    required this.source,
    required this.timestamp,
    required this.status,
    this.metadata,
  });

  String get typeName {
    switch (type) {
      case MonitoringEventType.sms: return 'SMS';
      case MonitoringEventType.url: return 'Link';
      case MonitoringEventType.app: return 'App';
      case MonitoringEventType.email: return 'Email';
      case MonitoringEventType.device: return 'Device';
    }
  }

  String get friendlyStatus {
    switch (status) {
      case MonitoringEventStatus.pending: return 'Pending';
      case MonitoringEventStatus.queued: return 'Preparing analysis';
      case MonitoringEventStatus.analyzing: return 'Waiting for AI analysis';
      case MonitoringEventStatus.completed: return 'Completed';
    }
  }
}
