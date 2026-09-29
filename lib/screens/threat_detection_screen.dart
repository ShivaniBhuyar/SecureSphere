import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/monitoring_event.dart';
import '../models/threat_analysis_result.dart';
import '../services/event_queue_service.dart';
import '../services/online_threat_analyzer.dart';
import '../services/threat_history_service.dart';
import '../theme/app_theme.dart';
import '../widgets/threat_detection_hero.dart';
import '../widgets/threat_result_card.dart';

class ThreatDetectionScreen extends StatefulWidget {
  final MonitoringEvent? initialEvent;

  const ThreatDetectionScreen({super.key, this.initialEvent});

  @override
  State<ThreatDetectionScreen> createState() => _ThreatDetectionScreenState();
}

class _ThreatDetectionScreenState extends State<ThreatDetectionScreen> {
  final _analyzer = OnlineThreatAnalyzer();
  final _historyService = ThreatHistoryService();
  final _eventQueueService = EventQueueService();

  ThreatDetectionState _state = ThreatDetectionState.waiting;
  MonitoringEvent? _selectedEvent;
  ThreatAnalysisResult? _currentResult;

  // Custom text input controller
  final _customInputController = TextEditingController();
  bool _isCustomMode = false;
  MonitoringEventType _customType = MonitoringEventType.sms;

  // Test Presets
  late final List<MonitoringEvent> _testPresets;

  @override
  void initState() {
    super.initState();
    _historyService.addListener(_onStateChange);
    _eventQueueService.addListener(_onStateChange);

    _initPresets();

    if (widget.initialEvent != null) {
      _selectedEvent = widget.initialEvent;
      // Auto-analyze initial event if passed from Module 2
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runAnalysis(_selectedEvent!);
      });
    } else if (_testPresets.isNotEmpty) {
      _selectedEvent = _testPresets[1]; // Default to Test 2 (OTP scam) for striking demo
    }
  }

  void _initPresets() {
    _testPresets = [
      MonitoringEvent(
        id: const Uuid().v4(),
        type: MonitoringEventType.sms,
        source: 'Hi Dad, can you pick up some groceries on your way home?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        status: MonitoringEventStatus.queued,
        metadata: {
          'presetName': 'TEST 1: Normal SMS',
          'expected': 'LOW RISK',
          'text': 'Hi Dad, can you pick up some groceries on your way home?',
        },
      ),
      MonitoringEvent(
        id: const Uuid().v4(),
        type: MonitoringEventType.sms,
        source: 'ALERT: Your SBI bank account will be blocked today. Please share the 6-digit OTP sent to your phone immediately to verify your KYC: bit.ly/sbi-verify',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: MonitoringEventStatus.queued,
        metadata: {
          'presetName': 'TEST 2: SMS requesting OTP',
          'expected': 'HIGH RISK',
          'text': 'ALERT: Your SBI bank account will be blocked today. Please share the 6-digit OTP sent to your phone immediately to verify your KYC: bit.ly/sbi-verify',
        },
      ),
      MonitoringEvent(
        id: const Uuid().v4(),
        type: MonitoringEventType.url,
        source: 'http://192.168.1.1/login-secure-banking-verify-otp.xyz/account',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        status: MonitoringEventStatus.queued,
        metadata: {
          'presetName': 'TEST 3: Suspicious URL',
          'expected': 'HIGH RISK',
          'url': 'http://192.168.1.1/login-secure-banking-verify-otp.xyz/account',
        },
      ),
      MonitoringEvent(
        id: const Uuid().v4(),
        type: MonitoringEventType.url,
        source: 'https://www.google.com',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        status: MonitoringEventStatus.queued,
        metadata: {
          'presetName': 'TEST 4: Normal URL',
          'expected': 'LOW RISK',
          'url': 'https://www.google.com',
        },
      ),
      MonitoringEvent(
        id: const Uuid().v4(),
        type: MonitoringEventType.app,
        source: "App installed from unknown download source requesting SMS and Contacts permission: 'FreeLoansFast.apk'",
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        status: MonitoringEventStatus.queued,
        metadata: {
          'presetName': 'TEST 5: Unknown App',
          'expected': 'MEDIUM RISK',
          'appName': 'FreeLoansFast.apk',
        },
      ),
    ];
  }

  @override
  void dispose() {
    _historyService.removeListener(_onStateChange);
    _eventQueueService.removeListener(_onStateChange);
    _customInputController.dispose();
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  Future<void> _runAnalysis(MonitoringEvent event) async {
    setState(() {
      _state = ThreatDetectionState.analyzing;
      _currentResult = null;
    });

    try {
      final result = await _analyzer.analyze(event);

      if (mounted) {
        setState(() {
          _state = ThreatDetectionState.complete;
          _currentResult = result;
        });
        _historyService.addResult(result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _state = ThreatDetectionState.error;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to analyze this activity.')),
        );
      }
    }
  }

  void _runCustomAnalysis() {
    final text = _customInputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter message or link to analyze.')),
      );
      return;
    }

    final customEvent = MonitoringEvent(
      id: const Uuid().v4(),
      type: _customType,
      source: text,
      timestamp: DateTime.now(),
      status: MonitoringEventStatus.analyzing,
      metadata: {'text': text, 'url': text},
    );

    setState(() {
      _selectedEvent = customEvent;
    });

    _runAnalysis(customEvent);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Security Check',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Digital Safety Analyzer',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero AI Security Core Visual
              Center(
                child: ThreatDetectionHero(
                  state: _state,
                  riskLevel: _currentResult?.riskLevel,
                  size: 190,
                ),
              ),
              const SizedBox(height: 28),

              // Active Analysis Result Card (if complete)
              if (_state == ThreatDetectionState.complete && _currentResult != null) ...[
                ThreatResultCard(
                  result: _currentResult!,
                  onDismiss: () {
                    setState(() {
                      _state = ThreatDetectionState.waiting;
                      _currentResult = null;
                    });
                  },
                ),
                const SizedBox(height: 28),
              ],

              // Current Selection Box & Analyze Button
              _buildTargetEventCard(isDark),
              const SizedBox(height: 28),

              // Test Presets & Live Events Selector
              _buildPresetsSection(isDark),
              const SizedBox(height: 28),

              // Custom Input Expander
              _buildCustomInputSection(isDark),
              const SizedBox(height: 32),

              // Recent Security Checks (History)
              _buildHistorySection(isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetEventCard(bool isDark) {
    final event = _selectedEvent;
    final isAnalyzing = _state == ThreatDetectionState.analyzing;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.electricCyan.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.royalBlue.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, color: AppTheme.royalBlue, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'SELECTED ACTIVITY',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? AppTheme.silver : AppTheme.royalBlue,
                    ),
                  ),
                ],
              ),
              if (event != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.electricCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.typeName,
                    style: const TextStyle(
                      color: AppTheme.electricCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.deepNavy : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              event != null ? event.source : 'No activity selected. Choose a preset or live event below.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : AppTheme.deepNavy,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Large ANALYZE NOW button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (isAnalyzing || event == null) ? null : () => _runAnalysis(event),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: isAnalyzing
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'CHECKING ACTIVITY...',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bolt, size: 22, color: AppTheme.electricCyan),
                        SizedBox(width: 8),
                        Text(
                          'ANALYZE NOW',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Demonstration Test Presets',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '5 Safe Tests',
              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.silver : Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._testPresets.map((preset) {
          final isSelected = _selectedEvent?.id == preset.id;
          final presetName = preset.metadata?['presetName'] as String? ?? 'Test';
          final expected = preset.metadata?['expected'] as String? ?? '';
          final isHighExpected = expected.contains('HIGH');
          final isMedExpected = expected.contains('MEDIUM');

          final Color expectedColor = isHighExpected
              ? AppTheme.criticalRed
              : (isMedExpected ? AppTheme.warningAmber : AppTheme.safeGreen);

          return Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedEvent = preset;
                  _isCustomMode = false;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark
                      ? (isSelected ? AppTheme.royalBlue.withValues(alpha: 0.25) : const Color(0xFF1E293B))
                      : (isSelected ? AppTheme.royalBlue.withValues(alpha: 0.1) : Colors.white),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppTheme.royalBlue : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: expectedColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isHighExpected
                            ? Icons.warning_amber_rounded
                            : (isMedExpected ? Icons.info_outline : Icons.check_circle_outline),
                        color: expectedColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                presetName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : AppTheme.deepNavy,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: expectedColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  expected,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: expectedColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preset.source,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppTheme.silver : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCustomInputSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: ExpansionTile(
        initiallyExpanded: _isCustomMode,
        onExpansionChanged: (val) => setState(() => _isCustomMode = val),
        title: const Text(
          'Analyze Custom Message or Link',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Type or paste anything to test locally',
          style: TextStyle(fontSize: 12, color: isDark ? AppTheme.silver : Colors.grey),
        ),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text('Type: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('SMS / Text'),
                selected: _customType == MonitoringEventType.sms,
                onSelected: (val) => setState(() => _customType = MonitoringEventType.sms),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Link / URL'),
                selected: _customType == MonitoringEventType.url,
                onSelected: (val) => setState(() => _customType = MonitoringEventType.url),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _customInputController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _customType == MonitoringEventType.sms
                  ? 'e.g. Please share your 6-digit OTP to verify KYC...'
                  : 'e.g. http://login-secure-banking.xyz',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: isDark ? AppTheme.deepNavy : const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _runCustomAnalysis,
              icon: const Icon(Icons.search),
              label: const Text('TEST CUSTOM INPUT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.electricCyan,
                foregroundColor: AppTheme.deepNavy,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(bool isDark) {
    final history = _historyService.history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Security Checks',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '${history.length} checks',
              style: TextStyle(fontSize: 12, color: isDark ? AppTheme.silver : Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (history.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: const Text('No past threat analyses yet.'),
          )
        else
          ...history.map((res) {
            final color = res.riskLevel.color;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  setState(() {
                    _currentResult = res;
                    _state = ThreatDetectionState.complete;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(res.riskLevel.icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  res.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : AppTheme.deepNavy,
                                  ),
                                ),
                                Text(
                                  'Score: ${res.riskScore}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              res.summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppTheme.silver : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
