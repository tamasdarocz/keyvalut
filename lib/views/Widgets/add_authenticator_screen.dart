import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../services/totp_service.dart';
import '../../data/credentialProvider.dart';

class AddAuthenticatorScreen extends StatefulWidget {
  const AddAuthenticatorScreen({super.key});

  @override
  State<AddAuthenticatorScreen> createState() => _AddAuthenticatorScreenState();
}

class _AddAuthenticatorScreenState extends State<AddAuthenticatorScreen> {
  final TextEditingController _serviceNameController = TextEditingController();
  String? _totpSecret;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _generateTotpSecret();
  }

  void _generateTotpSecret() {
    // For simplicity, we’ll use a random base32 string as the TOTP secret
    // In a production app, you should use a secure random generator
    _totpSecret = 'JBSWY3DPEHPK3PXP'; // Example secret (replace with secure generation)
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totpService = TotpService();
    final credentialProvider = Provider.of<CredentialProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Authenticator'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _serviceNameController,
              decoration: InputDecoration(
                labelText: 'Service Name (e.g., Google)',
                errorText: _errorText,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan the QR code below with an authenticator app:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_totpSecret != null)
              Center(
                child: QrImageView(
                  data: totpService.generateTotpUri(
                    _totpSecret!,
                    'KeyValut',
                    _serviceNameController.text.isEmpty
                        ? 'User'
                        : _serviceNameController.text,
                  ),
                  size: 200.0,
                  backgroundColor: Colors.white,
                ),
              ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () async {
                  final serviceName = _serviceNameController.text.trim();
                  if (serviceName.isEmpty) {
                    setState(() {
                      _errorText = 'Service name is required';
                    });
                    return;
                  }

                  // Add the authenticator entry to the database
                  await credentialProvider.addAuthenticatorEntry(
                    serviceName: serviceName,
                    totpSecret: _totpSecret!,
                  );

                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Authenticator'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}