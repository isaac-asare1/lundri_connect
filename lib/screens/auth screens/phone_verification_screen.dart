import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/route_names.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../laundry/laundry_location_picker_screen.dart';
import 'phone_verification_arguments.dart';

class PhoneVerificationScreen extends StatefulWidget {
  final PhoneVerificationArguments arguments;

  const PhoneVerificationScreen({super.key, required this.arguments});

  @override
  State<PhoneVerificationScreen> createState() =>
      _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();

  String? _verificationId;
  int? _resendToken;

  bool _isSendingCode = false;
  bool _isCompletingRegistration = false;
  bool _codeSent = false;

  Timer? _resendTimer;
  int _resendSeconds = 45;

  bool get _isBusy => _isSendingCode || _isCompletingRegistration;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendVerificationCode();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendVerificationCode({bool isResend = false}) async {
    if (_isBusy) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSendingCode = true;
    });

    final authProvider = context.read<app_auth.AuthProvider>();

    try {
      await authProvider.sendPhoneVerificationCode(
        phoneNumber: widget.arguments.phoneNumber,
        forceResendingToken: isResend ? _resendToken : null,

        verificationCompleted: (PhoneAuthCredential credential) async {
          if (!mounted) return;

          setState(() {
            _isSendingCode = false;
          });

          await _completeRegistration(credential);
        },

        verificationFailed: (FirebaseAuthException error) {
          if (!mounted) return;

          setState(() {
            _isSendingCode = false;
          });

          _showMessage(_friendlyFirebaseMessage(error));
        },

        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _resendToken = resendToken;
            _codeSent = true;
            _isSendingCode = false;
          });

          _startResendTimer();

          _showMessage(
            isResend
                ? 'A new verification code has been sent.'
                : 'Verification code sent.',
          );
        },

        codeAutoRetrievalTimeout: (String verificationId) {
          if (!mounted) return;

          setState(() {
            _verificationId = verificationId;
            _isSendingCode = false;
          });
        },
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      setState(() {
        _isSendingCode = false;
      });

      _showMessage(_friendlyFirebaseMessage(error));
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _isSendingCode = false;
      });

      _showMessage('Unable to send the verification code. Please try again.');
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();

    setState(() {
      _resendSeconds = 45;
    });

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSeconds <= 1) {
        timer.cancel();

        setState(() {
          _resendSeconds = 0;
        });

        return;
      }

      setState(() {
        _resendSeconds--;
      });
    });
  }

  Future<void> _verifyEnteredCode() async {
    if (_isBusy) return;

    final code = _otpController.text.trim();

    if (code.length != 6) {
      _showMessage('Enter the 6-digit verification code.');
      return;
    }

    final verificationId = _verificationId;

    if (verificationId == null || verificationId.isEmpty) {
      _showMessage(
        'The verification session is not ready. Please resend the code.',
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: code,
    );

    await _completeRegistration(credential);
  }

  Future<void> _completeRegistration(
    PhoneAuthCredential phoneCredential,
  ) async {
    if (_isCompletingRegistration) return;

    setState(() {
      _isCompletingRegistration = true;
    });

    final authProvider = context.read<app_auth.AuthProvider>();
    final args = widget.arguments;

    final success = await authProvider.completeSignupWithVerifiedPhone(
      fullName: args.fullName,
      email: args.email,
      laundryServiceName: args.laundryServiceName,
      password: args.password,
      role: args.role,
      phoneCredential: phoneCredential,
    );

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isCompletingRegistration = false;
      });

      _showMessage(
        authProvider.errorMessage.isNotEmpty
            ? authProvider.errorMessage
            : 'Account creation could not be completed.',
      );

      return;
    }

    _resendTimer?.cancel();

    if (args.isLaundry) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const LaundryLocationPickerScreen(),
        ),
        (route) => false,
      );

      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      RouteNames.riderBusinessInfo,
      (route) => false,
    );
  }

  String _friendlyFirebaseMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'The phone number is invalid.';
      case 'invalid-verification-code':
        return 'The verification code is incorrect.';
      case 'session-expired':
        return 'The verification code has expired. Request a new code.';
      case 'too-many-requests':
        return 'Too many verification attempts. Please try again later.';
      case 'quota-exceeded':
        return 'The SMS verification limit has been reached. Please try again later.';
      case 'credential-already-in-use':
        return 'This phone number is already connected to another account.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Phone authentication is not enabled for this Firebase project.';
      default:
        return error.message ?? 'Phone verification failed. Please try again.';
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  String _maskedPhoneNumber(String value) {
    if (value.length <= 7) return value;

    final visibleStart = value.substring(0, value.length - 4);

    final visibleEnd = value.substring(value.length - 4);

    return '$visibleStart••$visibleEnd';
  }

  @override
  Widget build(BuildContext context) {
    final phone = _maskedPhoneNumber(widget.arguments.phoneNumber);

    return PopScope(
      canPop: !_isCompletingRegistration,
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: !_isCompletingRegistration,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verify your phone',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeSent
                      ? 'Enter the 6-digit code sent to $phone.'
                      : 'We are sending a verification code to $phone.',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.phone_android_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phone number',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.arguments.phoneNumber,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Verification code',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _otpController,
                  enabled: !_isCompletingRegistration,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 10,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '••••••',
                    filled: true,
                    fillColor: AppColors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.6,
                      ),
                    ),
                  ),
                  onSubmitted: (_) {
                    _verifyEnteredCode();
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: !_codeSent || _isBusy
                        ? null
                        : _verifyEnteredCode,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _isCompletingRegistration
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Verify & Continue',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 18),

                Center(
                  child: _isSendingCode
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Sending code...',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : TextButton(
                          onPressed: _resendSeconds == 0 && !_isBusy
                              ? () {
                                  _otpController.clear();

                                  _sendVerificationCode(isResend: true);
                                }
                              : null,
                          child: Text(
                            _resendSeconds > 0
                                ? 'Resend code in 00:${_resendSeconds.toString().padLeft(2, '0')}'
                                : 'Resend code',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _resendSeconds == 0
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'By continuing, you confirm that this phone number belongs to you and can receive verification SMS messages.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
