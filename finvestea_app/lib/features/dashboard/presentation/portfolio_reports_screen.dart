// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:go_router/go_router.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import '../../../core/theme.dart';
// import '../services/portfolio_document_parser.dart';
// import '../services/portfolio_analysis_service.dart';
// import '../services/portfolio_ai_insight_service.dart';

// class PortfolioReportsScreen extends StatefulWidget {
//   const PortfolioReportsScreen({super.key});

//   @override
//   State<PortfolioReportsScreen> createState() => _PortfolioReportsScreenState();
// }

// class _PortfolioReportsScreenState extends State<PortfolioReportsScreen>
//     with SingleTickerProviderStateMixin {
//   final ScrollController _scrollController = ScrollController();
//   int _activeTab = 0;

//   // One key per section: 0=Overview, 1=Returns, 2=Holdings, 3=Allocation, 4=AI Insights
//   final List<GlobalKey> _sectionKeys = List.generate(5, (_) => GlobalKey());

//   static const List<String> _tabLabels = [
//     'Overview',
//     'Returns',
//     'Holdings',
//     'Allocation',
//     'AI Insight ✨',
//   ];

//   late List<PortfolioInvestment> _investments;
//   late PortfolioAnalysis _analysis;
//   AiInsightResult? _aiInsights;
//   bool _aiLoading = false;

//   late AnimationController _fadeController;
//   late Animation<double> _fadeAnimation;

//   @override
//   void initState() {
//     super.initState();
//     _investments = PortfolioDocumentParser.getDemoPortfolio();
//     _analysis = PortfolioAnalysisService.analyze(_investments);

//     _fadeController = AnimationController(
//       duration: const Duration(milliseconds: 600),
//       vsync: this,
//     )..forward();
//     _fadeAnimation = CurvedAnimation(
//       parent: _fadeController,
//       curve: Curves.easeOut,
//     );

//     _scrollController.addListener(_onScroll);
//   }

//   // ── Scroll detection: update active tab based on which section is near top ──
//   void _onScroll() {
//     // Walk sections bottom-to-top; the last one whose top is at or above the
//     // threshold wins (threshold = 200px from screen top).
//     const double threshold = 200.0;
//     for (int i = _sectionKeys.length - 1; i >= 0; i--) {
//       final ctx = _sectionKeys[i].currentContext;
//       if (ctx == null) continue;
//       final box = ctx.findRenderObject() as RenderBox?;
//       if (box == null) continue;
//       final dy = box.localToGlobal(Offset.zero).dy;
//       if (dy <= threshold) {
//         if (_activeTab != i) setState(() => _activeTab = i);
//         return;
//       }
//     }
//     // If nothing reached the threshold yet, we're at the top
//     if (_activeTab != 0) setState(() => _activeTab = 0);
//   }

//   // ── Smooth scroll to a section when a tab is tapped ──
//   // Uses RenderAbstractViewport to compute the exact scroll offset so that
//   // navigation works in both directions (up and down).
//   void _scrollToSection(int index) {
//     setState(() => _activeTab = index);

//     final ctx = _sectionKeys[index].currentContext;
//     if (ctx == null) return;

//     final box = ctx.findRenderObject() as RenderBox?;
//     if (box == null) return;

//     // RenderAbstractViewport gives us the scroll offset needed to align the
//     // target to the top of the viewport (alignment = 0.0), regardless of
//     // whether we are scrolling up or down.
//     final viewport = RenderAbstractViewport.of(box);
//     final targetOffset = viewport
//         .getOffsetToReveal(box, 0.0)
//         .offset
//         .clamp(
//           _scrollController.position.minScrollExtent,
//           _scrollController.position.maxScrollExtent,
//         );

//     _scrollController.animateTo(
//       targetOffset,
//       duration: const Duration(milliseconds: 400),
//       curve: Curves.easeInOut,
//     );
//   }

//   Future<void> _loadAiInsights() async {
//     setState(() => _aiLoading = true);
//     final result = await PortfolioAiInsightService.generateInsights(
//       _investments,
//       _analysis,
//     );
//     if (mounted) {
//       setState(() {
//         _aiInsights = result;
//         _aiLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _scrollController.dispose();
//     _fadeController.dispose();
//     super.dispose();
//   }

//   // ═══════════════════════════ BUILD ═══════════════════════════

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: AppTheme.mainGradient,
//         child: SafeArea(
//           child: FadeTransition(
//             opacity: _fadeAnimation,
//             child: Column(
//               children: [
//                 _buildAppBar(context),
//                 _buildPortfolioHeader(),
//                 _buildTabBar(),
//                 Expanded(
//                   child: ListView(
//                     controller: _scrollController,
//                     padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
//                     children: [
//                       _buildSection(0, _buildOverviewContent()),
//                       _buildSection(1, _buildReturnsContent()),
//                       _buildSection(2, _buildHoldingsContent()),
//                       _buildSection(3, _buildAllocationContent()),
//                       _buildSection(4, _buildAiInsightsContent()),
//                       _buildDocumentsBlock(),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () => context.push('/portfolio-import'),
//         backgroundColor: AppTheme.primaryColor,
//         icon: const Icon(
//           LucideIcons.uploadCloud,
//           size: 18,
//           color: Colors.white,
//         ),
//         label: const Text(
//           'Import',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════ APP BAR ═══════════════════════════

//   Widget _buildAppBar(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
//             onPressed: () => context.pop(),
//           ),
//           const Expanded(
//             child: Text(
//               'Portfolio & Reports',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//           ),
//           IconButton(
//             icon: const Icon(LucideIcons.upload, color: AppTheme.primaryColor),
//             onPressed: () => context.push('/portfolio-import'),
//           ),
//         ],
//       ),
//     );
//   }

//   // ═══════════════════════════ PORTFOLIO HEADER ═══════════════════════════

//   Widget _buildPortfolioHeader() {
//     final fmt = PortfolioAnalysisService.formatIndianCurrency;
//     return Container(
//       margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             AppTheme.primaryColor,
//             AppTheme.primaryColor.withValues(alpha: 0.6),
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(24),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'Total Portfolio Value',
//             style: TextStyle(color: Colors.white70, fontSize: 13),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             fmt(_analysis.currentValue),
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 12),
//           Row(
//             children: [
//               _buildHeaderStat(
//                 'Returns',
//                 '${_analysis.isProfit ? '+' : ''}${fmt(_analysis.totalReturns)}',
//                 _analysis.isProfit ? AppTheme.primaryColor : Colors.redAccent,
//               ),
//               _buildHeaderDivider(),
//               _buildHeaderStat(
//                 '% Return',
//                 '${_analysis.isProfit ? '+' : ''}${_analysis.returnPercentage.toStringAsFixed(1)}%',
//                 _analysis.isProfit ? AppTheme.primaryColor : Colors.redAccent,
//               ),
//               _buildHeaderDivider(),
//               _buildHeaderStat(
//                 'Invested',
//                 fmt(_analysis.totalInvested),
//                 Colors.white70,
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderStat(String label, String value, Color valueColor) {
//     return Expanded(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(color: Colors.white60, fontSize: 10),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               color: valueColor,
//               fontWeight: FontWeight.bold,
//               fontSize: 13,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildHeaderDivider() {
//     return Container(
//       width: 1,
//       height: 24,
//       margin: const EdgeInsets.symmetric(horizontal: 12),
//       color: Colors.white.withValues(alpha: 0.2),
//     );
//   }

//   // ═══════════════════════════ TAB BAR (ANCHOR NAVIGATION) ══════════════════

//   Widget _buildTabBar() {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(20, 0, 20, 4),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.05),
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: SingleChildScrollView(
//         scrollDirection: Axis.horizontal,
//         padding: const EdgeInsets.all(4),
//         child: Row(
//           children: List.generate(_tabLabels.length, (i) {
//             final isActive = _activeTab == i;
//             return GestureDetector(
//               onTap: () => _scrollToSection(i),
//               child: AnimatedContainer(
//                 duration: const Duration(milliseconds: 250),
//                 curve: Curves.easeInOut,
//                 margin: const EdgeInsets.symmetric(horizontal: 2),
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 14,
//                   vertical: 8,
//                 ),
//                 decoration: BoxDecoration(
//                   color: isActive ? AppTheme.primaryColor : Colors.transparent,
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 child: Text(
//                   _tabLabels[i],
//                   style: TextStyle(
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                     color: isActive ? Colors.white : AppTheme.textSecondary,
//                   ),
//                 ),
//               ),
//             );
//           }),
//         ),
//       ),
//     );
//   }

//   // ═══════════════════════════ SECTION WRAPPER ═══════════════════════════

//   /// Wraps content in a keyed container with a section label.
//   Widget _buildSection(int index, Widget content) {
//     return Container(
//       key: _sectionKeys[index],
//       margin: const EdgeInsets.only(bottom: 36),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           _buildSectionLabel(_tabLabels[index].replaceAll(' ✨', '')),
//           const SizedBox(height: 12),
//           content,
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionLabel(String title) {
//     return Row(
//       children: [
//         Container(
//           width: 3,
//           height: 16,
//           decoration: BoxDecoration(
//             color: AppTheme.primaryColor,
//             borderRadius: BorderRadius.circular(2),
//           ),
//         ),
//         const SizedBox(width: 8),
//         Text(
//           title.toUpperCase(),
//           style: const TextStyle(
//             color: AppTheme.primaryColor,
//             fontWeight: FontWeight.bold,
//             fontSize: 11,
//             letterSpacing: 1.4,
//           ),
//         ),
//       ],
//     );
//   }

//   // ═══════════════════════════ SECTION CONTENT ═══════════════════════════

//   // ── Overview ──────────────────────────────────────────────────────────────
//   Widget _buildOverviewContent() {
//     return Column(
//       children: [
//         Row(
//           children: [
//             _buildStatCard(
//               'Holdings',
//               '${_analysis.totalHoldings}',
//               LucideIcons.briefcase,
//               AppTheme.primaryColor,
//             ),
//             const SizedBox(width: 12),
//             _buildStatCard(
//               'Classes',
//               '${_analysis.allocation.length}',
//               LucideIcons.layers,
//               AppTheme.secondaryAccentColor,
//             ),
//           ],
//         ),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             _buildStatCard(
//               'Performance',
//               _performanceLabel(_analysis.returnPercentage),
//               LucideIcons.trendingUp,
//               _analysis.isProfit ? AppTheme.primaryColor : Colors.redAccent,
//             ),
//           ],
//         ),
//         const SizedBox(height: 20),
//         _buildSubLabel('Top Performers'),
//         const SizedBox(height: 10),
//         ..._analysis.topPerformers.map(_buildInvestmentCard),
//       ],
//     );
//   }

//   // ── Returns ───────────────────────────────────────────────────────────────
//   Widget _buildReturnsContent() {
//     return Column(
//       children: [
//         _buildSubLabel('Growth Trajectory'),
//         const SizedBox(height: 20),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: AppTheme.glassDecoration,
//           child: Column(children: _investments.map(_buildReturnRow).toList()),
//         ),
//       ],
//     );
//   }

//   // ── Holdings ──────────────────────────────────────────────────────────────
//   Widget _buildHoldingsContent() {
//     return Column(
//       children: _investments.map(_buildDetailedInvestmentCard).toList(),
//     );
//   }

//   // ── Allocation ────────────────────────────────────────────────────────────
//   Widget _buildAllocationContent() {
//     return Column(
//       children: [
//         _buildSubLabel('Portfolio Diversification'),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: AppTheme.glassDecoration,
//           child: Column(
//             children: _analysis.allocation.map(_buildAllocationItem).toList(),
//           ),
//         ),
//       ],
//     );
//   }

//   // ── AI Insights ───────────────────────────────────────────────────────────
//   Widget _buildAiInsightsContent() {
//     if (_aiLoading) {
//       return const Padding(
//         padding: EdgeInsets.symmetric(vertical: 40),
//         child: Center(child: CircularProgressIndicator()),
//       );
//     }
//     if (_aiInsights == null) {
//       return Container(
//         width: double.infinity,
//         padding: const EdgeInsets.all(24),
//         decoration: AppTheme.glassDecoration,
//         child: Column(
//           children: [
//             const Icon(
//               LucideIcons.sparkles,
//               size: 36,
//               color: AppTheme.primaryColor,
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               'AI Portfolio Analysis',
//               style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
//             ),
//             const SizedBox(height: 8),
//             const Text(
//               'Tap below to generate AI-powered insights about your portfolio performance.',
//               style: TextStyle(
//                 color: AppTheme.textSecondary,
//                 fontSize: 13,
//                 height: 1.5,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: _loadAiInsights,
//               icon: const Icon(LucideIcons.sparkles, size: 16),
//               label: const Text('Generate AI Insights'),
//             ),
//           ],
//         ),
//       );
//     }
//     return Column(
//       children: [
//         _buildAiCard(
//           'Summary',
//           _aiInsights!.performanceSummary,
//           LucideIcons.trendingUp,
//           AppTheme.primaryColor,
//         ),
//         _buildAiCard(
//           'Risk',
//           _aiInsights!.riskSummary,
//           LucideIcons.shieldCheck,
//           const Color(0xFF60A5FA),
//         ),
//         _buildAiCard(
//           'Diversification',
//           _aiInsights!.diversificationAnalysis,
//           LucideIcons.pieChart,
//           AppTheme.secondaryAccentColor,
//         ),
//         _buildSubLabel('Recommendations'),
//         const SizedBox(height: 10),
//         ..._aiInsights!.suggestions.map(_buildSuggestionCard),
//       ],
//     );
//   }

//   // ── Documents (non-anchored, always at bottom) ────────────────────────────
//   Widget _buildDocumentsBlock() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         _buildSectionLabel('Documents'),
//         const SizedBox(height: 12),
//         _buildReportCategory('Tax Statements', [
//           _ReportItem(
//             'Capital Gains Report',
//             'FY 2023-24',
//             LucideIcons.fileText,
//           ),
//           _ReportItem('Tax P&L Statement', 'FY 2023-24', LucideIcons.fileText),
//         ]),
//         const SizedBox(height: 16),
//         _buildReportCategory('Performance Reports', [
//           _ReportItem(
//             'Monthly Portfolio Review',
//             'Feb 2024',
//             LucideIcons.pieChart,
//           ),
//           _ReportItem('Annual Performance', '2023', LucideIcons.trendingUp),
//         ]),
//         const SizedBox(height: 16),
//         OutlinedButton.icon(
//           onPressed: () => context.push('/transactions'),
//           icon: const Icon(LucideIcons.clock, size: 18),
//           label: const Text('View Transaction History'),
//           style: OutlinedButton.styleFrom(
//             side: const BorderSide(color: AppTheme.primaryColor),
//             minimumSize: const Size(double.infinity, 52),
//           ),
//         ),
//       ],
//     );
//   }

//   // ═══════════════════════════ SHARED WIDGET HELPERS ═══════════════════════════

//   Widget _buildSubLabel(String title) {
//     return Text(
//       title.toUpperCase(),
//       style: const TextStyle(
//         color: AppTheme.textSecondary,
//         fontWeight: FontWeight.w600,
//         fontSize: 10,
//         letterSpacing: 1.0,
//       ),
//     );
//   }

//   Widget _buildStatCard(
//     String label,
//     String value,
//     IconData icon,
//     Color color,
//   ) {
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(16),
//         decoration: AppTheme.glassDecoration,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Icon(icon, color: color, size: 20),
//             const SizedBox(height: 12),
//             Text(
//               value,
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: color,
//               ),
//             ),
//             Text(
//               label,
//               style: const TextStyle(
//                 color: AppTheme.textSecondary,
//                 fontSize: 10,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInvestmentCard(PortfolioInvestment inv) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(16),
//       decoration: AppTheme.glassDecoration,
//       child: Row(
//         children: [
//           Icon(_typeIcon(inv.type), color: _typeColor(inv.type), size: 20),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               inv.name,
//               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           Text(
//             '${inv.isProfit ? '+' : ''}${inv.returnPercentage.toStringAsFixed(1)}%',
//             style: TextStyle(
//               color: inv.isProfit ? AppTheme.primaryColor : Colors.redAccent,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildDetailedInvestmentCard(PortfolioInvestment inv) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: AppTheme.glassDecoration,
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(8),
//                 decoration: BoxDecoration(
//                   color: _typeColor(inv.type).withValues(alpha: 0.1),
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 child: Icon(
//                   _typeIcon(inv.type),
//                   color: _typeColor(inv.type),
//                   size: 18,
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       inv.name,
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 14,
//                       ),
//                     ),
//                     Text(
//                       inv.type,
//                       style: const TextStyle(
//                         color: AppTheme.textSecondary,
//                         fontSize: 11,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                 decoration: BoxDecoration(
//                   color:
//                       (inv.isProfit ? AppTheme.primaryColor : Colors.redAccent)
//                           .withValues(alpha: 0.15),
//                   borderRadius: BorderRadius.circular(8),
//                 ),
//                 child: Text(
//                   '${inv.isProfit ? '+' : ''}${inv.returnPercentage.toStringAsFixed(1)}%',
//                   style: TextStyle(
//                     color: inv.isProfit
//                         ? AppTheme.primaryColor
//                         : Colors.redAccent,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 12),
//           const Divider(height: 1, color: Colors.white10),
//           const SizedBox(height: 12),
//           Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               _buildInvStat(
//                 'Invested',
//                 PortfolioAnalysisService.formatCurrencyCompact(
//                   inv.amountInvested,
//                 ),
//               ),
//               _buildInvStat(
//                 'Current',
//                 PortfolioAnalysisService.formatCurrencyCompact(
//                   inv.currentValue,
//                 ),
//               ),
//               _buildInvStat(
//                 'Returns',
//                 PortfolioAnalysisService.formatCurrencyCompact(inv.returns),
//                 color: inv.isProfit ? AppTheme.primaryColor : Colors.redAccent,
//               ),
//               _buildInvStat('Units', inv.units.toStringAsFixed(0)),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildInvStat(
//     String label,
//     String value, {
//     Color color = Colors.white,
//   }) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             fontWeight: FontWeight.bold,
//             fontSize: 12,
//             color: color,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
//         ),
//       ],
//     );
//   }

//   Widget _buildAiCard(String title, String body, IconData icon, Color color) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 12),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(16),
//         color: color.withValues(alpha: 0.05),
//         border: Border.all(color: color.withValues(alpha: 0.2)),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(icon, color: color, size: 18),
//               const SizedBox(width: 8),
//               Text(
//                 title,
//                 style: TextStyle(fontWeight: FontWeight.bold, color: color),
//               ),
//             ],
//           ),
//           const SizedBox(height: 8),
//           Text(
//             body,
//             style: const TextStyle(
//               color: AppTheme.textSecondary,
//               fontSize: 12,
//               height: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildSuggestionCard(String s) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(
//           color: AppTheme.secondaryAccentColor.withValues(alpha: 0.2),
//         ),
//       ),
//       child: Text(
//         s,
//         style: const TextStyle(
//           color: AppTheme.textSecondary,
//           fontSize: 12,
//           height: 1.4,
//         ),
//       ),
//     );
//   }

//   Widget _buildAllocationItem(AllocationItem item) {
//     final color = Color(int.parse(item.color.replaceAll('#', '0xFF')));
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         children: [
//           Container(
//             width: 10,
//             height: 10,
//             decoration: BoxDecoration(color: color, shape: BoxShape.circle),
//           ),
//           const SizedBox(width: 10),
//           Text(item.category, style: const TextStyle(fontSize: 13)),
//           const Spacer(),
//           Text(
//             PortfolioAnalysisService.formatCurrencyCompact(item.amount),
//             style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
//           ),
//           const SizedBox(width: 12),
//           Text(
//             '${item.percentage.toStringAsFixed(1)}%',
//             style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildReturnRow(PortfolioInvestment inv) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 10),
//       child: Row(
//         children: [
//           Icon(_typeIcon(inv.type), color: _typeColor(inv.type), size: 16),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               inv.name,
//               style: const TextStyle(fontSize: 12),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//           Text(
//             PortfolioAnalysisService.formatCurrencyCompact(inv.returns),
//             style: TextStyle(
//               color: inv.isProfit ? AppTheme.primaryColor : Colors.redAccent,
//               fontSize: 12,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildReportCategory(String title, List<_ReportItem> items) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           title.toUpperCase(),
//           style: const TextStyle(
//             color: AppTheme.primaryColor,
//             fontWeight: FontWeight.bold,
//             fontSize: 10,
//             letterSpacing: 1.0,
//           ),
//         ),
//         const SizedBox(height: 8),
//         Container(
//           decoration: AppTheme.glassDecoration,
//           child: Column(
//             children: items
//                 .map(
//                   (item) => ListTile(
//                     leading: Icon(
//                       item.icon,
//                       color: AppTheme.primaryColor,
//                       size: 20,
//                     ),
//                     title: Text(
//                       item.title,
//                       style: const TextStyle(
//                         fontSize: 13,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     subtitle: Text(
//                       item.subtitle,
//                       style: const TextStyle(
//                         fontSize: 11,
//                         color: AppTheme.textSecondary,
//                       ),
//                     ),
//                     trailing: const Icon(
//                       LucideIcons.download,
//                       size: 18,
//                       color: AppTheme.primaryColor,
//                     ),
//                     onTap: () {},
//                   ),
//                 )
//                 .toList(),
//           ),
//         ),
//       ],
//     );
//   }


//   // ═══════════════════════════ HELPER METHODS ═══════════════════════════

//   String _performanceLabel(double pct) {
//     if (pct >= 20) return 'Excellent (${pct.toStringAsFixed(1)}%)';
//     if (pct >= 10) return 'Good (${pct.toStringAsFixed(1)}%)';
//     if (pct >= 0) return 'Moderate (${pct.toStringAsFixed(1)}%)';
//     return 'Loss (${pct.toStringAsFixed(1)}%)';
//   }

//   Color _typeColor(String t) {
//     if (t == 'Mutual Fund') return AppTheme.primaryColor;
//     if (t == 'Stock' || t == 'Stocks') return AppTheme.secondaryAccentColor;
//     if (t == 'ETF') return Colors.blueAccent;
//     if (t == 'Gold') return const Color(0xFFF59E0B);
//     return Colors.purpleAccent;
//   }

//   IconData _typeIcon(String t) {
//     if (t == 'Mutual Fund') return LucideIcons.barChart2;
//     if (t == 'ETF') return LucideIcons.barChart;
//     if (t == 'Gold') return LucideIcons.coins;
//     return LucideIcons.trendingUp;
//   }
// }

// // ═══════════════════════════ DATA CLASS ═══════════════════════════

// class _ReportItem {
//   final String title, subtitle;
//   final IconData icon;
//   _ReportItem(this.title, this.subtitle, this.icon);
// }



// portfolio_reports_screen.dart
//
// Displays live portfolio data sourced from PortfolioService.
// Falls back to demo data when no holdings have been imported yet.
//
// Sections:
//   0  Overview     – key stats, CAGR, risk profile, top performers
//   1  Returns      – bar chart of return % per holding (fl_chart)
//   2  Holdings     – detailed card per investment
//   3  Allocation   – donut chart + breakdown list (fl_chart)
//   4  AI Insight   – strengths, weaknesses, suggestions

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../../core/services/portfolio_service.dart';
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

  // ── Scroll / tab ───────────────────────────────────────────────────────────
  final ScrollController _scrollController = ScrollController();
  int _activeTab = 0;
  final List<GlobalKey> _sectionKeys = List.generate(5, (_) => GlobalKey());
  static const List<String> _tabLabels = [
    'Overview', 'Returns', 'Holdings', 'Allocation', 'AI Insight ✨',
  ];

  // ── Portfolio data ─────────────────────────────────────────────────────────
  List<PortfolioInvestment> _investments = [];
  late PortfolioAnalysis _analysis;
  bool _usingDemoData = false;
  StreamSubscription<List<HoldingEntry>>? _holdingsSub;

  // ── AI insights ────────────────────────────────────────────────────────────
  AiInsightResult? _aiInsights;
  bool _aiLoading = false;

  // ── Chart touch state ──────────────────────────────────────────────────────
  int _touchedPieIndex = -1;

  // ── Animation ──────────────────────────────────────────────────────────────
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..forward();
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scrollController.addListener(_onScroll);

    // Subscribe to live portfolio data. The stream yields the current list
    // immediately, so we always get data on first frame.
    _holdingsSub = PortfolioService().portfolioStream().listen((entries) {
      if (!mounted) return;
      List<PortfolioInvestment> investments;
      bool demo = false;
      if (entries.isEmpty) {
        investments = PortfolioDocumentParser.getDemoPortfolio();
        demo = true;
      } else {
        investments = entries.map((e) => e.investment).toList();
      }
      setState(() {
        _investments = investments;
        _analysis = PortfolioAnalysisService.analyze(_investments);
        _usingDemoData = demo;
        // Reset AI insights when data changes
        _aiInsights = null;
      });
    });

    // Set initial state synchronously so build() doesn't use uninitialised data.
    _investments = PortfolioDocumentParser.getDemoPortfolio();
    _usingDemoData = true;
    _analysis = PortfolioAnalysisService.analyze(_investments);
  }

  @override
  void dispose() {
    _holdingsSub?.cancel();
    _scrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Scroll ────────────────────────────────────────────────────────────────

  void _onScroll() {
    const double threshold = 200.0;
    for (int i = _sectionKeys.length - 1; i >= 0; i--) {
      final ctx = _sectionKeys[i].currentContext;
      if (ctx == null) continue;
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null) continue;
      if (box.localToGlobal(Offset.zero).dy <= threshold) {
        if (_activeTab != i) setState(() => _activeTab = i);
        return;
      }
    }
    if (_activeTab != 0) setState(() => _activeTab = 0);
  }

  void _scrollToSection(int index) {
    setState(() => _activeTab = index);
    final ctx = _sectionKeys[index].currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
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

  // ── AI ────────────────────────────────────────────────────────────────────

  Future<void> _loadAiInsights() async {
    setState(() => _aiLoading = true);
    final result = await PortfolioAiInsightService.generateInsights(
      _investments,
      _analysis,
    );
    if (mounted) {
      setState(() {
        _aiInsights = result;
        _aiLoading = false;
      });
    }
  }

  // ═══════════════════════════════ BUILD ════════════════════════════════════

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
                if (_usingDemoData) _buildDemoBanner(),
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
        label: const Text(
          'Import',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // ── App bar ────────────────────────────────────────────────────────────────

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

  // ── Demo data banner ───────────────────────────────────────────────────────

  Widget _buildDemoBanner() {
    return GestureDetector(
      onTap: () => context.push('/portfolio-import'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.accentGold.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.accentGold.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.info, size: 16, color: AppTheme.accentGold),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Showing sample data. Tap "Import" to upload your real portfolio.',
                style: TextStyle(
                  color: AppTheme.accentGold,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(LucideIcons.arrowRight, size: 14, color: AppTheme.accentGold),
          ],
        ),
      ),
    );
  }

  // ── Portfolio header ───────────────────────────────────────────────────────

  Widget _buildPortfolioHeader() {
    final fmt = PortfolioAnalysisService.formatIndianCurrency;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Portfolio Value',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fmt(_analysis.currentValue),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // Risk profile badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _analysis.riskProfile,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _headerStat(
                'Returns',
                '${_analysis.isProfit ? '+' : ''}${fmt(_analysis.totalReturns)}',
                _analysis.isProfit ? Colors.white : Colors.redAccent,
              ),
              _headerDivider(),
              _headerStat(
                '% Return',
                '${_analysis.isProfit ? '+' : ''}${_analysis.returnPercentage.toStringAsFixed(1)}%',
                _analysis.isProfit ? Colors.white : Colors.redAccent,
              ),
              _headerDivider(),
              _headerStat(
                'CAGR',
                _analysis.cagr != null
                    ? '${_analysis.cagr!.toStringAsFixed(1)}%'
                    : 'N/A',
                Colors.white70,
              ),
              _headerDivider(),
              _headerStat(
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

  Widget _headerStat(String label, String value, Color valueColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerDivider() => Container(
        width: 1, height: 24,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white.withValues(alpha: 0.2),
      );

  // ── Tab bar ────────────────────────────────────────────────────────────────

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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _tabLabels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ── Section wrapper ────────────────────────────────────────────────────────

  Widget _buildSection(int index, Widget content) {
    return Container(
      key: _sectionKeys[index],
      margin: const EdgeInsets.only(bottom: 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(_tabLabels[index].replaceAll(' ✨', '')),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _sectionLabel(String title) {
    return Row(
      children: [
        Container(
          width: 3, height: 16,
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

  // ═══════════════════════════ SECTION CONTENT ══════════════════════════════

  // ── Overview ──────────────────────────────────────────────────────────────

  Widget _buildOverviewContent() {
    return Column(
      children: [
        // Stat cards row
        Row(
          children: [
            _statCard('Holdings', '${_analysis.totalHoldings}',
                LucideIcons.briefcase, AppTheme.primaryColor),
            const SizedBox(width: 12),
            _statCard('Classes', '${_analysis.allocation.length}',
                LucideIcons.layers, AppTheme.secondaryAccentColor),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _statCard(
              'Performance',
              _performanceLabel(_analysis.returnPercentage),
              LucideIcons.trendingUp,
              _analysis.isProfit ? AppTheme.primaryColor : Colors.redAccent,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _subLabel('Top Performers'),
        const SizedBox(height: 10),
        ..._analysis.topPerformers.map(_investmentCard),
      ],
    );
  }

  // ── Returns — Bar Chart ────────────────────────────────────────────────────

  Widget _buildReturnsContent() {
    // Limit to 8 holdings for readability; sort by return %
    final sorted = List<PortfolioInvestment>.from(_investments)
      ..sort((a, b) => b.returnPercentage.compareTo(a.returnPercentage));
    final display = sorted.take(8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _subLabel('Return % per Holding'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 20, 16, 12),
          decoration: AppTheme.glassDecoration,
          child: SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _maxReturnY(display),
                minY: _minReturnY(display),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBorderRadius: BorderRadius.circular(8),
                    getTooltipColor: (_) => const Color(0xFF1E2A3A),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final inv = display[group.x];
                      return BarTooltipItem(
                        '${inv.name}\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        children: [
                          TextSpan(
                            text:
                                '${inv.returnPercentage >= 0 ? '+' : ''}${inv.returnPercentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: inv.isProfit
                                  ? AppTheme.primaryColor
                                  : Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (value, _) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) {
                        final i = value.toInt();
                        if (i < 0 || i >= display.length) {
                          return const SizedBox.shrink();
                        }
                        final name = display[i].name;
                        final short = name.length > 8
                            ? '${name.substring(0, 7)}…'
                            : name;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            short,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.05),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(display.length, (i) {
                  final inv = display[i];
                  final color = inv.isProfit
                      ? AppTheme.primaryColor
                      : Colors.redAccent;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: inv.returnPercentage,
                        fromY: 0,
                        color: color.withValues(alpha: 0.85),
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: _maxReturnY(display),
                          fromY: _minReturnY(display),
                          color: Colors.white.withValues(alpha: 0.03),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Condensed table below chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration,
          child: Column(
            children: _investments.map(_returnRow).toList(),
          ),
        ),
      ],
    );
  }

  double _maxReturnY(List<PortfolioInvestment> list) {
    if (list.isEmpty) return 30;
    final max = list.map((i) => i.returnPercentage).reduce((a, b) => a > b ? a : b);
    return (max + 5).ceilToDouble();
  }

  double _minReturnY(List<PortfolioInvestment> list) {
    if (list.isEmpty) return 0;
    final min = list.map((i) => i.returnPercentage).reduce((a, b) => a < b ? a : b);
    return min < 0 ? (min - 5).floorToDouble() : 0;
  }

  // ── Holdings ──────────────────────────────────────────────────────────────

  Widget _buildHoldingsContent() {
    return Column(
      children: _investments.map(_detailedCard).toList(),
    );
  }

  // ── Allocation — Donut Chart ───────────────────────────────────────────────

  Widget _buildAllocationContent() {
    final allocation = _analysis.allocation;
    if (allocation.isEmpty) {
      return const Center(
        child: Text(
          'No allocation data',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Column(
      children: [
        _subLabel('Asset Class Distribution'),
        const SizedBox(height: 16),
        // Donut chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration,
          child: Column(
            children: [
              SizedBox(
                height: 220,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        pieTouchData: PieTouchData(
                          touchCallback: (event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedPieIndex = -1;
                                return;
                              }
                              _touchedPieIndex = pieTouchResponse
                                  .touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: _buildPieSections(allocation),
                        centerSpaceRadius: 60,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                      ),
                    ),
                    // Centre label
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_touchedPieIndex >= 0 &&
                            _touchedPieIndex < allocation.length) ...[
                          Text(
                            allocation[_touchedPieIndex].category,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            '${allocation[_touchedPieIndex].percentage.toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ] else ...[
                          const Text(
                            'Portfolio',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                          Text(
                            PortfolioAnalysisService.formatCurrencyCompact(
                              _analysis.currentValue,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Legend
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: allocation.map((item) {
                  final color =
                      Color(int.parse(item.color.replaceAll('#', '0xFF')));
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Detailed breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration,
          child: Column(
            children: allocation.map(_allocationRow).toList(),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(List<AllocationItem> allocation) {
    return List.generate(allocation.length, (i) {
      final item = allocation[i];
      final isTouched = i == _touchedPieIndex;
      final color = Color(int.parse(item.color.replaceAll('#', '0xFF')));
      return PieChartSectionData(
        value: item.percentage,
        color: color.withValues(alpha: isTouched ? 1.0 : 0.82),
        radius: isTouched ? 72 : 62,
        title: item.percentage >= 8
            ? '${item.percentage.toStringAsFixed(0)}%'
            : '',
        titleStyle: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgePositionPercentageOffset: 0.98,
      );
    });
  }

  // ── AI Insights ───────────────────────────────────────────────────────────

  Widget _buildAiInsightsContent() {
    // Always show rule-based strengths/weaknesses from the analysis engine.
    // The "Generate AI Insights" button loads richer text from the AI service.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Strengths
        _subLabel('Strengths'),
        const SizedBox(height: 10),
        ..._analysis.strengths.map(
          (s) => _insightCard(s, LucideIcons.shieldCheck, AppTheme.primaryColor),
        ),
        const SizedBox(height: 16),
        // Weaknesses
        _subLabel('Areas to Watch'),
        const SizedBox(height: 10),
        ..._analysis.weaknesses.map(
          (w) => _insightCard(w, LucideIcons.alertTriangle, Colors.orange),
        ),
        const SizedBox(height: 24),
        // AI deep-dive (on demand)
        if (_aiLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_aiInsights == null)
          _buildAiTrigger()
        else ...[
          _subLabel('AI Deep-Dive'),
          const SizedBox(height: 10),
          _aiCard('Performance', _aiInsights!.performanceSummary,
              LucideIcons.trendingUp, AppTheme.primaryColor),
          _aiCard('Risk', _aiInsights!.riskSummary,
              LucideIcons.shieldCheck, const Color(0xFF60A5FA)),
          _aiCard('Diversification', _aiInsights!.diversificationAnalysis,
              LucideIcons.pieChart, AppTheme.secondaryAccentColor),
          if (_aiInsights!.suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            _subLabel('Recommendations'),
            const SizedBox(height: 10),
            ..._aiInsights!.suggestions.map(_suggestionCard),
          ],
        ],
      ],
    );
  }

  Widget _buildAiTrigger() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: [
          const Icon(LucideIcons.sparkles, size: 36, color: AppTheme.primaryColor),
          const SizedBox(height: 12),
          const Text(
            'AI Portfolio Analysis',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap below to generate deeper AI-powered insights about your portfolio.',
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

  // ── Documents (non-anchored) ───────────────────────────────────────────────

  Widget _buildDocumentsBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Documents'),
        const SizedBox(height: 12),
        _reportCategory('Tax Statements', [
          _ReportItem('Capital Gains Report', 'FY 2023-24', LucideIcons.fileText),
          _ReportItem('Tax P&L Statement', 'FY 2023-24', LucideIcons.fileText),
        ]),
        const SizedBox(height: 16),
        _reportCategory('Performance Reports', [
          _ReportItem('Monthly Portfolio Review', 'Feb 2024', LucideIcons.pieChart),
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

  // ═══════════════════════════ SMALL WIDGETS ══════════════════════════════

  Widget _subLabel(String title) => Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: AppTheme.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 10,
          letterSpacing: 1.0,
        ),
      );

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _investmentCard(PortfolioInvestment inv) {
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
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            '${inv.isProfit ? '+' : ''}${inv.returnPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
                color: inv.isProfit ? AppTheme.primaryColor : Colors.redAccent,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _detailedCard(PortfolioInvestment inv) {
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
                child: Icon(_typeIcon(inv.type),
                    color: _typeColor(inv.type), size: 18),
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
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                    color:
                        inv.isProfit ? AppTheme.primaryColor : Colors.redAccent,
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
              _invStat('Invested',
                  PortfolioAnalysisService.formatCurrencyCompact(inv.amountInvested)),
              _invStat('Current',
                  PortfolioAnalysisService.formatCurrencyCompact(inv.currentValue)),
              _invStat('Returns',
                  PortfolioAnalysisService.formatCurrencyCompact(inv.returns),
                  color: inv.isProfit ? AppTheme.primaryColor : Colors.redAccent),
              _invStat('Units', inv.units.toStringAsFixed(0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _invStat(String label, String value, {Color color = Colors.white}) {
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

  Widget _allocationRow(AllocationItem item) {
    final color = Color(int.parse(item.color.replaceAll('#', '0xFF')));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10, height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(item.category,
                    style: const TextStyle(fontSize: 13)),
              ),
              Text(
                PortfolioAnalysisService.formatCurrencyCompact(item.amount),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 42,
                child: Text(
                  '${item.percentage.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: item.percentage / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation(color.withValues(alpha: 0.8)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _returnRow(PortfolioInvestment inv) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(_typeIcon(inv.type), color: _typeColor(inv.type), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(inv.name,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis),
          ),
          Text(
            PortfolioAnalysisService.formatCurrencyCompact(inv.returns),
            style: TextStyle(
              color: inv.isProfit ? AppTheme.primaryColor : Colors.redAccent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightCard(String text, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: color.withValues(alpha: 0.06),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: AppTheme.textSecondary, fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _aiCard(String title, String body, IconData icon, Color color) {
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
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  height: 1.5)),
        ],
      ),
    );
  }

  Widget _suggestionCard(String s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.secondaryAccentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Text(s,
          style: const TextStyle(
              color: AppTheme.textSecondary, fontSize: 12, height: 1.4)),
    );
  }

  Widget _reportCategory(String title, List<_ReportItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 10,
            letterSpacing: 1.0,
          ),
        ),
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
                              fontSize: 13, fontWeight: FontWeight.bold)),
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

  // ═══════════════════════════ HELPERS ══════════════════════════════════════

  String _performanceLabel(double pct) {
    if (pct >= 20) return 'Excellent (${pct.toStringAsFixed(1)}%)';
    if (pct >= 10) return 'Good (${pct.toStringAsFixed(1)}%)';
    if (pct >= 0) return 'Moderate (${pct.toStringAsFixed(1)}%)';
    return 'Loss (${pct.toStringAsFixed(1)}%)';
  }

  Color _typeColor(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('mutual') || lower.contains('mf')) {
      return AppTheme.primaryColor;
    }
    if (lower.contains('stock')) return AppTheme.secondaryAccentColor;
    if (lower.contains('etf')) return Colors.blueAccent;
    if (lower.contains('gold')) return const Color(0xFFF59E0B);
    if (lower.contains('fd') || lower.contains('fixed')) {
      return const Color(0xFF34D399);
    }
    if (lower.contains('insurance')) return const Color(0xFFA78BFA);
    return Colors.purpleAccent;
  }

  IconData _typeIcon(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('mutual') || lower.contains('mf')) {
      return LucideIcons.barChart2;
    }
    if (lower.contains('etf')) return LucideIcons.barChart;
    if (lower.contains('gold')) return LucideIcons.coins;
    if (lower.contains('fd') || lower.contains('fixed')) {
      return LucideIcons.landmark;
    }
    if (lower.contains('insurance')) return LucideIcons.shieldCheck;
    return LucideIcons.trendingUp;
  }
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _ReportItem {
  final String title, subtitle;
  final IconData icon;
  _ReportItem(this.title, this.subtitle, this.icon);
}
