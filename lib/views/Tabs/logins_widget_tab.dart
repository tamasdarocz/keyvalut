import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/views/Widgets/totp_widget.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database_model.dart';
import '../../data/database_provider.dart';
import 'create_logins_form.dart';
import '../../data/database_helper.dart';
import '../../services/url_service.dart';


class LoginsWidgetTab extends StatefulWidget {
  const LoginsWidgetTab({super.key});

  @override
  State<LoginsWidgetTab> createState() => _LoginsWidgetTabState();
}

class _LoginsWidgetTabState extends State<LoginsWidgetTab> {
  DatabaseHelper? _dbHelper;

  @override
  void initState() {
    super.initState();
    _loadDatabase();
  }

  Future<void> _loadDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final databaseName = prefs.getString('currentDatabase');
    if (databaseName != null) {
      setState(() {
        _dbHelper = DatabaseHelper(databaseName);
      });
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dbHelper == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'create',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateLoginsForm(dbHelper: _dbHelper!),
            ),
          );
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          if (provider.logins.isEmpty) {
            return Center(
              child: Text(
                'No credentials found',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            );
          }

          // Load logins on first build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            provider.loadLogins();
          });

          return ListView.builder(
            itemCount: provider.logins.length,
            itemBuilder: (context, index) {
              final login = provider.logins[index];
              final hasTotpSecret = login.totpSecret != null && login.totpSecret!.isNotEmpty;

              // Handle billing address display (compact format)
              final billingAddressLines = login.billingAddress?.split(RegExp(r'[\n,]')) ?? [];
              final addressDisplay = billingAddressLines.isNotEmpty
                  ? billingAddressLines.where((line) => line.trim().isNotEmpty).join(', ')
                  : 'N/A';

              // Find the linked credit card
              final creditCard = login.creditCardId != null
                  ? provider.creditCards.firstWhere(
                    (card) => card.id == login.creditCardId,
                orElse: () => CreditCard(
                  id: null,
                  title: 'Unknown',
                  ch_name: '',
                  card_number: '****',
                  expiry_date: '',
                  cvv: '',
                ),
              )
                  : null;

              final creditCardDisplay = creditCard != null
                  ? '${creditCard.title} - ${creditCard.cardNumber.substring(creditCard.cardNumber.length - 4)}'
                  : 'N/A';

              // Build the list of detail rows, only including non-empty fields
              final detailRows = <Widget>[];
              if (login.website != null && login.website!.isNotEmpty) {
                detailRows.add(_buildDetailRow(context, 'Website', login.website!));
              }
              if (login.email != null && login.email!.isNotEmpty) {
                detailRows.add(_buildDetailRow(context, 'Email', login.email!));
              }
              detailRows.add(_buildDetailRow(context, 'Username', login.username));
              detailRows.add(_PasswordRow(password: login.password));
              if (login.phoneNumber != null && login.phoneNumber!.isNotEmpty) {
                detailRows.add(_buildDetailRow(context, 'Phone', login.phoneNumber!));
              }
              if (login.billingDate != null && login.billingDate!.isNotEmpty) {
                detailRows.add(_buildDetailRow(context, 'Billing Date', login.billingDate!));
              }
              if (addressDisplay != 'N/A') {
                detailRows.add(_buildDetailRow(context, 'Billing Address', addressDisplay));
              }
              if (creditCardDisplay != 'N/A') {
                detailRows.add(_buildDetailRow(context, 'Credit Card', creditCardDisplay));
              }
              if (login.notificationSetting != 'Disabled' && login.notificationSetting!.isNotEmpty) {
                detailRows.add(_buildDetailRow(context, 'Notification', login.notificationSetting!));
              }
              if (login.selectedPeriod != 'None' && login.selectedPeriod!.isNotEmpty) {
                detailRows.add(_buildDetailRow(context, 'Billing Period', login.selectedPeriod!));
              }

              return Slidable(
                startActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) async {
                        if (login.id != null) {
                          await provider.archiveLogins(login.id!);
                          Fluttertoast.showToast(
                            msg: 'Login Archived',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                          );
                        }
                      },
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      icon: Icons.archive,
                      label: 'Archive',
                    ),
                    SlidableAction(
                      onPressed: (context) async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Login'),
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
                        if (confirmed == true && login.id != null) {
                          await provider.deleteLogins(login.id!);
                          Fluttertoast.showToast(
                            msg: 'Login Deleted',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.CENTER,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            textColor: Theme.of(context).colorScheme.onPrimary,
                          );
                        }
                      },
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
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
                            builder: (context) => CreateLoginsForm(
                              dbHelper: _dbHelper!,
                              login: login,
                            ),
                          ),
                        );
                      },
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      icon: Icons.edit,
                      label: 'Edit',
                    ),
                  ],
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  color: Theme.of(context).cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: ExpansionTile(
                    minTileHeight: 90,
                    backgroundColor: Theme.of(context).primaryColor,
                    leading: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          login.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        if (hasTotpSecret) TotpWidget(totpSecret: login.totpSecret),
                      ],
                    ),
                    children: [
                      Divider(),
                      ColoredBox(
                        color: Theme.of(context).colorScheme.surface,
                        child: Container(
                          padding: const EdgeInsets.all(8.0),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: detailRows,
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
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 120, // Increased width for better alignment with longer labels
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
                UrlService.launchWebsite(context: context, url

                    : value);
              },
            ),
          IconButton(
            icon: Icon(Icons.copy, size: 20, color: theme.colorScheme.onSurface),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              Fluttertoast.showToast(msg: 'Copied!', gravity: ToastGravity.CENTER);
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
            width: 120, // Increased width for consistency
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
              Fluttertoast.showToast(msg: 'Password copied!', gravity: ToastGravity.CENTER);
            },
          ),
        ],
      ),
    );
  }
}