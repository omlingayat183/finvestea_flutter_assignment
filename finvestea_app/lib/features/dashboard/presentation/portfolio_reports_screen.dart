import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme.dart';
import '../services/portfolio_document_parser.dart';
import '../services/portfolio_analysis_service.dart';
import '../services/portfolio_ai_insight_service.dart';

class PortfolioReportsScreen extends StatefulWidget {
  const PortfolioReportsScreen({super.key});

  @override
  State<PortfolioReportsScreen> createState() => _PortfolioReportsScreenState();
}

class _PortfolioReportsScreenState extends State<PortfolioReportsScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  int _activeTab = 0;

  // One key per section: 0=Overview, 1=Returns, 2=Holdings, 3=Allocation, 4=AI Insights
  final List<GlobalKey> _sectionKeys = List.generate(5, (_) => GlobalKey());

  static const List<String> _tabLabels = [
    'Overview',
    'Returns',
    'Holdings',
    'Allocation',
    'AI Insight ✨',
  ];

  late List<PortfolioInvestment> _investments;
  late PortfolioAnalysis _analysis;
  AiInsightResult? _aiInsights;
  bool _aiLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _investments = PortfolioDocumentParser.getDemoPortfolio();
    _analysis = PortfolioAnalysisService.analyze(_investments);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _scrollController.addListener(_onScroll);
  }

  // ── Scroll detection: update active tab based on which section is near top ──
  void _onScroll() {
    // Walk sections bottom-to-top; the last one whose top is at or above the
    // threshold wins (threshold = 200px from screen top).
    const double threshold = 200.0;
    for (int i = _sectionKeys.length - 1; i >= 0; i--) {
      final ctx = _sectionKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      final dy = box.localToGlobal(Offset.zero).dy;
      if (dy <= threshold) {
        if (_activeTab != i) setState(() => _activeTab = i);
        return;
      }
    }
    // If nothing reached the threshold yet, we're at the top
    if (_activeTab != 0) setState(() => _activeTab = 0);
  }

  // ── Smooth scroll to a section when a tab is tapped ──
  // Uses RenderAbstractViewport to compute the exact scroll offset so that
  // navigation works in both directions (up and down).
  void _scrollToSection(int index) {
    setState(() => _activeTab = index);

    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;

    // RenderAbstractViewport gives us the scroll offset needed to align the
    // target to the top of the viewport (alignment = 0.0), regardless of
    // whether we are scrolling up or down.
    final viewport = RenderAbstractViewport.of(box);
    final targetOffset = viewport
        .getOffsetToReveal(box, 0.0)
        .offset
        .clamp(
          _scrollController.position.minScrollExtent,
          _scrollController.position.maxScrollExtent,
        );

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _loadAiInsights() async {
    setState(() => _aiLoading = true);
    final result = await PortfolioAiInsightService.generateInsights(
        _investments, _analysis);
    if (mounted) {
      setState(() {
        _aiInsights = result;
        _aiLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ═══════════════════════════ BUILD ═══════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.mainGradient,
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildAppBar(context),
                _buildPortfolioHeader(),
                _buildTabBar(),
                Expanded(
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                    children: [
                      _buildSection(0, _buildOverviewContent()),
                      _buildSection(1, _buildReturnsContent()),
                      _buildSection(2, _buildHoldingsContent()),
                      _buildSection(3, _buildAllocationContent()),
                      _buildSection(4, _buildAiInsightsContent()),
                      _buildDocumentsBlock(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/portfolio-import'),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(LucideIcons.uploadCloud, size: 18, color: Colors.white),
        label: const Text('Import',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ═══════════════════════════ APP BAR ═══════════════════════════

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              'Portfolio & Reports',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.upload, color: AppTheme.primaryColor),
            onPressed: () => context.push('/portfolio-import'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════ PORTFOLIO HEADER ═══════════════════════════

  Widget _buildPortfolioHeader() {
    final fmt = PortfolioAnalysisService.formatIndianCurrency;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Portfolio Value',
              style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            fmt(_analysis.currentValue),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildHeaderStat(
                'Returns',
                '${_analysis.isProfit ? '+' : ''}${fmt(_analysis.totalReturns)}',
                _analysis.isProfit ? Colors.greenAccent : Colors.redAccent,
              ),
              _buildHeaderDivider(),
              _buildHeaderStat(
                '% Return',
                '${_analysis.isProfit ? '+' : ''}${_analysis.returnPercentage.toStringAsFixed(1)}%',
                _analysis.isProfit ? Colors.greenAccent : Colors.redAccent,
              ),
              _buildHeaderDivider(),
              _buildHeaderStat(
                'Invested',
                fmt(_analysis.totalInvested),
                Colors.white70,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Text(value,
              style: TextStyle(
                  color: valueColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildHeaderDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  // ═══════════════════════════ TAB BAR (ANCHOR NAVIGATION) ══════════════════

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(4),
        child: Row(
          children: List.generate(_tabLabels.length, (i) {
            final isActive = _activeTab == i;
            return GestureDetector(
              onTap: () => _scrollToSection(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppTheme.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _tabLabels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive
                        ? Colors.white
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ═══════════════════════════ SECTION WRAPPER ═══════════════════════════

  /// Wraps content in a keyed container with a section label.
  Widget _buildSection(int index, Widget content) {
    return Container(
      key: _sectionKeys[index],
      margin: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionLabel(_tabLabels[index].replaceAll(' ✨', '')),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.4,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════ SECTION CONTENT ═══════════════════════════

  // ── Overview ──────────────────────────────────────────────────────────────
  Widget _buildOverviewContent() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Holdings', '${_analysis.totalHoldings}',
                LucideIcons.briefcase, AppTheme.primaryColor),
            const SizedBox(width: 12),
            _buildStatCard('Classes', '${_analysis.allocation.length}',
                LucideIcons.layers, AppTheme.accentColor),
          ],
        ),
        const SizedBox(height: 12),
        Row(children: [
          _buildStatCard(
            'Performance',
            _performanceLabel(_analysis.returnPercentage),
            LucideIcons.trendingUp,
            _analysis.isProfit ? Colors.greenAccent : Colors.redAccent,
          )
        ]),
        const SizedBox(height: 20),
        _buildSubLabel('Asset Allocation'),
        const SizedBox(height: 10),
        _buildMiniAllocationChart(),
        const SizedBox(height: 20),
        _buildSubLabel('Top Performers'),
        const SizedBox(height: 10),
        ..._analysis.topPerformers.map(_buildInvestmentCard),
      ],
    );
  }

  // ── Returns ───────────────────────────────────────────────────────────────
  Widget _buildReturnsContent() {
    return Column(
      children: [
        _buildSubLabel('Growth Trajectory'),
        const SizedBox(height: 10),
        _buildGrowthChart(),
        const SizedBox(height: 20),
        _buildSubLabel('Return per Investment'),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration,
          child: Column(
            children: _investments.map(_buildReturnRow).toList(),
          ),
        ),
      ],
    );
  }

  // ── Holdings ──────────────────────────────────────────────────────────────
  Widget _buildHoldingsContent() {
    return Column(
      children: _investments.map(_buildDetailedInvestmentCard).toList(),
    );
  }

  // ── Allocation ────────────────────────────────────────────────────────────
  Widget _buildAllocationContent() {
    return Column(
      children: [
        _buildSubLabel('Portfolio Diversification'),
        const SizedBox(height: 10),
        _buildLargeAllocationChart(),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration,
          child: Column(
            children: _analysis.allocation.map(_buildAllocationItem).toList(),
          ),
        ),
      ],
    );
  }

  // ── AI Insights ───────────────────────────────────────────────────────────
  Widget _buildAiInsightsContent() {
    if (_aiLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_aiInsights == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: AppTheme.glassDecoration,
        child: Column(
          children: [
            const Icon(LucideIcons.sparkles,
                size: 36, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            const Text(
              'AI Portfolio Analysis',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap below to generate AI-powered insights about your portfolio performance.',
              style: TextStyle(
                  color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadAiInsights,
              icon: const Icon(LucideIcons.sparkles, size: 16),
              label: const Text('Generate AI Insights'),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        _buildAiCard('Summary', _aiInsights!.performanceSummary,
            LucideIcons.trendingUp, AppTheme.primaryColor),
        _buildAiCard('Risk', _aiInsights!.riskSummary, LucideIcons.shieldCheck,
            const Color(0xFF60A5FA)),
        _buildAiCard(
            'Diversification',
            _aiInsights!.diversificationAnalysis,
            LucideIcons.pieChart,
            AppTheme.accentColor),
        _buildSubLabel('Recommendations'),
        const SizedBox(height: 10),
        ..._aiInsights!.suggestions.map(_buildSuggestionCard),
      ],
    );
  }

  // ── Documents (non-anchored, always at bottom) ────────────────────────────
  Widget _buildDocumentsBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('Documents'),
        const SizedBox(height: 12),
        _buildReportCategory('Tax Statements', [
          _ReportItem(
              'Capital Gains Report', 'FY 2023-24', LucideIcons.fileText),
          _ReportItem(
              'Tax P&L Statement', 'FY 2023-24', LucideIcons.fileText),
        ]),
        const SizedBox(height: 16),
        _buildReportCategory('Performance Reports', [
          _ReportItem(
              'Monthly Portfolio Review', 'Feb 2024', LucideIcons.pieChart),
          _ReportItem('Annual Performance', '2023', LucideIcons.trendingUp),
        ]),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => context.push('/transactions'),
          icon: const Icon(LucideIcons.clock, size: 18),
          label: const Text('View Transaction History'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryColor),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════ SHARED WIDGET HELPERS ═══════════════════════════

  Widget _buildSubLabel(String title) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 1.0),
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(value,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentCard(PortfolioInvestment inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Row(
        children: [
          Icon(_typeIcon(inv.type), color: _typeColor(inv.type), size: 20),
          const SizedBox(width: 12),
          Expanded(
              child: Text(inv.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis)),
          Text(
            '${inv.isProfit ? '+' : ''}${inv.returnPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
                color: inv.isProfit
                    ? AppTheme.primaryColor
                    : Colors.redAccent,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedInvestmentCard(PortfolioInvestment inv) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _typeColor(inv.type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(_typeIcon(inv.type), color: _typeColor(inv.type), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inv.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(inv.type,
                      style: const TextStyle(
                          color: AppTheme.textSecondary, fontSize: 11)),
                ],
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (inv.isProfit
                          ? AppTheme.primaryColor
                          : Colors.redAccent)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${inv.isProfit ? '+' : ''}${inv.returnPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: inv.isProfit
                        ? AppTheme.primaryColor
                        : Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.white10),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInvStat('Invested',
                  PortfolioAnalysisService.formatCurrencyCompact(inv.amountInvested)),
              _buildInvStat('Current',
                  PortfolioAnalysisService.formatCurrencyCompact(inv.currentValue)),
              _buildInvStat('Returns',
                  PortfolioAnalysisService.formatCurrencyCompact(inv.returns),
                  color: inv.isProfit
                      ? AppTheme.primaryColor
                      : Colors.redAccent),
              _buildInvStat('Units', inv.units.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvStat(String label, String value,
      {Color color = Colors.white}) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 12, color: color)),
        Text(label,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 10)),
      ],
    );
  }

  Widget _buildAiCard(
      String title, String body, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.05),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(fontWeight: FontWeight.bold, color: color))
          ]),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppTheme.accentColor.withValues(alpha: 0.2)),
      ),
      child: Text(s,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
    );
  }

  Widget _buildAllocationItem(AllocationItem item) {
    final color =
        Color(int.parse(item.color.replaceAll('#', '0xFF')));
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(item.category,
              style: const TextStyle(fontSize: 13)),
          const Spacer(),
          Text(
            PortfolioAnalysisService.formatCurrencyCompact(item.amount),
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Text('${item.percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildReturnRow(PortfolioInvestment inv) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(_typeIcon(inv.type),
              color: _typeColor(inv.type), size: 16),
          const SizedBox(width: 8),
          Expanded(
              child: Text(inv.name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis)),
          Text(
            PortfolioAnalysisService.formatCurrencyCompact(inv.returns),
            style: TextStyle(
                color: inv.isProfit
                    ? AppTheme.primaryColor
                    : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCategory(String title, List<_ReportItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                letterSpacing: 1.0)),
        const SizedBox(height: 8),
        Container(
          decoration: AppTheme.glassDecoration,
          child: Column(
            children: items
                .map((item) => ListTile(
                      leading: Icon(item.icon,
                          color: AppTheme.primaryColor, size: 20),
                      title: Text(item.title,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(item.subtitle,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary)),
                      trailing: const Icon(LucideIcons.download,
                          size: 18, color: AppTheme.primaryColor),
                      onTap: () {},
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════ CHART WIDGETS ═══════════════════════════

  Widget _buildMiniAllocationChart() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: CustomPaint(painter: _PieChartPainter(_analysis.allocation)),
    );
  }

  Widget _buildLargeAllocationChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration,
      child: CustomPaint(painter: _PieChartPainter(_analysis.allocation)),
    );
  }

  Widget _buildGrowthChart() {
    // Data points representing growth trajectory towards actual return %
    final pct = _analysis.returnPercentage;
    final points = [
      0.0,
      pct * 0.07,
      pct * 0.18,
      pct * 0.30,
      pct * 0.42,
      pct * 0.54,
      pct * 0.63,
      pct * 0.72,
      pct * 0.80,
      pct * 0.89,
      pct * 0.95,
      pct,
    ];
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration,
      child: CustomPaint(painter: _LineChartPainter(points)),
    );
  }

  // ═══════════════════════════ HELPER METHODS ═══════════════════════════

  String _performanceLabel(double pct) {
    if (pct >= 20) return 'Excellent (${pct.toStringAsFixed(1)}%)';
    if (pct >= 10) return 'Good (${pct.toStringAsFixed(1)}%)';
    if (pct >= 0) return 'Moderate (${pct.toStringAsFixed(1)}%)';
    return 'Loss (${pct.toStringAsFixed(1)}%)';
  }

  Color _typeColor(String t) {
    if (t == 'Mutual Fund') return AppTheme.primaryColor;
    if (t == 'Stock' || t == 'Stocks') return AppTheme.accentColor;
    if (t == 'ETF') return Colors.blueAccent;
    if (t == 'Gold') return const Color(0xFFF59E0B);
    return Colors.purpleAccent;
  }

  IconData _typeIcon(String t) {
    if (t == 'Mutual Fund') return LucideIcons.barChart2;
    if (t == 'ETF') return LucideIcons.barChart;
    if (t == 'Gold') return LucideIcons.coins;
    return LucideIcons.trendingUp;
  }
}

// ═══════════════════════════ DATA CLASS ═══════════════════════════

class _ReportItem {
  final String title, subtitle;
  final IconData icon;
  _ReportItem(this.title, this.subtitle, this.icon);
}

// ═══════════════════════════ PIE CHART PAINTER ═══════════════════════════

class _PieChartPainter extends CustomPainter {
  final List<AllocationItem> data;
  _PieChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    double currentAngle = -math.pi / 2;

    for (var item in data) {
      final sweep = 2 * math.pi * (item.percentage / 100);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweep - 0.04,
        false,
        Paint()
          ..color = Color(int.parse(item.color.replaceAll('#', '0xFF')))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
      currentAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═══════════════════════════ LINE CHART PAINTER ═══════════════════════════

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  _LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.reduce(math.max);
    final minVal = data.reduce(math.min);
    final range = (maxVal - minVal).clamp(1.0, double.infinity);

    // Gradient fill
    final fillPath = Path();
    final linePath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - ((data[i] - minVal) / range * size.height * 0.85) - size.height * 0.05;
      if (i == 0) {
        fillPath.moveTo(x, y);
        linePath.moveTo(x, y);
      } else {
        fillPath.lineTo(x, y);
        linePath.lineTo(x, y);
      }
    }
    fillPath
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.3),
            AppTheme.primaryColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppTheme.primaryColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
