import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/dashboard/services/portfolio_document_parser.dart';

/// A [PortfolioInvestment] paired with its Firestore document ID,
/// so individual entries can be edited or deleted.
class PortfolioEntry {
  final String id;
  final PortfolioInvestment investment;
  final String notes;

  const PortfolioEntry({
    required this.id,
    required this.investment,
    this.notes = '',
  });
}

class PortfolioService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ─────────────────────────────────────────
  // Real-time stream
  // ─────────────────────────────────────────

  Stream<List<PortfolioEntry>> portfolioStream() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(_uid)
        .collection('portfolio')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final d = doc.data();
              return PortfolioEntry(
                id: doc.id,
                notes: d['notes'] ?? '',
                investment: PortfolioInvestment(
                  name: d['name'] ?? '',
                  type: d['type'] ?? 'Other',
                  amountInvested: (d['amountInvested'] ?? 0).toDouble(),
                  currentValue: (d['currentValue'] ?? 0).toDouble(),
                  units: (d['units'] ?? 0).toDouble(),
                  dateOfInvestment: d['dateOfInvestment'] != null
                      ? (d['dateOfInvestment'] as Timestamp).toDate()
                      : DateTime.now(),
                  returns: (d['returns'] ?? 0).toDouble(),
                ),
              );
            }).toList());
  }

  // ─────────────────────────────────────────
  // CRUD
  // ─────────────────────────────────────────

  Future<void> addItem(PortfolioInvestment item, {String notes = ''}) async {
    if (_uid == null) return;
    await _db.collection('users').doc(_uid).collection('portfolio').add({
      'name': item.name,
      'type': item.type,
      'amountInvested': item.amountInvested,
      'currentValue': item.currentValue,
      'units': item.units,
      'dateOfInvestment': Timestamp.fromDate(item.dateOfInvestment),
      'returns': item.currentValue - item.amountInvested,
      'notes': notes,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateItem(String docId, PortfolioInvestment item,
      {String notes = ''}) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('portfolio')
        .doc(docId)
        .update({
      'name': item.name,
      'type': item.type,
      'amountInvested': item.amountInvested,
      'currentValue': item.currentValue,
      'units': item.units,
      'dateOfInvestment': Timestamp.fromDate(item.dateOfInvestment),
      'returns': item.currentValue - item.amountInvested,
      'notes': notes,
    });
  }

  Future<void> deleteItem(String docId) async {
    if (_uid == null) return;
    await _db
        .collection('users')
        .doc(_uid)
        .collection('portfolio')
        .doc(docId)
        .delete();
  }

  /// Saves a batch of investments (from file upload) in a single Firestore batch.
  Future<int> addBulk(List<PortfolioInvestment> items) async {
    if (_uid == null || items.isEmpty) return 0;
    final batch = _db.batch();
    int count = 0;
    for (final item in items) {
      final ref = _db
          .collection('users')
          .doc(_uid)
          .collection('portfolio')
          .doc();
      batch.set(ref, {
        'name': item.name,
        'type': item.type,
        'amountInvested': item.amountInvested,
        'currentValue': item.currentValue,
        'units': item.units,
        'dateOfInvestment': Timestamp.fromDate(item.dateOfInvestment),
        'returns': item.currentValue - item.amountInvested,
        'notes': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
      count++;
    }
    await batch.commit();
    return count;
  }

  // ─────────────────────────────────────────
  // Metrics (client-side, from stream data)
  // ─────────────────────────────────────────

  static PortfolioMetrics calculateMetrics(List<PortfolioEntry> entries) {
    if (entries.isEmpty) {
      return const PortfolioMetrics(
        totalInvestment: 0,
        currentValue: 0,
        totalReturns: 0,
        returnPercentage: 0,
      );
    }
    final totalInvestment = entries.fold<double>(
        0, (s, e) => s + e.investment.amountInvested);
    final currentValue = entries.fold<double>(
        0, (s, e) => s + e.investment.currentValue);
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
