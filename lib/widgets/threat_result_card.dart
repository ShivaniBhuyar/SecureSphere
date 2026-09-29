import 'package:flutter/material.dart';
import '../models/threat_analysis_result.dart';
import '../screens/knowledge_detail_screen.dart';
import '../services/knowledge_repository.dart';
import '../theme/app_theme.dart';
import 'risk_indicator.dart';

class ThreatResultCard extends StatelessWidget {
  final ThreatAnalysisResult result;
  final VoidCallback? onDismiss;

  const ThreatResultCard({
    super.key,
    required this.result,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final color = result.riskLevel.color;

    return Card(
      elevation: 0,
      color: isDark ? AppTheme.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: color.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'SECURITY ANALYSIS',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onDismiss,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Score and Summary Block
            Center(
              child: RiskIndicator(
                score: result.riskScore,
                level: result.riskLevel,
                size: 110,
              ),
            ),
            const SizedBox(height: 20),

            // Title & Summary
            Center(
              child: Text(
                result.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.deepNavy,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                result.summary,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppTheme.silver : Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Divider(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
            const SizedBox(height: 16),

            // Why? (Indicators)
            Text(
              'Why is this flagged?',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.deepNavy,
              ),
            ),
            const SizedBox(height: 10),
            ...result.indicators.map((indicator) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        indicator,
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.silver : Colors.grey.shade800,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),
            Divider(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)),
            const SizedBox(height: 16),

            // What should you do? (Recommended Action)
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  'What should you do?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.deepNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Text(
                result.recommendedAction,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppTheme.deepNavy,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final repo = KnowledgeRepository();
                  final entry = repo.findRelevantKnowledge(result);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => KnowledgeDetailScreen(entry: entry),
                    ),
                  );
                },
                icon: Icon(Icons.menu_book, size: 18, color: color),
                label: Text(
                  'Read Full Cyber Safety Guide',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.deepNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: color.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
