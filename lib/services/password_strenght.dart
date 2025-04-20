import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  double _calculateStrength() {
    int score = 0;
    if (password.isEmpty) return 0;

    // Length
    if (password.length >= 4) score++;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character types
    if (password.contains(RegExp(r'[A-Z]'))) score++; // Uppercase
    if (password.contains(RegExp(r'[a-z]'))) score++; // Lowercase
    if (password.contains(RegExp(r'[0-9]'))) score++; // Numbers
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++; // Special chars

    // Normalize score to 0-1 range (max score is 7)
    return score / 7.0;
  }

  String _getStrengthLabel(double strength) {
    if (strength < 0.3) return 'Weak';
    if (strength < 0.6) return 'Moderate';
    if (strength < 0.9) return 'Strong';
    return 'Very Strong';
  }

  Color _getStrengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.9) return Colors.blue;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Strength: ${_getStrengthLabel(strength)}',
          style: TextStyle(
            color: _getStrengthColor(strength),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: strength,
          backgroundColor: Colors.grey[300],
          color: _getStrengthColor(strength),
          minHeight: 5,
        ),
      ],
    );
  }
}