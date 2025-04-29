import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


import '../../services/qr_scanner.dart';

class TotpSecretInputField extends StatefulWidget {
  final TextEditingController controller;

  const TotpSecretInputField({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<TotpSecretInputField> createState() => _TotpSecretInputFieldState();
}

class _TotpSecretInputFieldState extends State<TotpSecretInputField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      decoration: InputDecoration(
        border: OutlineInputBorder( borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary, width: 1),),
        labelText: 'TOTP Secret',
        hintText: 'Enter TOTP secret key for authenticator',
        prefixIcon: const Icon(Icons.security),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // QR scan button
            IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QRScannerScreen(
                      onQRScanned: (label, secret) {
                        widget.controller.text = secret;
                      },
                    ),
                  ),
                );
              },
              tooltip: 'Scan QR code',
            ),
            // Toggle visibility
            IconButton(
              icon: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            ),
          ],
        ),
      ),
      // Allow only alphanumeric characters for Base32
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
      ],
    );
  }
}