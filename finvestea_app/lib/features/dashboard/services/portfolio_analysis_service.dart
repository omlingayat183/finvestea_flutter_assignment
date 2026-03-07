// portfolio_analysis_service.dart
// Computes portfolio analytics from a list of PortfolioInvestment objects.

import 'portfolio_document_parser.dart';

class AllocationItem {
  final String category;
  final double amount;
  final double percentage;
  final String color; // hex string for UI

  AllocationItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class PortfolioAnalysis {
  final double totalInvested;
  final double currentValue;
  final double totalReturns;
  final double returnPercentage;
  final List<AllocationItem> allocation;
  final List<PortfolioInvestment> topPerformers;
  final List<PortfolioInvestment> underPerformers;
  final int totalHoldings;

  PortfolioAnalysis({
    required this.totalInvested,
    required this.currentValue,
    required this.totalReturns,
    required this.returnPercentage,
    required this.allocation,
    required this.topPerformers,
    required this.underPerformers,
    required this.totalHoldings,
  });

  bool get isProfit => totalReturns >= 0;
}

class PortfolioAnalysisService {
  /// Category colors map (used for charts)
  static const Map<String, String> _categoryColors = {
    'Mutual Fund': '#22C55E',
    'Stock': '#D4AF37',
    'Stocks': '#D4AF37',
    'Gold': '#F59E0B',
    'ETF': '#60A5FA',
    'Bonds': '#A78BFA',
    'FD': '#FB7185',
    'Other': '#94A3B8',
  };

  static String _colorForCategory(String category) {
    return _categoryColors[category] ?? _categoryColors['Other']!;
  }

  /// Main analysis method
  static PortfolioAnalysis analyze(List<PortfolioInvestment> investments) {
    if (investments.isEmpty) {
      return PortfolioAnalysis(
        totalInvested: 0,
        currentValue: 0,
        totalReturns: 0,
        returnPercentage: 0,
        allocation: [],
        topPerformers: [],
        underPerformers: [],
        totalHoldings: 0,
      );
    }

    final double totalInvested =
        investments.fold(0, (sum, i) => sum + i.amountInvested);
    final double currentValue =
        investments.fold(0, (sum, i) => sum + i.currentValue);
    final double totalReturns = currentValue - totalInvested;
    final double returnPct =
        totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0;

    // Build allocation by type
    final Map<String, double> categoryAmounts = {};
    for (final inv in investments) {
      categoryAmounts[inv.type] =
          (categoryAmounts[inv.type] ?? 0) + inv.currentValue;
    }

    final List<AllocationItem> allocation = categoryAmounts.entries.map((e) {
      return AllocationItem(
        category: e.key,
        amount: e.value,
        percentage: currentValue > 0 ? (e.value / currentValue) * 100 : 0,
        color: _colorForCategory(e.key),
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // Top performers (sorted by returnPercentage descending)
    final sorted = List<PortfolioInvestment>.from(investments)
      ..sort((a, b) => b.returnPercentage.compareTo(a.returnPercentage));

    final topPerformers = sorted.where((i) => i.isProfit).take(3).toList();
    final underPerformers =
        sorted.reversed.where((i) => !i.isProfit).take(3).toList();

    return PortfolioAnalysis(
      totalInvested: totalInvested,
      currentValue: currentValue,
      totalReturns: totalReturns,
      returnPercentage: returnPct,
      allocation: allocation,
      topPerformers: topPerformers,
      underPerformers: underPerformers.isEmpty
          ? sorted.reversed.take(2).toList()
          : underPerformers,
      totalHoldings: investments.length,
    );
  }

  /// Formats amount in Indian number system (3,2,2 grouping)
  static String formatIndianCurrency(double amount, {bool showPaise = false}) {
    final bool isNegative = amount < 0;
    final double absAmount = amount.abs();

    String amountStr = absAmount.toStringAsFixed(showPaise ? 2 : 0);
    List<String> parts = amountStr.split('.');
    String whole = parts[0];

    if (whole.length <= 3) {
      amountStr = whole;
    } else {
      String lastThree = whole.substring(whole.length - 3);
      String other = whole.substring(0, whole.length - 3);
      String groupedOther = '';
      int count = 0;
      for (int i = other.length - 1; i >= 0; i--) {
        groupedOther = other[i] + groupedOther;
        count++;
        if (count == 2 && i > 0) {
          groupedOther = ',$groupedOther';
          count = 0;
        }
      }
      amountStr = '$groupedOther,$lastThree';
    }

    if (showPaise && parts.length > 1) {
      amountStr += '.${parts[1]}';
    }

    return isNegative ? '-₹$amountStr' : '₹$amountStr';
  }

  /// Returns a compact currency string (e.g., 1.2L, 5.4Cr)
  static String formatCurrencyCompact(double amount) {
    final bool isNeg = amount < 0;
    final double abs = amount.abs();
    String val;
    if (abs >= 10000000) {
      val = '${(abs / 10000000).toStringAsFixed(2)}Cr';
    } else if (abs >= 100000) {
      val = '${(abs / 100000).toStringAsFixed(2)}L';
    } else if (abs >= 1000) {
      val = '${(abs / 1000).toStringAsFixed(1)}K';
    } else {
      val = abs.toStringAsFixed(0);
    }
    return '${isNeg ? '-' : ''}₹$val';
  }
}
