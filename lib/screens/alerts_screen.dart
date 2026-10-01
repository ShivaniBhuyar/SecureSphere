import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/security_alert.dart';
import '../services/alert_service.dart';
import '../theme/app_theme.dart';
import 'knowledge_detail_screen.dart';

/// Module 5 — Alert & Notification Screen (Alert Center & Threat History)
/// Displays security alerts received from Module 3 Threat Detection,
/// visualizes risk levels, detailed indicators, and recommended actions,
/// and manages read/unread state.
class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

enum _AlertFilter { all, unread, high, medium, low }

class _AlertsScreenState extends State<AlertsScreen> {
  _AlertFilter _currentFilter = _AlertFilter.all;

  @override
  Widget build(BuildContext context) {
    final alertService = Provider.of<AlertService>(context);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredAlerts = _getFilteredAlerts(alertService);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Safety Alerts',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Live threat notifications & alert center',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.silver : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (alertService.unreadCount > 0)
            TextButton.icon(
              icon: const Icon(Icons.done_all, size: 16, color: AppTheme.electricCyan),
              label: const Text(
                'Mark All Read',
                style: TextStyle(color: AppTheme.electricCyan, fontSize: 12),
              ),
              onPressed: () {
                alertService.markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All alerts marked as read'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips Row
          _buildFilterBar(alertService),

          // Alert Cards List
          Expanded(
            child: filteredAlerts.isEmpty
                ? _buildEmptyState(isDark)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = filteredAlerts[index];
                      return _buildAlertCard(context, alert, alertService, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AlertService alertService) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            label: 'All (${alertService.alerts.length})',
            filter: _AlertFilter.all,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Unread (${alertService.unreadCount})',
            filter: _AlertFilter.unread,
            accentColor: AppTheme.electricCyan,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'High (${alertService.highRiskAlerts.length})',
            filter: _AlertFilter.high,
            accentColor: AppTheme.criticalRed,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Medium (${alertService.mediumRiskAlerts.length})',
            filter: _AlertFilter.medium,
            accentColor: AppTheme.warningAmber,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: 'Low (${alertService.lowRiskAlerts.length})',
            filter: _AlertFilter.low,
            accentColor: AppTheme.safeGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required _AlertFilter filter,
    Color? accentColor,
  }) {
    final isSelected = _currentFilter == filter;
    final color = accentColor ?? AppTheme.royalBlue;

    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.grey.shade400,
        ),
      ),
      backgroundColor: Colors.transparent,
      selectedColor: color.withValues(alpha: 0.3),
      side: BorderSide(
        color: isSelected ? color : Colors.white.withValues(alpha: 0.15),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      onSelected: (_) {
        setState(() {
          _currentFilter = filter;
        });
      },
    );
  }

  List<SecurityAlert> _getFilteredAlerts(AlertService service) {
    switch (_currentFilter) {
      case _AlertFilter.all:
        return service.alerts;
      case _AlertFilter.unread:
        return service.unreadAlerts;
      case _AlertFilter.high:
        return service.highRiskAlerts;
      case _AlertFilter.medium:
        return service.mediumRiskAlerts;
      case _AlertFilter.low:
        return service.lowRiskAlerts;
    }
  }

  Widget _buildAlertCard(
    BuildContext context,
    SecurityAlert alert,
    AlertService service,
    bool isDark,
  ) {
    final severityColor = alert.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: alert.isRead
            ? (isDark ? AppTheme.darkSurface.withValues(alpha: 0.6) : Colors.white)
            : (isDark ? AppTheme.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: alert.isRead
              ? Colors.white.withValues(alpha: 0.08)
              : severityColor.withValues(alpha: 0.5),
          width: alert.isRead ? 1 : 1.5,
        ),
        boxShadow: alert.isRead
            ? []
            : [
                BoxShadow(
                  color: severityColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (!alert.isRead) {
              service.markAsRead(alert.id);
            }
            _showAlertDetails(context, alert, service, isDark);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Risk Severity Icon Badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: severityColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Icon(alert.icon, color: severityColor, size: 24),
                ),
                const SizedBox(width: 14),

                // Alert Contents
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Severity & Timestamp Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: severityColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              alert.severityLabel,
                              style: TextStyle(
                                color: severityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            alert.formattedTime,
                            style: TextStyle(
                              color: isDark ? AppTheme.silver : Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                          const Spacer(),
                          if (!alert.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.electricCyan,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        alert.title,
                        style: TextStyle(
                          fontWeight: alert.isRead ? FontWeight.w600 : FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppTheme.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Reason Summary
                      Text(
                        alert.reason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppTheme.silver : Colors.grey.shade700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Bottom Action & Score Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.speed,
                                size: 14,
                                color: severityColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Risk Score: ${alert.riskScore}/100',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: severityColor,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                'Details',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.electricCyan : AppTheme.royalBlue,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: isDark ? AppTheme.electricCyan : AppTheme.royalBlue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.safeGreen.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.safeGreen.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 56,
                color: AppTheme.safeGreen,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Security Alerts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.deepNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No threats matching your current filter. SecureSphere is continuously monitoring in the background.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.silver : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays the full threat details, indicators, and recommended action in a modal bottom sheet
  void _showAlertDetails(
    BuildContext context,
    SecurityAlert alert,
    AlertService service,
    bool isDark,
  ) {
    final severityColor = alert.color;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Prominent Risk Severity Banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: severityColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: severityColor.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(alert.icon, color: severityColor, size: 32),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alert.isHighRisk
                                    ? 'IMMEDIATE ATTENTION REQUIRED'
                                    : (alert.isMediumRisk
                                        ? 'SECURITY WARNING'
                                        : 'INFORMATIONAL CHECK'),
                                style: TextStyle(
                                  color: severityColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Risk Score: ${alert.riskScore} / 100 • ${alert.severityLabel}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Alert Title
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppTheme.deepNavy,
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Timestamp
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 6),
                      Text(
                        alert.formattedFullDate,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Threat Reason / Description
                  const Text(
                    'THREAT ANALYSIS REASON',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.electricCyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alert.reason,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: isDark ? Colors.grey.shade200 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Indicators Detected
                  if (alert.indicators.isNotEmpty) ...[
                    const Text(
                      'DETECTED THREAT INDICATORS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppTheme.electricCyan,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...alert.indicators.map((ind) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Icon(
                                  Icons.warning_amber_rounded,
                                  size: 14,
                                  color: severityColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ind,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.3,
                                    color: isDark ? Colors.grey.shade300 : Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // Recommended Action Box
                  const Text(
                    'RECOMMENDED SECURITY ACTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: AppTheme.safeGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.safeGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.safeGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.security,
                          color: AppTheme.safeGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            alert.recommendedAction,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white : AppTheme.deepNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Related Cyber Knowledge Base Entries
                  if (alert.relatedKnowledge.isNotEmpty) ...[
                    const Text(
                      'RELATED SAFETY TOPICS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: AppTheme.electricCyan,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...alert.relatedKnowledge.map((entry) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppTheme.deepNavy.withValues(alpha: 0.6)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.menu_book_outlined,
                              color: AppTheme.electricCyan,
                            ),
                            title: Text(
                              entry.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            subtitle: Text(
                              entry.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              Navigator.pop(ctx);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => KnowledgeDetailScreen(entry: entry),
                                ),
                              );
                            },
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],

                  // Bottom Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            alert.isRead ? Icons.mark_email_unread : Icons.done,
                            size: 16,
                          ),
                          label: Text(alert.isRead ? 'Mark Unread' : 'Mark Read'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            if (alert.isRead) {
                              service.markAsUnread(alert.id);
                            } else {
                              service.markAsRead(alert.id);
                            }
                            Navigator.pop(ctx);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.royalBlue,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
