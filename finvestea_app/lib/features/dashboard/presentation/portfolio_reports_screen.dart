import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme.dart';

class PortfolioReportsScreen extends StatelessWidget {
  const PortfolioReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.mainGradient,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              _buildPortfolioSummary(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    _buildReportCategory(context, 'Tax Statements', [
                      _ReportItem(
                        'Capital Gains Report',
                        'FY 2023-24',
                        LucideIcons.fileText,
                      ),
                      _ReportItem(
                        'Tax P&L Statement',
                        'FY 2023-24',
                        LucideIcons.fileText,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildReportCategory(context, 'Performance Reports', [
                      _ReportItem(
                        'Monthly Portfolio Review',
                        'Feb 2024',
                        LucideIcons.pieChart,
                      ),
                      _ReportItem(
                        'Annual Performance',
                        '2023',
                        LucideIcons.trendingUp,
                      ),
                      _ReportItem(
                        'Asset Allocation Summary',
                        'Current',
                        LucideIcons.layers,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildReportCategory(context, 'Transaction Reports', [
                      _ReportItem(
                        'Ledger Statement',
                        'Last 6 Months',
                        LucideIcons.list,
                      ),
                      _ReportItem('Contract Notes', 'Recent', LucideIcons.file),
                    ]),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/transactions'),
                      icon: const Icon(LucideIcons.clock, size: 18),
                      label: const Text('View Transaction History'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
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
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          const Text(
            'Portfolio Reports',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioSummary() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Portfolio Value',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  '₹ 12,45,780.00',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '+₹ 1,38,400 (12.5% all time)',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.trendingUp,
            color: Colors.white.withOpacity(0.8),
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCategory(
    BuildContext context,
    String title,
    List<_ReportItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: AppTheme.glassDecoration,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    title: Text(
                      item.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    trailing: const Icon(
                      LucideIcons.download,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Downloading ${item.title}...'),
                          duration: const Duration(seconds: 2),
                          backgroundColor: AppTheme.surfaceColor,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  if (index < items.length - 1)
                    const Divider(height: 1, indent: 64, color: Colors.white10),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _ReportItem {
  final String title;
  final String subtitle;
  final IconData icon;
  _ReportItem(this.title, this.subtitle, this.icon);
}
