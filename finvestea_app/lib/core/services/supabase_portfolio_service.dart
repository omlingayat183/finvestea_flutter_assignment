// supabase_portfolio_service.dart
//
// Local stub — no Supabase or network calls.
// API surface kept identical so portfolio_import_screen.dart compiles unchanged.

import 'package:flutter/foundation.dart';

class SupabasePortfolioService {
  SupabasePortfolioService._();
  static final SupabasePortfolioService instance =
      SupabasePortfolioService._();

  /// Stub: simulates a successful file upload locally.
  Future<String> uploadFile({
    required String fileName,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    debugPrint('[uploadFile] local stub — $fileName (${bytes.length} bytes)');
    return 'local://$fileName';
  }

  /// Stub: simulates a successful DB insert locally.
  Future<Map<String, dynamic>> insertToDatabase({
    required String fileName,
    required String fileUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('[insertToDatabase] local stub — $fileName');
    return {
      'id': 'local_${DateTime.now().millisecondsSinceEpoch}',
      'file_name': fileName,
      'file_url': fileUrl,
    };
  }

  /// Stub: runs uploadFile → insertToDatabase in sequence.
  Future<UploadResult> uploadPortfolio({
    required String fileName,
    required Uint8List bytes,
    required String fileExtension,
  }) async {
    final fileUrl = await uploadFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: _mimeType(fileExtension),
    );
    final record = await insertToDatabase(
      fileName: fileName,
      fileUrl: fileUrl,
    );
    return UploadResult(
      id: record['id'] as String,
      fileUrl: fileUrl,
      fileName: fileName,
    );
  }

  /// Stub: AI analysis — no-op.
  Future<void> triggerAiAnalysis(String fileUrl) async {
    await Future.delayed(const Duration(milliseconds: 200));
    debugPrint('[triggerAiAnalysis] local stub — $fileUrl');
  }

  static String _mimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'csv':
        return 'text/csv';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument'
            '.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      default:
        return 'application/octet-stream';
    }
  }
}

// ── Result model ──────────────────────────────────────────────────────────────

class UploadResult {
  final String id;
  final String fileUrl;
  final String fileName;

  const UploadResult({
    required this.id,
    required this.fileUrl,
    required this.fileName,
  });
}

// ── Exception ─────────────────────────────────────────────────────────────────

class PortfolioUploadException implements Exception {
  final String message;
  const PortfolioUploadException(this.message);

  @override
  String toString() => message;
}
