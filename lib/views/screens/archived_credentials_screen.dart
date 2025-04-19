import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/credential_provider.dart';
import '../../data/credential_model.dart';

class ArchivedItemsView extends StatelessWidget {
  const ArchivedItemsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CredentialProvider>(context);
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadArchivedItems();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Items'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Consumer<CredentialProvider>(
        builder: (context, provider, child) {
          if (provider.archivedCredentials.isEmpty && provider.archivedCreditCards.isEmpty) {
            return Center(
              child: Text(
                'No archived items found',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(8),
            children: [
              // Archived Credentials
              if (provider.archivedCredentials.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Credentials',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...provider.archivedCredentials.map((credential) => Slidable(
                  key: ValueKey(credential.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          await provider.restoreCredential(credential.id!);
                          Fluttertoast.showToast(
                            msg: 'Credential Restored',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.TOP,
                            backgroundColor: theme.colorScheme.primary,
                            textColor: theme.colorScheme.onPrimary,
                          );
                        },
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        icon: Icons.restore,
                        label: 'Restore',
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(credential.title),
                    subtitle: Text('Archived at: ${credential.archivedAt}'),
                  ),
                )),
              ],
              // Archived Credit Cards
              if (provider.archivedCreditCards.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Credit Cards',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...provider.archivedCreditCards.map((card) => Slidable(
                  key: ValueKey(card.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          await provider.restoreCreditCard(card.id!);
                          Fluttertoast.showToast(
                            msg: 'Credit Card Restored',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.TOP,
                            backgroundColor: theme.colorScheme.primary,
                            textColor: theme.colorScheme.onPrimary,
                          );
                        },
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        icon: Icons.restore,
                        label: 'Restore',
                      ),
                    ],
                  ),
                  child: ListTile(
                    title: Text(card.title),
                    subtitle: Text('Archived at: ${card.archivedAt}'),
                  ),
                )),
              ],
            ],
          );
        },
      ),
    );
  }
}