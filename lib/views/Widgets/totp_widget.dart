import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '/services/totp_generator.dart';

class TotpWidget extends StatefulWidget {
  final String? totpSecret;

  const TotpWidget({
    super.key,
    required this.totpSecret,
  });

  @override
  State<TotpWidget> createState() => _TotpWidgetState();
}

class _TotpWidgetState extends State<TotpWidget> {
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
    final theme = Theme.of(context);
    if (widget.totpSecret == null || widget.totpSecret!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 80,
          height: 80,
          child: CircularProgressIndicator(
            value: _remainingSeconds / _period,
            backgroundColor: theme.colorScheme.onSurface.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            strokeWidth: 3,
          ),
        ),
        TextButton(

          onPressed: () {
            Clipboard.setData(ClipboardData(text: _currentCode));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Center(child: Text('Copied!'))),
            );
          },
          child: Text(
            _currentCode,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}