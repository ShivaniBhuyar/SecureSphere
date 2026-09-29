import 'package:flutter/foundation.dart';
import '../models/monitoring_event.dart';
import 'package:uuid/uuid.dart';

class EventQueueService extends ChangeNotifier {
  static final EventQueueService _instance = EventQueueService._internal();
  factory EventQueueService() => _instance;
  
  final List<MonitoringEvent> _events = [];

  EventQueueService._internal() {
    // Add some initial mock events
    _events.addAll([
      MonitoringEvent(
        id: const Uuid().v4(),
        type: MonitoringEventType.url,
        source: 'Link received',
        timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        status: MonitoringEventStatus.analyzing,
      ),
      MonitoringEvent(
        id: const Uuid().v4(),
        type: MonitoringEventType.app,
        source: 'New app installed',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: MonitoringEventStatus.queued,
      ),
      MonitoringEvent(
        id: const Uuid().v4(),
        type: MonitoringEventType.sms,
        source: 'Suspicious message shared',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        status: MonitoringEventStatus.queued,
      ),
    ]);
  }

  List<MonitoringEvent> get recentEvents => List.unmodifiable(_events);

  void addEvent(MonitoringEvent event) {
    _events.insert(0, event); // Add to the top
    notifyListeners();
  }
}
