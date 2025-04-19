import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyvalut/views/textforms/create_element_form.dart';
import 'package:provider/provider.dart';
import 'package:keyvalut/data/credential_provider.dart';
import 'package:keyvalut/data/credential_model.dart';
import 'package:keyvalut/services/url_service.dart';

import 'database_helper.dart';

class CredentialItem extends StatefulWidget {
  const CredentialItem({super.key, required Credential credential});

  @override
  State<CredentialItem> createState() => _CredentialItemState();
}

class _CredentialItemState extends State<CredentialItem> {
  List<bool> _expandedItems = [];

  @override
  void initState() {
    super.initState();
    // Load credentials on initial build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final credentialProvider =
          Provider.of<CredentialProvider>(context, listen: false);
      credentialProvider.loadCredentials();
    });
  }

  void _copyToClipboard(String text, String fieldName) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Center(child: Text('$fieldName copied!'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CredentialProvider>(
      builder: (context, provider, child) {
        if (provider.credentials.isEmpty) {
          return const Center(child: Text('No credentials found'));
        }

        // Initialize expanded state for each credential if needed
        if (_expandedItems.length != provider.credentials.length) {
          _expandedItems =
              List.generate(provider.credentials.length, (_) => false);
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ExpansionPanelList(
              expandedHeaderPadding: EdgeInsets.zero,
              expansionCallback: (int index, bool isExpanded) {
                setState(() {
                  _expandedItems[index] = !isExpanded;
                });
              },
              children: provider.credentials.asMap().entries.map((entry) {
                final index = entry.key;
                final credential = entry.value;

                // Get subtitle (email prefix or username)
                final subtitle =
                    credential.email != null && credential.email!.isNotEmpty
                        ? credential.email!.split('@').first
                        : credential.username;

                return ExpansionPanel(
                  headerBuilder: (context, isExpanded) {
                    return ListTile(
                      title: Text(credential.title),
                      subtitle: Text('Username: $subtitle'),
                      leading: const Icon(Icons.key),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () => _copyToClipboard(
                                credential.password, 'Password'),
                            tooltip: 'Copy password',
                          ),
                        ],
                      ),
                    );
                  },
                  body: _buildCredentialDetails(credential, context),
                  isExpanded: _expandedItems[index],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCredentialDetails(Credential credential, BuildContext context) {
    final ValueNotifier<bool> showPassword = ValueNotifier<bool>(false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Website
          if (credential.website != null && credential.website!.isNotEmpty)
            _buildDetailRow(
              context: context,
              label: 'Website',
              value: credential.website!,
              icon: Icons.launch,
              onTap: () => UrlService.launchWebsite(
                context: context,
                url: credential.website,
              ),
            ),

          // Email
          if (credential.email != null && credential.email!.isNotEmpty)
            _buildDetailRow(
              context: context,
              label: 'Email',
              value: credential.email!,
              icon: Icons.email,
            ),

          // Username
          _buildDetailRow(
            context: context,
            label: 'Username',
            value: credential.username,
            icon: Icons.person,
          ),

          // Password
          Padding(
            padding: const EdgeInsets.only(bottom: 6, top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'Password:',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: showPassword,
                    builder: (context, isVisible, _) {
                      return Text(
                        isVisible ? credential.password : '••••••••',
                      );
                    },
                  ),
                ),
                IconButton(
                  icon: ValueListenableBuilder<bool>(
                    valueListenable: showPassword,
                    builder: (context, isVisible, _) {
                      return Icon(
                        isVisible ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: Theme.of(context).colorScheme.secondary,
                      );
                    },
                  ),
                  onPressed: () {
                    showPassword.value = !showPassword.value;
                  },
                  tooltip: 'Show/hide password',
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    size: 20,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () =>
                      _copyToClipboard(credential.password, 'Password'),
                  tooltip: 'Copy password',
                ),
              ],
            ),
          ),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text('Edit'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateElementForm(
                        dbHelper: DatabaseHelper.instance,
                        credential: credential,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.delete, color: Colors.red),
                label:
                    const Text('Delete', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Credential'),
                      content: const Text('Are you sure you want to delete?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && credential.id != null) {
                    final provider =
                        Provider.of<CredentialProvider>(context, listen: false);
                    await provider.deleteCredential(credential.id!);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              child: Text(
                value,
                style: onTap != null
                    ? TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline)
                    : null,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.copy,
              size: 20,
              color: Theme.of(context).colorScheme.secondary,
            ),
            onPressed: () => _copyToClipboard(value, label),
            tooltip: 'Copy $label',
          ),
        ],
      ),
    );
  }
}
