import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/credentialProvider.dart';
import '../../services/totp_service.dart';
import 'add_authenticator_screen.dart';

class SecondTab extends StatefulWidget {
  const SecondTab({super.key});

  @override
  State<SecondTab> createState() => _SecondTabState();
}

class _SecondTabState extends State<SecondTab> {
  final TotpService _totpService = TotpService();
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _remainingSeconds = _totpService.getRemainingSeconds();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds = _totpService.getRemainingSeconds();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CredentialProvider>(
      builder: (context, credentialProvider, child) {
        final entries = credentialProvider.authenticatorEntries;

        return Scaffold(
          body: entries.isEmpty
              ? const Center(child: Text('No Authenticator Entries'))
              : ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final totpCode = _totpService.generateTotpCode(entry['totp_secret']);
                    return ListTile(
                      title: Text(entry['service_name']),
                      subtitle: Text(totpCode, style: const TextStyle(fontSize: 20)),
                      trailing: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: _remainingSeconds / 30,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text('$_remainingSeconds'),
                        ],
                      ),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddAuthenticatorScreen()),
              );
            },
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}