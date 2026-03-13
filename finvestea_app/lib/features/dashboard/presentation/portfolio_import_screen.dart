import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as xl;
import '../../../core/theme.dart';
import '../../../core/services/portfolio_service.dart';
import '../services/portfolio_document_parser.dart';

class PortfolioImportScreen extends StatefulWidget {
  const PortfolioImportScreen({super.key});

  @override
  State<PortfolioImportScreen> createState() => _PortfolioImportScreenState();
}

class _PortfolioImportScreenState extends State<PortfolioImportScreen>
    with TickerProviderStateMixin {
  _ImportState _state = _ImportState.idle;
  String? _selectedFileName;
  double _uploadProgress = 0;
  String? _errorMessage;
  int _importedCount = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Timer? _progressTimer;

  final _service = PortfolioService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        withData: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not open file picker: $e';
          _state = _ImportState.error;
        });
      }
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileName = file.name;
    final bytes = file.bytes;

    if (bytes == null) {
      setState(() {
        _errorMessage = 'Could not read file data.';
        _state = _ImportState.error;
      });
      return;
    }

    final validationError =
        PortfolioDocumentParser.validateFile(fileName, bytes.length);
    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
        _state = _ImportState.error;
      });
      return;
    }

    setState(() {
      _selectedFileName = fileName;
      _state = _ImportState.uploading;
      _uploadProgress = 0;
      _errorMessage = null;
    });

    // Animate progress while parsing/saving
    int step = 0;
    _progressTimer =
        Timer.periodic(const Duration(milliseconds: 60), (timer) {
      step++;
      if (mounted) {
        setState(() {
          // Only advance to 80% — the last 20% fills after Firestore save
          _uploadProgress = ((step / 40) * 0.8).clamp(0.0, 0.8);
        });
      }
      if (step >= 40) timer.cancel();
    });

    try {
      List<PortfolioInvestment> investments;
      final ext = fileName.toLowerCase();

      if (ext.endsWith('.csv')) {
        final content = String.fromCharCodes(bytes);
        investments = PortfolioDocumentParser.parseCsv(content);
      } else {
        // xlsx / xls
        final excel = xl.Excel.decodeBytes(bytes);
        final sheetName = excel.tables.keys.first;
        final sheet = excel.tables[sheetName]!;
        final rows = sheet.rows
            .map((row) => row.map((cell) => cell?.value).toList())
            .toList();
        investments = PortfolioDocumentParser.parseExcelRows(rows);
      }

      if (investments.isEmpty) {
        _progressTimer?.cancel();
        if (mounted) {
          setState(() {
            _errorMessage =
                'No valid investment rows found. Check that your file matches the expected format.';
            _state = _ImportState.error;
          });
        }
        return;
      }

      final count = await _service.addBulk(investments);
      _progressTimer?.cancel();

      if (mounted) {
        setState(() {
          _uploadProgress = 1.0;
          _importedCount = count;
          _state = _ImportState.success;
        });
      }
    } catch (e) {
      _progressTimer?.cancel();
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to process file: $e';
          _state = _ImportState.error;
        });
      }
    }
  }

  void _onViewInsights() {
    context.push('/portfolio-insights');
  }

  void _onReset() {
    setState(() {
      _state = _ImportState.idle;
      _selectedFileName = null;
      _uploadProgress = 0;
      _errorMessage = null;
      _importedCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.mainGradient,
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      _buildHeroSection(),
                      const SizedBox(height: 32),
                      _buildUploadArea(),
                      const SizedBox(height: 24),
                      if (_state == _ImportState.idle) ...[
                        _buildFormatSupportRow(),
                        const SizedBox(height: 32),
                        _buildManualEntryBanner(context),
                      ],
                      if (_state == _ImportState.error) ...[
                        const SizedBox(height: 8),
                        _buildErrorBanner(),
                        const SizedBox(height: 16),
                        _buildRetryButton(),
                      ],
                      if (_state == _ImportState.success) ...[
                        const SizedBox(height: 8),
                        _buildSuccessSummary(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                      ],
                      const SizedBox(height: 32),
                      _buildPrivacyNote(),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          const Expanded(
            child: Text(
              'Import Portfolio',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.secondaryAccentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.secondaryAccentColor.withOpacity(0.4),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 14,
                  color: AppTheme.secondaryAccentColor,
                ),
                SizedBox(width: 4),
                Text(
                  'AI Powered',
                  style: TextStyle(
                    color: AppTheme.secondaryAccentColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withOpacity(0.3),
                  AppTheme.primaryColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: const Icon(
              LucideIcons.fileSpreadsheet,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Upload Your Portfolio',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Import your investment document and get\nAI-powered insights instantly',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUploadArea() {
    switch (_state) {
      case _ImportState.idle:
        return _buildDropZone();
      case _ImportState.uploading:
        return _buildUploadProgress();
      case _ImportState.success:
        return _buildUploadSuccess();
      case _ImportState.error:
        return _buildDropZone();
    }
  }

  Widget _buildDropZone() {
    return GestureDetector(
      onTap: _pickAndUploadFile,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppTheme.primaryColor.withOpacity(0.4),
            width: 2,
          ),
          gradient: LinearGradient(
            colors: [
              AppTheme.primaryColor.withOpacity(0.06),
              AppTheme.primaryColor.withOpacity(0.02),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.uploadCloud,
                size: 36,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tap to Upload File',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Supports CSV and Excel (.xlsx / .xls)',
              style:
                  TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFormatBadge('XLSX'),
                const SizedBox(width: 8),
                _buildFormatBadge('XLS'),
                const SizedBox(width: 8),
                _buildFormatBadge('CSV'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatBadge(String format) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        format,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: AppTheme.glassDecoration,
      child: Column(
        children: [
          const Icon(
            LucideIcons.fileUp,
            size: 40,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            _selectedFileName ?? 'file.xlsx',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation(
                  AppTheme.primaryColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${(_uploadProgress * 100).toInt()}% — Processing & Saving...',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSuccess() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border:
            Border.all(color: AppTheme.primaryColor.withOpacity(0.5)),
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.12),
            AppTheme.primaryColor.withOpacity(0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle2,
              size: 40,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload Successful!',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFileName ?? 'portfolio.xlsx',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_importedCount investment${_importedCount == 1 ? '' : 's'} imported · Saved to portfolio',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSupportRow() {
    return Row(
      children: [
        _buildSupportItem(
          LucideIcons.fileSpreadsheet,
          'Excel\n(.xlsx / .xls)',
          AppTheme.primaryColor,
        ),
        const SizedBox(width: 12),
        _buildSupportItem(
          LucideIcons.fileText,
          'CSV\nFormat',
          const Color(0xFF60A5FA),
        ),
        const SizedBox(width: 12),
        _buildSupportItem(
          LucideIcons.info,
          'Columns:\nName, Type, Amount...',
          AppTheme.secondaryAccentColor,
        ),
      ],
    );
  }

  Widget _buildSupportItem(IconData icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: AppTheme.glassDecoration,
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntryBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/add-investment'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassDecoration,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                LucideIcons.plusCircle,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Manually',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Enter investments one by one',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.arrowRight,
              color: AppTheme.primaryColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle,
              color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? 'An error occurred. Please try again.',
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return OutlinedButton.icon(
      onPressed: _onReset,
      icon: const Icon(LucideIcons.refreshCw, size: 16),
      label: const Text('Try Again'),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppTheme.primaryColor),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    );
  }

  Widget _buildSuccessSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.glassDecoration,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(LucideIcons.checkCircle2,
              color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Text(
            '$_importedCount investment${_importedCount == 1 ? '' : 's'} saved to your portfolio',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _onViewInsights,
          icon: const Icon(LucideIcons.sparkles, size: 18),
          label: const Text('View Portfolio Insights'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _onReset,
          icon: const Icon(LucideIcons.uploadCloud, size: 16),
          label: const Text('Upload Another File'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppTheme.primaryColor),
            minimumSize: const Size(double.infinity, 52),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyNote() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          LucideIcons.shieldCheck,
          size: 14,
          color: AppTheme.textSecondary,
        ),
        const SizedBox(width: 6),
        const Flexible(
          child: Text(
            'Files are processed on-device and saved securely to your account',
            style:
                TextStyle(color: AppTheme.textSecondary, fontSize: 11),
          ),
        ),
      ],
    );
  }
}

enum _ImportState { idle, uploading, success, error }
