import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/credentialProvider.dart';
import '../../data/credential_item.dart';


class CredentialsWidget extends StatelessWidget {
  const CredentialsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final credentialProvider = Provider.of<CredentialProvider>(context);

    // Load credentials on initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      credentialProvider.loadCredentials();
    });

    return Consumer<CredentialProvider>(
      builder: (context, provider, child) {
        if (provider.credentials.isEmpty) {
          return const Center(child: Text('No credentials found'));
        }
        return ListView.builder(
          itemCount: provider.credentials.length,
          itemBuilder: (context, index) =>
              CredentialItem(credential: provider.credentials[index]),
        );
      },
    );
  }
}