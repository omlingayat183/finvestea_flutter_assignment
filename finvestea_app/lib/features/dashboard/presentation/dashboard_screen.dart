import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.mainGradient,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 32),
                _buildPortfolioCard(context),
                const SizedBox(height: 32),
                _buildSectionHeader(
                  context,
                  'Explore Opportunities',
                  onTap: () => context.push('/marketplace'),
                ),
                const SizedBox(height: 16),
                _buildInvestmentCategories(context),
                const SizedBox(height: 32),
                _buildSectionHeader(
                  context,
                  'Recent Insights',
                  onTap: () => context.push('/news-feed'),
                ),
                const SizedBox(height: 16),
                _buildInsightCard(
                  context,
                  'Market Update',
                  'NIFTY 50 touches all-time high as tech stocks soar.',
                  '2 mins ago',
                  onTap: () => context.push('/academy/article'),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundColorEnd,
          border: Border(
            top: BorderSide(color: Colors.white.withOpacity(0.05)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: AppTheme.textSecondary,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            switch (index) {
              case 0:
                context.go('/dashboard');
                break;
              case 1:
                context.push('/reports');
                break;
              case 2:
                context.push('/market-overview');
                break;
              case 3:
                context.push('/profile');
                break;
            }
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.pieChart),
              label: 'Portfolio',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.layoutGrid),
              label: 'Market',
            ),
            BottomNavigationBarItem(
              icon: Icon(LucideIcons.user),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, John!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Text(
              'Welcome back to Finvestea',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
        InkWell(
          onTap: () => context.push('/help'),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: AppTheme.glassDecoration,
            child: const Icon(
              LucideIcons.bell,
              size: 24,
              color: AppTheme.accentColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioCard(BuildContext context) {
    return InkWell(
      onTap: () => context.push('/reports'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor,
              AppTheme.primaryColor.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Total Portfolio Value',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '₹ 12,45,780.00',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  LucideIcons.trendingUp,
                  size: 18,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                const Text(
                  '+12.5% (₹ 1,38,400)',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: onTap,
          child: const Text(
            'See All',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentCategories(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCategoryItem(
              context,
              'Academy',
              LucideIcons.graduationCap,
              () => context.push('/academy'),
            ),
            _buildCategoryItem(
              context,
              'Market',
              LucideIcons.trendingUp,
              () => context.push('/market-overview'),
            ),
            _buildCategoryItem(
              context,
              'Calculators',
              LucideIcons.calculator,
              () => context.push('/calculators'),
            ),
            _buildCategoryItem(
              context,
              'Goals',
              LucideIcons.target,
              () => context.push('/goals'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildCategoryItem(
              context,
              'Invest',
              LucideIcons.layers,
              () => context.push('/marketplace'),
            ),
            _buildCategoryItem(
              context,
              'Loans',
              LucideIcons.landmark,
              () => context.push('/loans'),
            ),
            _buildCategoryItem(
              context,
              'Reports',
              LucideIcons.pieChart,
              () => context.push('/reports'),
            ),
            _buildCategoryItem(
              context,
              'Services',
              LucideIcons.moreHorizontal,
              () => context.push('/services-hub'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    String name,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: AppTheme.glassDecoration,
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String tag,
    String title,
    String time, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: AppTheme.glassDecoration,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    LucideIcons.chevronRight,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
