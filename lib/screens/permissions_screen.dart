import 'package:flutter/material.dart';
import '../models/monitoring_event.dart';
import '../services/permission_service.dart';
import '../theme/app_theme.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({super.key});

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  final _permissionService = PermissionService();

  @override
  void initState() {
    super.initState();
    _permissionService.addListener(_updateState);
  }

  @override
  void dispose() {
    _permissionService.removeListener(_updateState);
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  void _showWhyDialog(String title, String explanation) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(explanation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(MonitoringEventType type, String title, IconData icon, String whyExplanation) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isGranted = _permissionService.isGranted(type);

    return Card(
      color: isDark ? AppTheme.deepNavy : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.silver.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.electricCyan, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _showWhyDialog(title, whyExplanation),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.electricCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Why?',
                        style: TextStyle(color: AppTheme.electricCyan, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: isGranted,
              onChanged: (val) {
                if (val) {
                  _permissionService.grantPermission(type);
                } else {
                  _permissionService.revokePermission(type);
                }
              },
              activeThumbColor: AppTheme.safeGreen,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Permissions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'You\'re always in control.',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Only enable the permissions you feel comfortable with. SecureSphere protects you either way.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          
          _buildPermissionItem(
            MonitoringEventType.sms,
            'SMS Protection',
            Icons.message_outlined,
            'Allows SecureSphere to scan incoming messages for known phishing links and scam language locally on your device.',
          ),
          _buildPermissionItem(
            MonitoringEventType.url,
            'Link Sharing',
            Icons.link,
            'Allows you to share suspicious links to SecureSphere for safety analysis before you click them.',
          ),
          _buildPermissionItem(
            MonitoringEventType.app,
            'App Monitoring',
            Icons.apps,
            'Allows SecureSphere to check new apps you install against a list of known malware.',
          ),
          _buildPermissionItem(
            MonitoringEventType.email,
            'Email Sharing',
            Icons.email_outlined,
            'Allows you to forward suspicious emails to SecureSphere for scanning.',
          ),
          _buildPermissionItem(
            MonitoringEventType.device,
            'Device Status',
            Icons.security,
            'Allows SecureSphere to verify that your lock screen, Play Protect, and basic security settings are active.',
          ),
        ],
      ),
    );
  }
}
