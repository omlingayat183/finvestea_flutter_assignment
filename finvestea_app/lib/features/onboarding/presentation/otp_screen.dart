import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme.dart';
import '../../../core/services/auth_service.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _authService = AuthService();

  String? _verificationId;
  String? _phoneNumber;
  bool _isLoading = false;
  bool _canResend = false;
  int _resendTimer = 60;
  String? _errorMessage;

  // Guard so arguments are loaded only once from GoRouterState
  bool _argumentsLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // GoRouterState.of(context) uses InheritedWidget — cannot be called in
    // initState(). didChangeDependencies() is the earliest safe point.
    if (!_argumentsLoaded) {
      _argumentsLoaded = true;
      _loadArguments();
      _startResendTimer();
    }
  }

  void _loadArguments() {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    if (extra != null) {
      _verificationId = extra['verificationId'] as String?;
      _phoneNumber = extra['phoneNumber'] as String?;
    }
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
          _startResendTimer();
        } else {
          _canResend = true;
        }
      });
    });
  }

  @override
  void dispose() {
    for (var c in _controllers) {
      c.dispose();
    }
    for (var n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  String _getOTP() => _controllers.map((c) => c.text).join();

  Future<void> _verifyOTP() async {
    final otp = _getOTP();

    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP.';
      });
      return;
    }

    if (_verificationId == null) {
      setState(() {
        _errorMessage =
            'Verification session expired. Please go back and request a new OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userCredential = await _authService.verifyOTP(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      if (userCredential != null && mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e is AuthException) {
          _errorMessage = _authService.getErrorMessage(e);
        } else {
          _errorMessage = 'Verification failed. Please try again.';
        }
      });
    }
  }

  Future<void> _resendOTP() async {
    if (_phoneNumber == null) return;

    setState(() {
      _canResend = false;
      _resendTimer = 60;
      _errorMessage = null;
    });
    _startResendTimer();

    await _authService.resendOTP(
      phoneNumber: _phoneNumber!,
      onCodeSent: (verificationId) {
        if (!mounted) return;
        setState(() => _verificationId = verificationId);
      },
      onError: (AuthException e) {
        if (!mounted) return;
        setState(() => _errorMessage = _authService.getErrorMessage(e));
      },
      onAutoVerified: () {
        if (mounted) context.go('/dashboard');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.mainGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(
                    LucideIcons.chevronLeft,
                    color: Colors.white,
                  ),
                  onPressed: () => context.pop(),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),
                Text(
                  'Verify OTP',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the 6-digit code sent to '
                  '${_phoneNumber != null ? "+91 $_phoneNumber" : "your mobile number"}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    return Container(
                      width: 48,
                      height: 56,
                      decoration: AppTheme.glassDecoration,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          // Auto-submit when all 6 digits are filled
                          if (_getOTP().length == 6) {
                            FocusScope.of(context).unfocus();
                            _verifyOTP();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.alertCircle,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: _canResend ? _resendOTP : null,
                    child: Text(
                      _canResend
                          ? 'Resend Code'
                          : 'Resend Code in ${_resendTimer}s',
                      style: TextStyle(
                        color: _canResend
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOTP,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Verify & Continue'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
