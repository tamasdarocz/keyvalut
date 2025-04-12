import 'package:flutter/material.dart';
import '../../data/credential_item.dart';
import '../../data/credential_model.dart';
import '../../data/database_helper.dart';

class CredentialsWidget extends StatefulWidget {
  const CredentialsWidget({super.key});

  @override
  State<CredentialsWidget> createState() => _CredentialsWidgetState();
}

class _CredentialsWidgetState extends State<CredentialsWidget> {
  late Future<List<Credential>> _credentialsFuture;

  @override
  void initState() {
    super.initState();
    _loadCredentials();
  }

  // Loads credentials from the database
  void _loadCredentials() {
    setState(() {
      _credentialsFuture = DatabaseHelper.instance.getCredentials();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Credential>>(
      future: _credentialsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator()); // Show loading spinner
        }
        if (snapshot.hasError) {
          print('FutureBuilder error: ${snapshot.error}'); // Log error for debugging
          return Center(child: Text('Error: ${snapshot.error}')); // Show specific error
        }
        final credentials = snapshot.data ?? [];
        if (credentials.isEmpty) {
          return const Center(child: Text('No credentials found')); // Handle empty state
        }
        return ListView.builder(
          itemCount: credentials.length,
          itemBuilder: (context, index) {
            final credential = credentials[index];
            return CredentialItem(credential: credential);
          },
        );
      },
    );
  }
}