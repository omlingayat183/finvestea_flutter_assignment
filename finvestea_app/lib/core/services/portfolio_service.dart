import 'dart:async';
import '../../features/dashboard/services/portfolio_document_parser.dart';

// ─── Holding ──────────────────────────────────────────────────────────────────

class Holding {
  final String name;
  final double quantity;
  final double costBasis;
  final double currentValue;
  final DateTime purchaseDate;
  final String assetType;
  final DateTime createdAt;
  final String portfolioId;
  final String? tickerSymbol;
  final String? notes;

  const Holding({
    required this.name,
    required this.quantity,
    required this.costBasis,
    required this.currentValue,
    required this.purchaseDate,
    required this.assetType,
    required this.createdAt,
    required this.portfolioId,
    this.tickerSymbol,
    this.notes,
  });

  double get returns => currentValue - costBasis;
  double get returnPercentage =>
      costBasis > 0 ? (returns / costBasis) * 100 : 0;
  bool get isProfit => returns >= 0;

  Map<String, dynamic> toMap() => {
        'name': name,
        'quantity': quantity,
        'costBasis': costBasis,
        'currentValue': currentValue,
        'purchaseDate': purchaseDate.toIso8601String(),
        'assetType': assetType,
        'createdAt': createdAt.toIso8601String(),
        'portfolioId': portfolioId,
        'tickerSymbol': tickerSymbol ?? '',
        'notes': notes ?? '',
      };

  factory Holding.fromMap(Map<String, dynamic> d) => Holding(
        name: d['name'] ?? '',
        quantity: (d['quantity'] ?? 0).toDouble(),
        costBasis: (d['costBasis'] ?? 0).toDouble(),
        currentValue: (d['currentValue'] ?? 0).toDouble(),
        purchaseDate: d['purchaseDate'] != null
            ? DateTime.tryParse(d['purchaseDate']) ?? DateTime.now()
            : DateTime.now(),
        assetType: d['assetType'] ?? 'Other',
        createdAt: d['createdAt'] != null
            ? DateTime.tryParse(d['createdAt']) ?? DateTime.now()
            : DateTime.now(),
        portfolioId: d['portfolioId'] ?? '',
        tickerSymbol: d['tickerSymbol']?.toString().isEmpty == true
            ? null
            : d['tickerSymbol'],
        notes: d['notes']?.toString().isEmpty == true ? null : d['notes'],
      );
}

// ─── HoldingEntry ─────────────────────────────────────────────────────────────

class HoldingEntry {
  final String id;
  final Holding holding;

  const HoldingEntry({required this.id, required this.holding});

  String get notes => holding.notes ?? '';

  PortfolioInvestment get investment => PortfolioInvestment(
        name: holding.name,
        type: holding.assetType,
        amountInvested: holding.costBasis,
        currentValue: holding.currentValue,
        dateOfInvestment: holding.purchaseDate,
        units: holding.quantity,
        returns: holding.returns,
      );
}

// Backward-compat alias
typedef PortfolioEntry = HoldingEntry;

// ─── Portfolio ────────────────────────────────────────────────────────────────

class Portfolio {
  final String id;
  final String name;
  final String currency;
  final DateTime createdAt;
  final String? description;

  const Portfolio({
    required this.id,
    required this.name,
    required this.currency,
    required this.createdAt,
    this.description,
  });
}

// ─── PortfolioMetrics ─────────────────────────────────────────────────────────

class PortfolioMetrics {
  final double totalInvestment;
  final double currentValue;
  final double totalReturns;
  final double returnPercentage;

  const PortfolioMetrics({
    required this.totalInvestment,
    required this.currentValue,
    required this.totalReturns,
    required this.returnPercentage,
  });

  bool get isProfit => totalReturns >= 0;
  bool get isEmpty => totalInvestment == 0 && currentValue == 0;
}

// ─── PortfolioService ─────────────────────────────────────────────────────────
// Fully in-memory. All data lives in the app session only.

class PortfolioService {
  static final PortfolioService _instance = PortfolioService._internal();
  factory PortfolioService() => _instance;
  PortfolioService._internal();

  final List<HoldingEntry> _holdings = [];
  int _idCounter = 0;
  final StreamController<List<HoldingEntry>> _holdingsController =
      StreamController<List<HoldingEntry>>.broadcast();

  void _emit() =>
      _holdingsController.add(List.unmodifiable(_holdings));

  String _nextId() => 'holding_${++_idCounter}';

  // ── Portfolio operations ────────────────────────────────────────────────────

  Stream<List<Portfolio>> portfoliosStream() => Stream.value([
        Portfolio(
          id: 'default_portfolio',
          name: 'My Portfolio',
          currency: 'INR',
          createdAt: DateTime(2024),
        ),
      ]);

  Future<String> createPortfolio(
    String name, {
    String currency = 'INR',
    String? description,
  }) async {
    return 'default_portfolio';
  }

  Future<String> getOrCreateDefaultPortfolioId() async {
    return 'default_portfolio';
  }

  // ── Holding operations ──────────────────────────────────────────────────────

  /// Stream all holdings — emits current list immediately then on every change.
  Stream<List<HoldingEntry>> portfolioStream() async* {
    yield List.unmodifiable(_holdings);
    await for (final list in _holdingsController.stream) {
      yield list;
    }
  }

  /// Stream holdings for a specific portfolio.
  Stream<List<HoldingEntry>> holdingsStream(String portfolioId) async* {
    yield _holdings
        .where((e) => e.holding.portfolioId == portfolioId)
        .toList();
    await for (final list in _holdingsController.stream) {
      yield list
          .where((e) => e.holding.portfolioId == portfolioId)
          .toList();
    }
  }

  Future<void> addItem(
    PortfolioInvestment item, {
    String notes = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final holding = Holding(
      name: item.name,
      quantity: item.units,
      costBasis: item.amountInvested,
      currentValue: item.currentValue,
      purchaseDate: item.dateOfInvestment,
      assetType: item.type,
      createdAt: DateTime.now(),
      portfolioId: 'default_portfolio',
      notes: notes.isEmpty ? null : notes,
    );
    _holdings.add(HoldingEntry(id: _nextId(), holding: holding));
    _emit();
  }

  Future<void> updateItem(
    String docId,
    PortfolioInvestment item, {
    String notes = '',
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _holdings.indexWhere((e) => e.id == docId);
    if (index == -1) return;
    final old = _holdings[index].holding;
    final updated = Holding(
      name: item.name,
      quantity: item.units,
      costBasis: item.amountInvested,
      currentValue: item.currentValue,
      purchaseDate: item.dateOfInvestment,
      assetType: item.type,
      createdAt: old.createdAt,
      portfolioId: old.portfolioId,
      notes: notes.isEmpty ? null : notes,
    );
    _holdings[index] = HoldingEntry(id: docId, holding: updated);
    _emit();
  }

  Future<void> deleteItem(String docId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _holdings.removeWhere((e) => e.id == docId);
    _emit();
  }

  /// Bulk-saves a list of PortfolioInvestment (from file import).
  Future<int> addBulk(List<PortfolioInvestment> items) async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (final item in items) {
      final holding = Holding(
        name: item.name,
        quantity: item.units,
        costBasis: item.amountInvested,
        currentValue: item.currentValue,
        purchaseDate: item.dateOfInvestment,
        assetType: item.type,
        createdAt: DateTime.now(),
        portfolioId: 'default_portfolio',
      );
      _holdings.add(HoldingEntry(id: _nextId(), holding: holding));
    }
    _emit();
    return items.length;
  }

  /// No-op upload tracking (kept for API compatibility).
  Future<void> recordUpload({
    required String filename,
    required String fileType,
    required String status,
    String? processingLog,
  }) async {
    // Local mode: nothing to record externally
  }

  // ── Metrics ─────────────────────────────────────────────────────────────────

  static PortfolioMetrics calculateMetrics(List<HoldingEntry> entries) {
    if (entries.isEmpty) {
      return const PortfolioMetrics(
        totalInvestment: 0,
        currentValue: 0,
        totalReturns: 0,
        returnPercentage: 0,
      );
    }
    final totalInvestment =
        entries.fold<double>(0, (s, e) => s + e.holding.costBasis);
    final currentValue =
        entries.fold<double>(0, (s, e) => s + e.holding.currentValue);
    final totalReturns = currentValue - totalInvestment;
    final returnPercentage =
        totalInvestment > 0 ? (totalReturns / totalInvestment) * 100 : 0.0;
    return PortfolioMetrics(
      totalInvestment: totalInvestment,
      currentValue: currentValue,
      totalReturns: totalReturns,
      returnPercentage: returnPercentage,
    );
  }
}
