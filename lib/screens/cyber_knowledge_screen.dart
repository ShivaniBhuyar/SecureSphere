import 'package:flutter/material.dart';
import '../models/knowledge_entry.dart';
import '../models/threat_analysis_result.dart';
import '../services/api_service.dart';
import '../services/knowledge_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/knowledge_card.dart';
import 'knowledge_detail_screen.dart';

/// Module 4: Cyber Knowledge Base Screen.
/// Provides offline, accessible cybersecurity knowledge and guidance.
class CyberKnowledgeScreen extends StatefulWidget {
  final ThreatAnalysisResult? initialThreat;

  const CyberKnowledgeScreen({super.key, this.initialThreat});

  @override
  State<CyberKnowledgeScreen> createState() => _CyberKnowledgeScreenState();
}

class _CyberKnowledgeScreenState extends State<CyberKnowledgeScreen> {
  final KnowledgeRepository _repository = KnowledgeRepository();
  final TextEditingController _searchController = TextEditingController();

  KnowledgeCategory? _selectedCategory;
  List<KnowledgeEntry> _displayedEntries = [];
  KnowledgeEntry? _matchedThreatEntry;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _displayedEntries = _repository.getAllEntries();

    if (widget.initialThreat != null) {
      _matchedThreatEntry = _repository.findRelevantKnowledge(widget.initialThreat!);
    }

    _searchController.addListener(_onSearchChanged);
    _syncOnlineKnowledge();
  }

  Future<void> _syncOnlineKnowledge() async {
    final online = await ApiService().checkHealth();
    if (mounted) {
      setState(() {
        _isOnline = online;
      });
    }
    if (online) {
      final updated = await _repository.refreshFromOnline();
      if (updated && mounted) {
        _filterEntries();
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterEntries();
  }

  void _filterEntries() async {
    final query = _searchController.text;
    final results = await _repository.searchOnlineOrOffline(query, category: _selectedCategory);
    if (mounted) {
      setState(() {
        _displayedEntries = results;
      });
    }
  }

  void _selectCategory(KnowledgeCategory? category) {
    setState(() {
      _selectedCategory = category;
      _filterEntries();
    });
  }

  void _openDetail(KnowledgeEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => KnowledgeDetailScreen(entry: entry),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _syncOnlineKnowledge,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // App Bar & Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button (if can pop) + Title
                      Row(
                        children: [
                          if (Navigator.of(context).canPop())
                            Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => Navigator.of(context).pop(),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cyber Safety',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : AppTheme.deepNavy,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Learn how to stay safe online',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: isDark ? AppTheme.silver : Colors.grey.shade600,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: _syncOnlineKnowledge,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: _isOnline ? AppTheme.safeGreen : Colors.grey.shade500,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isOnline ? 'Online (Cloud Intelligence Active)' : 'Offline Mode (Local Security)',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: _isOnline ? AppTheme.safeGreen : Colors.grey.shade500,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(
                                          Icons.refresh,
                                          size: 13,
                                          color: _isOnline ? AppTheme.safeGreen : Colors.grey.shade500,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                    // Threat-Aware Highlight Banner (if navigated from Module 3 threat detection)
                    if (_matchedThreatEntry != null) ...[
                      _buildThreatBanner(isDark, _matchedThreatEntry!),
                      const SizedBox(height: 20),
                    ],

                    // Search Field
                    _buildSearchBar(isDark),
                    const SizedBox(height: 16),

                    // Categories Horizontal Bar
                    _buildCategoryChips(isDark),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Content List or Empty State
            if (_displayedEntries.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(isDark),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final entry = _displayedEntries[index];
                      return KnowledgeCard(
                        entry: entry,
                        onTap: () => _openDetail(entry),
                      );
                    },
                    childCount: _displayedEntries.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

  /// Highlight banner linking detected threat to its matching topic.
  Widget _buildThreatBanner(bool isDark, KnowledgeEntry entry) {
    final threat = widget.initialThreat!;
    final color = threat.riskLevel.color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(threat.riskLevel.icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                'RECOMMENDED SAFETY TOPIC',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Matched for: ${threat.title}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppTheme.deepNavy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.description,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.silver : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openDetail(entry),
              icon: const Icon(Icons.menu_book, size: 16),
              label: Text('Read "${entry.title}" Guide'),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Search text input matching requirements.
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: TextStyle(
          color: isDark ? Colors.white : AppTheme.deepNavy,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Search cyber safety topics...',
          hintStyle: TextStyle(
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
            fontSize: 14,
          ),
          prefixIcon: const Icon(Icons.search, color: AppTheme.royalBlue),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  /// Category chips row for quick filtering.
  Widget _buildCategoryChips(bool isDark) {
    final categories = [null, ...KnowledgeCategory.values];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = _selectedCategory == cat;

          final label = cat == null ? 'All Topics' : cat.label;
          final icon = cat == null ? Icons.grid_view : cat.icon;

          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            avatar: Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : (isDark ? AppTheme.silver : AppTheme.deepNavy),
            ),
            label: Text(label),
            labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : (isDark ? AppTheme.silver : AppTheme.deepNavy),
            ),
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            selectedColor: AppTheme.royalBlue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected
                    ? AppTheme.royalBlue
                    : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08)),
              ),
            ),
            onSelected: (_) => _selectCategory(cat),
          );
        },
      ),
    );
  }

  /// Empty state matching the required prompt text.
  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.royalBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.search_off, size: 48, color: AppTheme.royalBlue),
            ),
            const SizedBox(height: 20),
            Text(
              'No matching safety topic found.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.deepNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try searching for OTP, UPI, scam, password or phishing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? AppTheme.silver : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: ['OTP', 'UPI', 'scam', 'password', 'phishing', 'WhatsApp'].map((term) {
                return ActionChip(
                  label: Text(term),
                  labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.royalBlue),
                  backgroundColor: AppTheme.royalBlue.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: AppTheme.royalBlue.withValues(alpha: 0.3)),
                  ),
                  onPressed: () {
                    _searchController.text = term;
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
