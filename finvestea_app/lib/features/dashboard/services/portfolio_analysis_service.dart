// // portfolio_analysis_service.dart
// // Computes portfolio analytics from a list of PortfolioInvestment objects.

// import 'portfolio_document_parser.dart';

// class AllocationItem {
//   final String category;
//   final double amount;
//   final double percentage;
//   final String color; // hex string for UI

//   AllocationItem({
//     required this.category,
//     required this.amount,
//     required this.percentage,
//     required this.color,
//   });
// }

// class PortfolioAnalysis {
//   final double totalInvested;
//   final double currentValue;
//   final double totalReturns;
//   final double returnPercentage;
//   final List<AllocationItem> allocation;
//   final List<PortfolioInvestment> topPerformers;
//   final List<PortfolioInvestment> underPerformers;
//   final int totalHoldings;

//   PortfolioAnalysis({
//     required this.totalInvested,
//     required this.currentValue,
//     required this.totalReturns,
//     required this.returnPercentage,
//     required this.allocation,
//     required this.topPerformers,
//     required this.underPerformers,
//     required this.totalHoldings,
//   });

//   bool get isProfit => totalReturns >= 0;
// }

// class PortfolioAnalysisService {
//   /// Category colors map (used for charts)
//   static const Map<String, String> _categoryColors = {
//     'Mutual Fund': '#3FA9FF',
//     'Stock': '#4C8DFF',
//     'Stocks': '#4C8DFF',
//     'Gold': '#7BD3FF',
//     'ETF': '#9BD9FF',
//     'Bonds': '#3FA9FF',
//     'FD': '#4C8DFF',
//     'Other': '#A7B8D9',
//   };

//   static String _colorForCategory(String category) {
//     return _categoryColors[category] ?? _categoryColors['Other']!;
//   }

//   /// Main analysis method
//   static PortfolioAnalysis analyze(List<PortfolioInvestment> investments) {
//     if (investments.isEmpty) {
//       return PortfolioAnalysis(
//         totalInvested: 0,
//         currentValue: 0,
//         totalReturns: 0,
//         returnPercentage: 0,
//         allocation: [],
//         topPerformers: [],
//         underPerformers: [],
//         totalHoldings: 0,
//       );
//     }

//     final double totalInvested = investments.fold(
//       0,
//       (sum, i) => sum + i.amountInvested,
//     );
//     final double currentValue = investments.fold(
//       0,
//       (sum, i) => sum + i.currentValue,
//     );
//     final double totalReturns = currentValue - totalInvested;
//     final double returnPct = totalInvested > 0
//         ? (totalReturns / totalInvested) * 100
//         : 0;

//     // Build allocation by type
//     final Map<String, double> categoryAmounts = {};
//     for (final inv in investments) {
//       categoryAmounts[inv.type] =
//           (categoryAmounts[inv.type] ?? 0) + inv.currentValue;
//     }

//     final List<AllocationItem> allocation = categoryAmounts.entries.map((e) {
//       return AllocationItem(
//         category: e.key,
//         amount: e.value,
//         percentage: currentValue > 0 ? (e.value / currentValue) * 100 : 0,
//         color: _colorForCategory(e.key),
//       );
//     }).toList()..sort((a, b) => b.amount.compareTo(a.amount));

//     // Top performers (sorted by returnPercentage descending)
//     final sorted = List<PortfolioInvestment>.from(investments)
//       ..sort((a, b) => b.returnPercentage.compareTo(a.returnPercentage));

//     final topPerformers = sorted.where((i) => i.isProfit).take(3).toList();
//     final underPerformers = sorted.reversed
//         .where((i) => !i.isProfit)
//         .take(3)
//         .toList();

//     return PortfolioAnalysis(
//       totalInvested: totalInvested,
//       currentValue: currentValue,
//       totalReturns: totalReturns,
//       returnPercentage: returnPct,
//       allocation: allocation,
//       topPerformers: topPerformers,
//       underPerformers: underPerformers.isEmpty
//           ? sorted.reversed.take(2).toList()
//           : underPerformers,
//       totalHoldings: investments.length,
//     );
//   }

//   /// Formats amount in Indian number system (3,2,2 grouping)
//   static String formatIndianCurrency(double amount, {bool showPaise = false}) {
//     final bool isNegative = amount < 0;
//     final double absAmount = amount.abs();

//     String amountStr = absAmount.toStringAsFixed(showPaise ? 2 : 0);
//     List<String> parts = amountStr.split('.');
//     String whole = parts[0];

//     if (whole.length <= 3) {
//       amountStr = whole;
//     } else {
//       String lastThree = whole.substring(whole.length - 3);
//       String other = whole.substring(0, whole.length - 3);
//       String groupedOther = '';
//       int count = 0;
//       for (int i = other.length - 1; i >= 0; i--) {
//         groupedOther = other[i] + groupedOther;
//         count++;
//         if (count == 2 && i > 0) {
//           groupedOther = ',$groupedOther';
//           count = 0;
//         }
//       }
//       amountStr = '$groupedOther,$lastThree';
//     }

//     if (showPaise && parts.length > 1) {
//       amountStr += '.${parts[1]}';
//     }

//     return isNegative ? '-₹$amountStr' : '₹$amountStr';
//   }

//   /// Returns a compact currency string (e.g., 1.2L, 5.4Cr)
//   static String formatCurrencyCompact(double amount) {
//     final bool isNeg = amount < 0;
//     final double abs = amount.abs();
//     String val;
//     if (abs >= 10000000) {
//       val = '${(abs / 10000000).toStringAsFixed(2)}Cr';
//     } else if (abs >= 100000) {
//       val = '${(abs / 100000).toStringAsFixed(2)}L';
//     } else if (abs >= 1000) {
//       val = '${(abs / 1000).toStringAsFixed(1)}K';
//     } else {
//       val = abs.toStringAsFixed(0);
//     }
//     return '${isNeg ? '-' : ''}₹$val';
//   }
// }



// portfolio_analysis_service.dart
// Computes portfolio analytics from a list of PortfolioInvestment objects.

import 'dart:math' as math;
import 'portfolio_document_parser.dart';

// ─── AllocationItem ───────────────────────────────────────────────────────────

class AllocationItem {
  final String category;
  final double amount;
  final double percentage;
  final String color; // hex string e.g. '#3FA9FF'

  AllocationItem({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

// ─── PortfolioAnalysis ────────────────────────────────────────────────────────

class PortfolioAnalysis {
  final double totalInvested;
  final double currentValue;
  final double totalReturns;
  final double returnPercentage;
  final double? cagr;          // null when date range < 6 months
  final String riskProfile;
  final List<AllocationItem> allocation;
  final List<PortfolioInvestment> topPerformers;
  final List<PortfolioInvestment> underPerformers;
  final int totalHoldings;
  final List<String> strengths;
  final List<String> weaknesses;

  PortfolioAnalysis({
    required this.totalInvested,
    required this.currentValue,
    required this.totalReturns,
    required this.returnPercentage,
    this.cagr,
    required this.riskProfile,
    required this.allocation,
    required this.topPerformers,
    required this.underPerformers,
    required this.totalHoldings,
    required this.strengths,
    required this.weaknesses,
  });

  bool get isProfit => totalReturns >= 0;
}

// ─── PortfolioAnalysisService ────────────────────────────────────────────────

class PortfolioAnalysisService {

  // ── Category colours ────────────────────────────────────────────────────────
  static const Map<String, String> _categoryColors = {
    'Mutual Fund':  '#3FA9FF',
    'MF Equity':    '#3FA9FF',
    'MF Debt':      '#7BD3FF',
    'Stock':        '#4C8DFF',
    'Stocks':       '#4C8DFF',
    'Gold':         '#F59E0B',
    'ETF':          '#9BD9FF',
    'Bonds':        '#60A5FA',
    'FD':           '#34D399',
    'Insurance':    '#A78BFA',
    'ELSS':         '#FB923C',
    'Other':        '#A7B8D9',
  };

  // Asset types that count as "equity" for risk-profile calculation
  static const List<String> _equityTypes = [
    'stock', 'mutual fund', 'mf equity', 'etf', 'elss',
  ];

  static String _colorForCategory(String cat) {
    if (_categoryColors.containsKey(cat)) return _categoryColors[cat]!;
    final lower = cat.toLowerCase();
    for (final entry in _categoryColors.entries) {
      if (lower.contains(entry.key.toLowerCase())) return entry.value;
    }
    return _categoryColors['Other']!;
  }

  // ── Main entry point ────────────────────────────────────────────────────────

  static PortfolioAnalysis analyze(List<PortfolioInvestment> investments) {
    if (investments.isEmpty) {
      return PortfolioAnalysis(
        totalInvested: 0, currentValue: 0,
        totalReturns: 0, returnPercentage: 0,
        cagr: null, riskProfile: 'Unknown',
        allocation: [], topPerformers: [], underPerformers: [],
        totalHoldings: 0, strengths: [], weaknesses: [],
      );
    }

    // ── Totals ──────────────────────────────────────────────────────────────
    final totalInvested = investments.fold<double>(0, (s, i) => s + i.amountInvested);
    final currentValue  = investments.fold<double>(0, (s, i) => s + i.currentValue);
    final totalReturns  = currentValue - totalInvested;
    final returnPct     = totalInvested > 0 ? (totalReturns / totalInvested) * 100 : 0.0;

    // ── CAGR ────────────────────────────────────────────────────────────────
    final earliest = investments
        .map((i) => i.dateOfInvestment)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final years = DateTime.now().difference(earliest).inDays / 365.25;
    double? cagr;
    if (years >= 0.5 && totalInvested > 0 && currentValue > 0) {
      cagr = (math.pow(currentValue / totalInvested, 1 / years) - 1) * 100;
    }

    // ── Asset allocation ────────────────────────────────────────────────────
    final Map<String, double> byType = {};
    for (final inv in investments) {
      byType[inv.type] = (byType[inv.type] ?? 0) + inv.currentValue;
    }
    final allocation = byType.entries.map((e) => AllocationItem(
      category: e.key,
      amount: e.value,
      percentage: currentValue > 0 ? (e.value / currentValue) * 100 : 0,
      color: _colorForCategory(e.key),
    )).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    // ── Risk profile ────────────────────────────────────────────────────────
    final equityValue = investments
        .where((i) => _equityTypes.any(
              (t) => i.type.toLowerCase().contains(t),
            ))
        .fold<double>(0, (s, i) => s + i.currentValue);
    final equityPct = currentValue > 0 ? (equityValue / currentValue) * 100 : 0.0;
    final riskProfile = _riskLabel(equityPct);

    // ── Performers ──────────────────────────────────────────────────────────
    final sorted = List<PortfolioInvestment>.from(investments)
      ..sort((a, b) => b.returnPercentage.compareTo(a.returnPercentage));
    final topPerformers    = sorted.where((i) => i.isProfit).take(3).toList();
    final underPerformers  = sorted.reversed.where((i) => !i.isProfit).take(3).toList();

    // ── Insights ────────────────────────────────────────────────────────────
    final strengths  = _strengths(investments, allocation, returnPct, cagr, equityPct);
    final weaknesses = _weaknesses(investments, allocation, returnPct,
        underPerformers.isEmpty ? sorted.reversed.take(2).toList() : underPerformers);

    return PortfolioAnalysis(
      totalInvested: totalInvested,
      currentValue: currentValue,
      totalReturns: totalReturns,
      returnPercentage: returnPct,
      cagr: cagr,
      riskProfile: riskProfile,
      allocation: allocation,
      topPerformers: topPerformers,
      underPerformers: underPerformers.isEmpty
          ? sorted.reversed.take(2).toList()
          : underPerformers,
      totalHoldings: investments.length,
      strengths: strengths,
      weaknesses: weaknesses,
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  static String _riskLabel(double equityPct) {
    if (equityPct >= 75) return 'Aggressive Growth';
    if (equityPct >= 55) return 'Moderately Aggressive';
    if (equityPct >= 35) return 'Moderate';
    if (equityPct >= 15) return 'Moderately Conservative';
    return 'Conservative';
  }

  static List<String> _strengths(
    List<PortfolioInvestment> investments,
    List<AllocationItem> allocation,
    double returnPct,
    double? cagr,
    double equityPct,
  ) {
    final list = <String>[];
    if (allocation.length >= 3) {
      list.add('Well-diversified across ${allocation.length} asset classes, '
          'helping to manage risk through market cycles.');
    }
    if (returnPct >= 15) {
      list.add('Strong overall return of ${returnPct.toStringAsFixed(1)}% — '
          'outpacing typical inflation and fixed-deposit rates.');
    } else if (returnPct >= 8) {
      list.add('Healthy return of ${returnPct.toStringAsFixed(1)}% — '
          'comfortably above most savings account rates.');
    }
    if (cagr != null && cagr >= 10) {
      list.add('Impressive CAGR of ${cagr.toStringAsFixed(1)}% — '
          'demonstrates the compounding power of long-term investing.');
    }
    if (equityPct >= 40 && equityPct <= 70) {
      list.add('Balanced equity allocation of ${equityPct.toStringAsFixed(0)}% '
          'offers growth potential while managing downside risk.');
    }
    if (investments.length >= 5) {
      list.add('${investments.length} holdings reduce concentration '
          'risk from any single investment or sector.');
    }
    if (list.isEmpty) {
      list.add('Portfolio is active and being tracked — a great first step '
          'toward disciplined investing.');
    }
    return list;
  }

  static List<String> _weaknesses(
    List<PortfolioInvestment> investments,
    List<AllocationItem> allocation,
    double returnPct,
    List<PortfolioInvestment> underPerformers,
  ) {
    final list = <String>[];
    if (underPerformers.isNotEmpty) {
      final names = underPerformers.map((i) => i.name).take(2).join(' & ');
      list.add('Underperforming holdings ($names) are dragging overall returns. '
          'Review their long-term thesis.');
    }
    if (allocation.length == 1) {
      list.add('Portfolio is concentrated in a single asset class. '
          'Diversifying across equity, debt and gold can reduce volatility.');
    }
    if (allocation.isNotEmpty && allocation.first.percentage > 65) {
      list.add('${allocation.first.category} represents '
          '${allocation.first.percentage.toStringAsFixed(0)}% of the portfolio — '
          'consider reducing concentration risk.');
    }
    if (returnPct < 0) {
      list.add('Portfolio is currently at a loss. '
          'Review individual holdings and consider rebalancing.');
    }
    if (list.isEmpty) {
      list.add('No critical weaknesses detected. Continue monitoring and '
          'rebalance periodically to stay aligned with your goals.');
    }
    return list;
  }

  // ── Currency formatters ──────────────────────────────────────────────────────

  /// Indian number system: 1,00,000 grouping
  static String formatIndianCurrency(double amount, {bool showPaise = false}) {
    final bool isNeg = amount < 0;
    final double abs = amount.abs();
    String amountStr = abs.toStringAsFixed(showPaise ? 2 : 0);
    final parts = amountStr.split('.');
    String whole = parts[0];
    if (whole.length > 3) {
      final lastThree = whole.substring(whole.length - 3);
      final other = whole.substring(0, whole.length - 3);
      var grouped = '';
      int count = 0;
      for (int i = other.length - 1; i >= 0; i--) {
        grouped = other[i] + grouped;
        count++;
        if (count == 2 && i > 0) { grouped = ',$grouped'; count = 0; }
      }
      amountStr = '$grouped,$lastThree';
    }
    if (showPaise && parts.length > 1) amountStr += '.${parts[1]}';
    return '${isNeg ? '-' : ''}₹$amountStr';
  }

  /// Compact: ₹1.2L, ₹5.4Cr, ₹12.5K
  static String formatCurrencyCompact(double amount) {
    final bool isNeg = amount < 0;
    final double abs = amount.abs();
    String val;
    if (abs >= 10000000)      val = '${(abs / 10000000).toStringAsFixed(2)}Cr';
    else if (abs >= 100000)   val = '${(abs / 100000).toStringAsFixed(2)}L';
    else if (abs >= 1000)     val = '${(abs / 1000).toStringAsFixed(1)}K';
    else                      val = abs.toStringAsFixed(0);
    return '${isNeg ? '-' : ''}₹$val';
  }
}
