import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/alert_service.dart';
import '../widgets/guardian_hero.dart';
import 'cyber_knowledge_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;

  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background ambient lighting
          if (isDark)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.royalBlue.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isDark),
                  const SizedBox(height: 32),
                  const GuardianHero(),
                  const SizedBox(height: 40),
                  _buildActionCards(context, isDark),
                  const SizedBox(height: 24),
                  _buildSafetyTip(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: AppTheme.electricCyan, size: 24),
                const SizedBox(width: 8),
                Text(
                  'SECURESPHERE',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your Digital Safety Guardian',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.silver : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Consumer<AlertService>(
              builder: (context, alertService, child) {
                final unread = alertService.unreadCount;
                return IconButton(
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    backgroundColor: AppTheme.criticalRed,
                    child: Icon(
                      Icons.notifications_none,
                      color: isDark ? Colors.white : AppTheme.deepNavy,
                    ),
                  ),
                  tooltip: 'Safety Alerts',
                  onPressed: () =>
                      onNavigate(3), // Navigate to Alerts (index 3)
                );
              },
            ),
            GestureDetector(
              onTap: () => onNavigate(4), // Navigate to Profile (index 4)
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.electricCyan.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.electricCyan),
                ),
                child: const Icon(
                  Icons.person,
                  size: 20,
                  color: AppTheme.electricCyan,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCards(BuildContext context, bool isDark) {
    return Column(
      children: [
        _ActionCard(
          title: 'SAFETY GUARD',
          subtitle: 'SecureSphere is quietly watching for suspicious activity.',
          icon: Icons.shield_outlined,
          color: AppTheme.safeGreen,
          onTap: () => onNavigate(1), // Navigate to Guard tab
          showStatus: true,
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'ASK SECURESPHERE',
          subtitle: 'Talk to your digital safety assistant',
          icon: Icons.chat_bubble_outline,
          color: AppTheme.electricCyan,
          onTap: () => onNavigate(2), // Navigate to Ask
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'VIEW ALERTS',
          subtitle: 'See important safety reminders',
          icon: Icons.error_outline,
          color: AppTheme.warningAmber,
          onTap: () => onNavigate(3), // Navigate to Alerts
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'CYBER SAFETY',
          subtitle: 'Learn how to stay safe from scams & online fraud',
          icon: Icons.menu_book_outlined,
          color: AppTheme.royalBlue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CyberKnowledgeScreen()),
            );
          },
        ),
        const SizedBox(height: 16),
        _ActionCard(
          title: 'SECURITY REPORTS',
          subtitle: 'Device score, incident history & trend analytics',
          icon: Icons.analytics_outlined,
          color: AppTheme.softViolet,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSafetyTip(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.safeGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.safeGreen.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppTheme.safeGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SAFETY TIP',
                  style: TextStyle(
                    color: AppTheme.safeGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Never share your OTP, PIN or password with anyone.',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppTheme.deepNavy,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool showStatus;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 0,
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.white : AppTheme.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? AppTheme.silver : Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    if (showStatus) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.safeGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active',
                            style: TextStyle(
                              color: AppTheme.safeGreen,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: isDark ? Colors.white24 : Colors.black12,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
