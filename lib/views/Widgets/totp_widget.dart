import 'package:flutter/material.dart';
import 'dart:async';
import 'package:keyvalut/services/totp_generator.dart';

class TotpDisplay extends StatefulWidget {
  final String? totpSecret;

  const TotpDisplay({
    Key? key,
    required this.totpSecret,
  }) : super(key: key);

  @override
  State<TotpDisplay> createState() => _TotpDisplayState();
}

class _TotpDisplayState extends State<TotpDisplay> {
  String _currentCode = '';
  int _remainingSeconds = 0;
  Timer? _timer;
  static const int _period = 30;

  @override
  void initState() {
    super.initState();
    if (widget.totpSecret != null && widget.totpSecret!.isNotEmpty) {
      _generateCode();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds = TOTPGenerator.getRemainingSeconds(period: _period);
        if (_remainingSeconds == _period) {
          _generateCode();
        }
      });
    });
  }

  void _generateCode() {
    try {
      if (widget.totpSecret != null && widget.totpSecret!.isNotEmpty) {
        _currentCode = TOTPGenerator.generateTOTP(widget.totpSecret!);
        _remainingSeconds = TOTPGenerator.getRemainingSeconds(period: _period);
      }
    } catch (e) {
      _currentCode = 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totpSecret == null || widget.totpSecret!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        // Circular progress indicator
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            strokeAlign: BorderSide.strokeAlignOutside,
            value: _remainingSeconds / _period,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.amber,
            ),
            strokeWidth: 3,
          ),
        ),
        // TOTP Code with padding
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Text(
            _currentCode,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}