import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/monitoring_event.dart';
import '../services/monitoring_service.dart';
import '../services/permission_service.dart';
import '../services/event_queue_service.dart';
import '../widgets/guardian_monitor_widget.dart';
import '../widgets/monitoring_card.dart';
import '../widgets/activity_timeline.dart';
import '../widgets/privacy_card.dart';
import 'link_check_screen.dart';
import 'threat_detection_screen.dart';

class MonitoringScreen extends StatefulWidget {
  const MonitoringScreen({super.key});

  @override
  State<MonitoringScreen> createState() => _MonitoringScreenState();
}

class _MonitoringScreenState extends State<MonitoringScreen> {
  final _monitoringService = MonitoringService();
  final _permissionService = PermissionService();
  final _eventQueueService = EventQueueService();
  
  @override
  void initState() {
    super.initState();
    _monitoringService.addListener(_updateState);
    _permissionService.addListener(_updateState);
    _eventQueueService.addListener(_updateState);
  }

  @override
  void dispose() {
    _monitoringService.removeListener(_updateState);
    _permissionService.removeListener(_updateState);
    _eventQueueService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  void _handleCardTap(MonitoringEventType type) {
    if (type == MonitoringEventType.url) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LinkCheckScreen()));
    } else {
      if (!_permissionService.isGranted(type)) {
        _permissionService.grantPermission(type);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.name.toUpperCase()} protection enabled.'),
            backgroundColor: AppTheme.safeGreen,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isActive = _monitoringService.isProtectionActive;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Safety Guard'),
            Text(
              'Your phone\'s digital protection layer',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt, color: AppTheme.electricCyan),
            tooltip: 'Check for Threats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThreatDetectionScreen()),
              );
            },
          ),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 3D Hero Section
            Center(child: GuardianMonitorWidget(isActive: isActive)),
            const SizedBox(height: 24),
            
            // Master Status
            Center(
              child: Column(
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.safeGreen : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'BACKGROUND PROTECTION ACTIVE' : 'PROTECTION PAUSED',
                          style: TextStyle(
                            color: isActive ? AppTheme.safeGreen : Colors.grey,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isActive 
                      ? 'SecureSphere is monitoring supported activity.' 
                      : 'Background monitoring is temporarily disabled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: isDark ? AppTheme.silver : Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Master Toggle Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.deepNavy.withValues(alpha: 0.5) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isActive ? AppTheme.electricCyan.withValues(alpha: 0.3) : AppTheme.silver.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Safety Guard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.deepNavy,
                    ),
                  ),
                  Switch(
                    value: isActive,
                    onChanged: (val) => _monitoringService.toggleProtection(val),
                    activeThumbColor: AppTheme.electricCyan,
                    activeTrackColor: AppTheme.electricCyan.withValues(alpha: 0.2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Categories
            Text(
              'Monitoring Categories',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            MonitoringCard(
              type: MonitoringEventType.sms,
              title: 'SMS Protection',
              description: 'Check suspicious messages and scam indicators.',
              isGranted: _permissionService.isGranted(MonitoringEventType.sms),
              onTap: () => _handleCardTap(MonitoringEventType.sms),
            ),
            MonitoringCard(
              type: MonitoringEventType.url,
              title: 'Link Protection',
              description: 'Review links before opening them.',
              isGranted: _permissionService.isGranted(MonitoringEventType.url),
              onTap: () => _handleCardTap(MonitoringEventType.url),
            ),
            MonitoringCard(
              type: MonitoringEventType.app,
              title: 'App Protection',
              description: 'Monitor newly installed applications.',
              isGranted: _permissionService.isGranted(MonitoringEventType.app),
              onTap: () => _handleCardTap(MonitoringEventType.app),
            ),
            MonitoringCard(
              type: MonitoringEventType.email,
              title: 'Email Protection',
              description: 'Analyze emails you choose to share.',
              isGranted: _permissionService.isGranted(MonitoringEventType.email),
              onTap: () => _handleCardTap(MonitoringEventType.email),
            ),
            MonitoringCard(
              type: MonitoringEventType.device,
              title: 'Device Protection',
              description: 'Review important phone security settings.',
              isGranted: _permissionService.isGranted(MonitoringEventType.device),
              onTap: () => _handleCardTap(MonitoringEventType.device),
            ),
            
            const SizedBox(height: 40),
            
            // Recent Activity
            Text(
              'Recent Security Activity',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ActivityTimeline(events: _eventQueueService.recentEvents),

            const SizedBox(height: 40),
            const PrivacyCard(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
