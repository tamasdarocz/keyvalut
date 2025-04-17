import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _passwordController = TextEditingController();
  final _correctPassword = '1234'; // Replace with your actual password logic
  static const _secureScreenChannel = MethodChannel('com.keyvalut.app/secure_screen');

  @override
  void initState() {
    super.initState();
    _setSecureFlag();
  }

  @override
  void dispose() {
    _clearSecureFlag();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _setSecureFlag() async {
    if (Platform.isAndroid) {
      try {
        // This requires implementing the method channel on the Android side
        await _secureScreenChannel.invokeMethod('setSecureFlag', true);
      } catch (e) {
        // Fallback to using system UI restrictions if method channel fails
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
        );
      }
    }

    // For iOS, we don't need to do anything special for screenshot prevention
    // as iOS doesn't allow screenshots in secure contexts by default
  }

  Future<void> _clearSecureFlag() async {
    if (Platform.isAndroid) {
      try {
        await _secureScreenChannel.invokeMethod('setSecureFlag', false);
      } catch (e) {
        // Restore normal system UI mode
        await SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.edgeToEdge,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'App Locked',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                onSubmitted: (_) => _attemptUnlock(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _attemptUnlock,
                child: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _attemptUnlock() {
    if (_passwordController.text == _correctPassword) {
      widget.onUnlock();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect password')),
      );
    }
  }
}