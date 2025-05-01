import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/views/Widgets/totp_display.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database_provider.dart';
import '../textforms/create_element_form.dart';
import '../../data/database_helper.dart';
import '../../services/url_service.dart';

class LoginsWidget extends StatefulWidget {
  const LoginsWidget({super.key});

  @override
  State<LoginsWidget> createState() => _LoginsWidgetState();
}

class _LoginsWidgetState extends State<LoginsWidget> {
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
    final databaseProvider = Provider.of<DatabaseProvider>(context);
    final theme = Theme.of(context);

    // Load logins on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
     databaseProvider.loadLogins();
    });

    if (_dbHelper == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Consumer<DatabaseProvider>(
      builder: (context, provider, child) {
        if (provider.logins.isEmpty) {
          return Center(
            child: Text(
              'No credentials found',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          );
        }

        return ListView.builder(
          itemCount: provider.logins.length,
          itemBuilder: (context, index) {
            final login = provider.logins[index];
            final hasTotpSecret = login.totpSecret != null && login.totpSecret!.isNotEmpty;

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
                          backgroundColor: theme.colorScheme.primary,
                          textColor: theme.colorScheme.onPrimary,
                        );
                      }
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
                          backgroundColor: theme.colorScheme.primary,
                          textColor: theme.colorScheme.onPrimary,
                        );
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
                            dbHelper: _dbHelper!,
                            login: login,
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
                  borderRadius: BorderRadius.circular(0),
                ),
                child: ExpansionTile(
                  minTileHeight: 90,
                  backgroundColor: theme.primaryColor,
                  leading: Icon(Icons.person, color: theme.colorScheme.onSurface),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          login.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: TextStyle(
                            fontSize: 20,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (hasTotpSecret) TotpDisplay(totpSecret: login.totpSecret),
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
                              if (login.website != null && login.website!.isNotEmpty)
                                _buildDetailRow(context, 'Website', login.website!),
                              if (login.email != null && login.email!.isNotEmpty)
                                _buildDetailRow(context, 'Email', login.email!),
                              _buildDetailRow(context, 'Username', login.username),
                              _PasswordRow(password: login.password),
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
              Fluttertoast.showToast(msg: 'Password copied!', gravity: ToastGravity.CENTER);
            },
          ),
        ],
      ),
    );
  }
}