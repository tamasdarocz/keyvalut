import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyvalut/views/Widgets/textforms/totp_display.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../data/credential_provider.dart';
import '../../views/Widgets/create_element_form.dart';
import '../../data/database_helper.dart';
import '../../services/url_service.dart';

class CredentialsWidget extends StatelessWidget {
  const CredentialsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final credentialProvider = Provider.of<CredentialProvider>(context);
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      credentialProvider.loadCredentials();
    });

    return Consumer<CredentialProvider>(
      builder: (context, provider, child) {
        if (provider.credentials.isEmpty) {
          return Center(child: Text('No credentials found', style: TextStyle(color: theme.colorScheme.onSurface)));
        }

        return ListView.builder(
          itemCount: provider.credentials.length,
          itemBuilder: (context, index) {
            final credential = provider.credentials[index];
            final hasTotpSecret = credential.totpSecret != null && credential.totpSecret!.isNotEmpty;

            return Slidable(
              key: ValueKey(credential.id),
              startActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {
                      provider.moveToArchive(credential.id!);
                    },
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    icon: Icons.archive,
                    label: 'Archive',
                  ),
                  SlidableAction(
                    onPressed: (context) async {
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
                        await provider.moveToTrash(credential.id!);
                      }
                    },
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                    icon: Icons.delete,
                    label: 'Delete',
                  ),
                ],
              ),
              endActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) {
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
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    icon: Icons.edit,
                    label: 'Edit',
                  ),
                ],
              ),
              child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: ExpansionTile(
                  minTileHeight: 90,
                  backgroundColor: theme.cardColor,
                  leading: Icon(Icons.person, color: theme.colorScheme.onSurface),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          credential.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 20,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (hasTotpSecret) TotpDisplay(totpSecret: credential.totpSecret),
                    ],
                  ),
                  children: [
                    ColoredBox(
                      color: theme.cardColor,
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (credential.website != null && credential.website!.isNotEmpty)
                                _buildDetailRow(context, 'Website', credential.website!),
                              if (credential.email != null && credential.email!.isNotEmpty)
                                _buildDetailRow(context, 'Email', credential.email!),
                              _buildDetailRow(context, 'Username', credential.username),
                              _PasswordRow(password: credential.password),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          if (label == 'Website')
            IconButton(
              icon: Icon(Icons.launch, size: 20, color: theme.colorScheme.onSurface),
              onPressed: () {
                UrlService.launchWebsite(context: context, url: value);
              },
            ),
          IconButton(
            icon: Icon(Icons.copy, size: 20, color: theme.colorScheme.onSurface),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Center(child: Text('$label copied!'))),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PasswordRow extends StatefulWidget {
  final String password;

  const _PasswordRow({required this.password});

  @override
  _PasswordRowState createState() => _PasswordRowState();
}

class _PasswordRowState extends State<_PasswordRow> {
  bool _showPassword = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              'Password:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _showPassword ? widget.password : '********',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              size: 20,
              color: theme.colorScheme.onSurface,
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 20, color: theme.colorScheme.onSurface),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.password));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Center(child: Text('Password copied!'))),
              );
            },
          ),
        ],
      ),
    );
  }
}