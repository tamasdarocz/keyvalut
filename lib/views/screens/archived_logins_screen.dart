import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/database_provider.dart';

class ArchivedItemsView extends StatelessWidget {
  const ArchivedItemsView({super.key});

  Future<bool> _confirmBulkAction(BuildContext context, String action, String itemType) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$action All $itemType'),
        content: Text('Are you sure you want to $action all $itemType items? ${action == "Permanently Delete" ? "This action cannot be undone." : ""}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    )) ??
        false;
  }

  Future<void> _deleteAllItems(BuildContext context,DatabaseProvider provider) async {
    if (provider.archivedLogins.isEmpty && provider.archivedCreditCards.isEmpty && provider.archivedNotes.isEmpty) return;

    final confirmed = await _confirmBulkAction(context, 'Permanently Delete', 'Archived');
    if (!confirmed) return;

    for (var login in provider.archivedLogins) {
      await provider.permanentlyDeleteLogin(login.id!);
    }
    for (var card in provider.archivedCreditCards) {
      await provider.permanentlyDeleteCreditCard(card.id!);
    }
    for (var note in provider.archivedNotes) {
      await provider.permanentlyDeleteNote(note.id!);
    }

    Fluttertoast.showToast(
      msg: 'All Archived Items Permanently Deleted',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );
  }

  Future<void> _restoreAllItems(BuildContext context, DatabaseProvider provider) async {
    if (provider.archivedLogins.isEmpty && provider.archivedCreditCards.isEmpty && provider.archivedNotes.isEmpty) return;

    final confirmed = await _confirmBulkAction(context, 'Restore', 'Archived');
    if (!confirmed) return;

    for (var login in provider.archivedLogins) {
      await provider.restoreLogins(login.id!);
    }
    for (var card in provider.archivedCreditCards) {
      await provider.restoreCreditCard(card.id!);
    }
    for (var note in provider.archivedNotes) {
      await provider.restoreNote(note.id!);
    }

    Fluttertoast.showToast(
      msg: 'All Archived Items Restored',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DatabaseProvider>(context);
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadArchivedItems();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Items'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Restore All',
            onPressed: provider.archivedLogins.isEmpty && provider.archivedCreditCards.isEmpty && provider.archivedNotes.isEmpty
                ? null
                : () => _restoreAllItems(context, provider),
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete All',
            onPressed: provider.archivedLogins.isEmpty && provider.archivedCreditCards.isEmpty && provider.archivedNotes.isEmpty
                ? null
                : () => _deleteAllItems(context, provider),
          ),
        ],
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          if (provider.archivedLogins.isEmpty &&
              provider.archivedCreditCards.isEmpty &&
              provider.archivedNotes.isEmpty) {
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
              // Archived Logins
              if (provider.archivedLogins.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Logins',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...provider.archivedLogins.map((login) => Slidable(
                  key: ValueKey(login.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          await provider.restoreLogins(login.id!);
                          Fluttertoast.showToast(
                            msg: 'Login Restored',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: theme.colorScheme.primary,
                            textColor: theme.colorScheme.onPrimary,
                          );
                        },
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        icon: Icons.restore,
                        label: 'Restore',
                      ),
                      SlidableAction(
                        onPressed: (context) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Permanently Delete Login'),
                              content: const Text('Are you sure you want to permanently delete this login? This action cannot be undone.'),
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
                          if (confirmed == true) {
                            await provider.permanentlyDeleteLogin(login.id!);
                            Fluttertoast.showToast(
                              msg: 'Login Permanently Deleted',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              backgroundColor: theme.colorScheme.primary,
                              textColor: theme.colorScheme.onPrimary,
                            );
                          }
                        },
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        icon: Icons.delete_forever,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: Card(
                    child: ListTile(
                      title: Text(login.title),
                      subtitle: Text('Archived at: ${login.archivedAt}'),
                    ),
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
                            gravity: ToastGravity.CENTER,
                            backgroundColor: theme.colorScheme.primary,
                            textColor: theme.colorScheme.onPrimary,
                          );
                        },
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        icon: Icons.restore,
                        label: 'Restore',
                      ),
                      SlidableAction(
                        onPressed: (context) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Permanently Delete Credit Card'),
                              content: const Text('Are you sure you want to permanently delete this credit card? This action cannot be undone.'),
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
                          if (confirmed == true) {
                            await provider.permanentlyDeleteCreditCard(card.id!);
                            Fluttertoast.showToast(
                              msg: 'Credit Card Permanently Deleted',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              backgroundColor: theme.colorScheme.primary,
                              textColor: theme.colorScheme.onPrimary,
                            );
                          }
                        },
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        icon: Icons.delete_forever,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: Card(
                    child: ListTile(
                      title: Text(card.title),
                      subtitle: Text('Archived at: ${card.archivedAt}'),
                    ),
                  ),
                )),
              ],
              // Archived Notes
              if (provider.archivedNotes.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                ...provider.archivedNotes.map((note) => Slidable(
                  key: ValueKey(note.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) async {
                          await provider.restoreNote(note.id!);
                          Fluttertoast.showToast(
                            msg: 'Note Restored',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: theme.colorScheme.primary,
                            textColor: theme.colorScheme.onPrimary,
                          );
                        },
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        icon: Icons.restore,
                        label: 'Restore',
                      ),
                      SlidableAction(
                        onPressed: (context) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Permanently Delete Note'),
                              content: const Text('Are you sure you want to permanently delete this note? This action cannot be undone.'),
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
                          if (confirmed == true) {
                            await provider.permanentlyDeleteNote(note.id!);
                            Fluttertoast.showToast(
                              msg: 'Note Permanently Deleted',
                              toastLength: Toast.LENGTH_SHORT,
                              gravity: ToastGravity.CENTER,
                              backgroundColor: theme.colorScheme.primary,
                              textColor: theme.colorScheme.onPrimary,
                            );
                          }
                        },
                        backgroundColor: theme.colorScheme.error,
                        foregroundColor: theme.colorScheme.onError,
                        icon: Icons.delete_forever,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: Card(
                    child: ListTile(
                      title: Text(note.title),
                      subtitle: Text('Archived at: ${note.archivedAt}'),
                    ),
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