// portfolio_ai_insight_service.dart
// Generates AI-powered portfolio insights (simulated Gamma API integration).
// In production, replace the _callGammaApi method body with a real HTTP call.

import 'portfolio_analysis_service.dart';
import 'portfolio_document_parser.dart';

class AiInsightResult {
  final String performanceSummary;
  final String riskSummary;
  final String diversificationAnalysis;
  final List<String> suggestions;
  final bool isLoading;
  final String? error;

  const AiInsightResult({
    required this.performanceSummary,
    required this.riskSummary,
    required this.diversificationAnalysis,
    required this.suggestions,
    this.isLoading = false,
    this.error,
  });

  factory AiInsightResult.loading() => const AiInsightResult(
        performanceSummary: '',
        riskSummary: '',
        diversificationAnalysis: '',
        suggestions: [],
        isLoading: true,
      );

  factory AiInsightResult.error(String message) => AiInsightResult(
        performanceSummary: '',
        riskSummary: '',
        diversificationAnalysis: '',
        suggestions: [],
        error: message,
      );
}

class PortfolioAiInsightService {
  /// Generates portfolio insights. In production, replace with a real Gamma API call.
  static Future<AiInsightResult> generateInsights(
    List<PortfolioInvestment> investments,
    PortfolioAnalysis analysis,
  ) async {
    // Simulate network latency for backend/Gamma API call
    await Future.delayed(const Duration(seconds: 2));

    try {
      return _buildInsights(investments, analysis);
    } catch (e) {
      return AiInsightResult.error(
        'Unable to fetch AI insights. Please try again later.',
      );
    }
  }

  /// Builds rule-based insights simulating Gamma AI output.
  /// TODO: Replace this with actual Gamma API POST request in production:
  /// ```
  /// final response = await http.post(
  ///   Uri.parse('https://api.gamma.app/v1/portfolio/analyze'),
  ///   headers: {'Authorization': 'Bearer $gammaApiKey', 'Content-Type': 'application/json'},
  ///   body: jsonEncode({'portfolio': investments.map((i) => i.toJson()).toList()}),
  /// );
  /// ```
  static AiInsightResult _buildInsights(
    List<PortfolioInvestment> investments,
    PortfolioAnalysis analysis,
  ) {
    // Performance Summary
    final String perfSummary = _buildPerformanceSummary(analysis);

    // Risk Summary
    final String riskSummary = _buildRiskSummary(analysis);

    // Diversification Analysis
    final String diversification = _buildDiversificationAnalysis(analysis);

    // Suggestions
    final List<String> suggestions = _buildSuggestions(investments, analysis);

    return AiInsightResult(
      performanceSummary: perfSummary,
      riskSummary: riskSummary,
      diversificationAnalysis: diversification,
      suggestions: suggestions,
    );
  }

  static String _buildPerformanceSummary(PortfolioAnalysis analysis) {
    final retPct = analysis.returnPercentage.toStringAsFixed(1);
    final retStr = PortfolioAnalysisService.formatCurrencyCompact(
      analysis.totalReturns,
    );
    final valStr = PortfolioAnalysisService.formatCurrencyCompact(
      analysis.currentValue,
    );

    if (analysis.returnPercentage >= 20) {
      return 'Excellent performance! Your portfolio has delivered $retPct% returns ($retStr), significantly outperforming the Nifty 50 benchmark. Your current portfolio value stands at $valStr. Large-cap and equity allocations have been the primary growth drivers.';
    } else if (analysis.returnPercentage >= 10) {
      return 'Your portfolio is performing well with $retPct% overall returns ($retStr). The current value of $valStr reflects steady growth. Equity mutual funds are contributing positively to your portfolio health.';
    } else if (analysis.returnPercentage >= 0) {
      return 'Your portfolio shows modest positive returns of $retPct% ($retStr). With current value at $valStr, consider reviewing underperforming assets to optimize growth potential.';
    } else {
      return 'Your portfolio is currently at a loss of $retPct% ($retStr). This may be a temporary market condition. Review your asset allocation and consider rebalancing with defensive assets like bonds or gold.';
    }
  }

  static String _buildRiskSummary(PortfolioAnalysis analysis) {
    final equityAlloc = analysis.allocation.where((a) {
      return a.category == 'Stocks' ||
          a.category == 'ETF' ||
          a.category == 'Mutual Fund';
    }).fold(0.0, (sum, a) => sum + a.percentage);

    if (equityAlloc > 80) {
      return 'High Risk Profile: Your portfolio is ${ equityAlloc.toStringAsFixed(0)}% equity-heavy. While this maximizes growth potential, it also exposes you to significant market volatility. Suitable for investors with a long-term horizon (7+ years) and high risk tolerance.';
    } else if (equityAlloc > 60) {
      return 'Moderate-High Risk: With ${equityAlloc.toStringAsFixed(0)}% in equity instruments, your portfolio is growth-oriented. Recommended for investors with a 5–7 year horizon. Consider adding 10–15% debt allocation for stability.';
    } else if (equityAlloc > 40) {
      return 'Balanced Risk Profile: Your portfolio maintains a healthy balance of ${equityAlloc.toStringAsFixed(0)}% equity and ${(100 - equityAlloc).toStringAsFixed(0)}% non-equity assets. This reduces volatility while preserving growth potential.';
    } else {
      return 'Conservative Risk Profile: ${equityAlloc.toStringAsFixed(0)}% equity exposure indicates a capital-preservation focus. Suitable for near-term goals, but consider increasing equity allocation for long-term wealth creation.';
    }
  }

  static String _buildDiversificationAnalysis(PortfolioAnalysis analysis) {
    final catCount = analysis.allocation.length;
    final topAlloc = analysis.allocation.isNotEmpty
        ? analysis.allocation.first.percentage
        : 0;

    if (catCount >= 4 && topAlloc < 50) {
      return 'Well Diversified: Your portfolio spans $catCount asset classes with no single category exceeding 50%. This reduces concentration risk and provides exposure to multiple market segments — an excellent foundation for long-term wealth creation.';
    } else if (catCount >= 3) {
      return 'Moderately Diversified: Your investments cover $catCount categories. The dominant allocation (${topAlloc.toStringAsFixed(0)}%) creates some concentration risk. Adding exposure to bonds, international ETFs, or gold could further balance your portfolio.';
    } else {
      return 'Low Diversification: Your portfolio is concentrated in ${catCount <= 1 ? 'a single' : 'very few'} asset class(es). Diversifying across Mutual Funds, ETFs, Gold, and Bonds can significantly reduce portfolio risk and improve risk-adjusted returns.';
    }
  }

  static List<String> _buildSuggestions(
    List<PortfolioInvestment> investments,
    PortfolioAnalysis analysis,
  ) {
    final List<String> suggestions = [];

    final hasGold =
        analysis.allocation.any((a) => a.category == 'Gold');
    final hasBonds =
        analysis.allocation.any((a) => a.category == 'Bonds' || a.category == 'FD');
    final equityPct = analysis.allocation
        .where((a) =>
            a.category == 'Stocks' ||
            a.category == 'ETF' ||
            a.category == 'Mutual Fund')
        .fold(0.0, (s, a) => s + a.percentage);

    if (!hasGold) {
      suggestions.add(
        '🥇 Consider allocating 5–10% to Sovereign Gold Bonds (SGBs) or Gold ETFs as a hedge against inflation and market volatility.',
      );
    }

    if (!hasBonds && equityPct > 70) {
      suggestions.add(
        '📊 Your heavy equity exposure (${equityPct.toStringAsFixed(0)}%) could benefit from 10–15% in debt instruments like Government Bonds or Corporate FDs for stability.',
      );
    }

    if (analysis.returnPercentage < 10 && equityPct > 60) {
      suggestions.add(
        '🔄 Review underperforming equity holdings. Consider switching to index funds (Nifty 50 ETF) which have historically delivered 12–15% CAGR with lower costs.',
      );
    }

    suggestions.add(
      '📈 Set up SIPs (Systematic Investment Plans) to invest consistently and benefit from rupee cost averaging during market dips.',
    );

    if (analysis.totalHoldings < 5) {
      suggestions.add(
        '🌐 Your portfolio has fewer than 5 holdings. Diversifying into 8–12 instruments across asset classes reduces unsystematic risk significantly.',
      );
    }

    suggestions.add(
      '🎯 Review and rebalance your portfolio annually to maintain your target asset allocation as market conditions evolve.',
    );

    return suggestions;
  }
}
