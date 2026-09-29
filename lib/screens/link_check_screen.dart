import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/monitoring_event.dart';
import '../services/event_queue_service.dart';
import 'package:uuid/uuid.dart';
import 'threat_detection_screen.dart';

class LinkCheckScreen extends StatefulWidget {
  const LinkCheckScreen({super.key});

  @override
  State<LinkCheckScreen> createState() => _LinkCheckScreenState();
}

class _LinkCheckScreenState extends State<LinkCheckScreen> {
  final _urlController = TextEditingController();
  bool _isChecking = false;

  void _checkLink() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() => _isChecking = true);
    
    // Simulate slight processing delay
    await Future.delayed(const Duration(seconds: 1));

      final event = MonitoringEvent(
        id: const Uuid().v4(),
        type: MonitoringEventType.url,
        source: url,
        timestamp: DateTime.now(),
        status: MonitoringEventStatus.queued,
        metadata: {'url': url},
      );
      EventQueueService().addEvent(event);

      if (mounted) {
        setState(() => _isChecking = false);
        _urlController.clear();
        
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.safeGreen, size: 60),
                const SizedBox(height: 16),
                const Text('Link received.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                const Text('Ready for Security Check.', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ThreatDetectionScreen(initialEvent: event),
                        ),
                      );
                    },
                    child: const Text('CHECK SAFETY NOW'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Close screen
                  },
                  child: const Text('GOT IT'),
                )
              ],
            ),
          ),
        );
      }
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Check Link Safety')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.security, size: 80, color: AppTheme.electricCyan),
            const SizedBox(height: 24),
            const Text(
              'Paste a link here to check if it\'s safe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'https://...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkLink,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.electricCyan,
                  foregroundColor: AppTheme.deepNavy,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isChecking
                    ? const CircularProgressIndicator(color: AppTheme.deepNavy)
                    : const Text('CHECK LINK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
