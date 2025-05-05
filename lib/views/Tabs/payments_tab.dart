import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database_provider.dart';
import '../../data/database_helper.dart';
import '../../data/database_model.dart';
import '../screens/credit_card_details_screen.dart';
import '../Tabs/card_input_form.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> {
  DatabaseHelper? _dbHelper;
  bool _isInitialized = false;

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
        _isInitialized = true;
      });
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final provider = Provider.of<DatabaseProvider>(context);
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadCreditCards();
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'create',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardInputForm(
                dbHelper: _dbHelper!,
                card: null,
              ),
            ),
          );
        },
        backgroundColor: theme.colorScheme.primary,
        child: const Icon(Icons.add),
      ),
      body: Consumer<DatabaseProvider>(
        builder: (context, provider, child) {
          if (provider.creditCards.isEmpty) {
            return Center(
              child: Text(
                'No cards found',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.creditCards.length,
            itemBuilder: (context, index) {
              final card = provider.creditCards[index];
              return CreditCardItem(
                card: card,
                dbHelper: _dbHelper!,
                theme: theme,
                provider: provider,
              );
            },
          );
        },
      ),
    );
  }
}

class CreditCardItem extends StatefulWidget {
  final CreditCard card;
  final DatabaseHelper dbHelper;
  final ThemeData theme;
  final DatabaseProvider provider;

  const CreditCardItem({
    super.key,
    required this.card,
    required this.dbHelper,
    required this.theme,
    required this.provider,
  });

  @override
  CreditCardItemState createState() => CreditCardItemState();
}

class CreditCardItemState extends State<CreditCardItem> {
  bool _isSensitiveVisible = false;

  @override
  Widget build(BuildContext context) {
    final maskedNumber = _isSensitiveVisible
        ? widget.card.card_number
        : '**** **** **** ${widget.card.card_number.substring(widget.card.card_number.length - 4)}';
    final expiry = _isSensitiveVisible ? widget.card.expiry_date : '****';
    final cvv = _isSensitiveVisible ? widget.card.cvv : '***';

    return Slidable(
      key: ValueKey(widget.card.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Archive Card'),
                  content: const Text('Are you sure you want to archive this card?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Archive'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && widget.card.id != null) {
                await widget.provider.moveCreditCardToArchive(widget.card.id!);
                Fluttertoast.showToast(
                  msg: 'Card Archived',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: widget.theme.colorScheme.primary,
                  textColor: widget.theme.colorScheme.onPrimary,
                );
              }
            },
            backgroundColor: widget.theme.colorScheme.surface,
            icon: Icons.archive,
            label: 'Archive',
          ),
          SlidableAction(
            onPressed: (context) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Card'),
                  content: const Text('Are you sure you want to delete this card? It will be moved to the deleted items section.'),
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
              if (confirmed == true && widget.card.id != null) {
                await widget.provider.deleteCreditCard(widget.card.id!);
                Fluttertoast.showToast(
                  msg: 'Card Deleted',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: widget.theme.colorScheme.primary,
                  textColor: widget.theme.colorScheme.onPrimary,
                );
              }
            },
            backgroundColor: widget.theme.colorScheme.error,
            foregroundColor: widget.theme.colorScheme.onError,
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
                  builder: (context) => CardInputForm(
                    dbHelper: widget.dbHelper,
                    card: widget.card,
                  ),
                ),
              );
            },
            backgroundColor: widget.theme.colorScheme.primary,
            foregroundColor: widget.theme.colorScheme.onPrimary,
            icon: Icons.edit,
            label: 'Edit',
          ),
        ],
      ),
      child: Container(
        height: 225,
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: widget.theme.cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.only(left: 8, top: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.card.title,
              style: TextStyle(
                color: widget.theme.colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                Text(
                  maskedNumber,
                  style: TextStyle(
                    color: widget.theme.colorScheme.onSurface,
                    fontSize: 22,
                    letterSpacing: 2,
                    fontFamily: 'Courier',
                  ),
                ),
                IconButton(onPressed: () {Clipboard.setData(ClipboardData(text: widget.card.card_number));
                Fluttertoast.showToast(msg: 'Copied!',
                    gravity: ToastGravity.CENTER);},
                    icon: Icon(Icons.copy))
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
               Text(
                  'Card Holder',
                  style: TextStyle(color: widget.theme.colorScheme.onSurface, fontSize: 14),
                ),
                Row(
                  children: [
                    Text(
                      widget.card.ch_name,
                      style: TextStyle(
                        color: widget.theme.colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                        onPressed: () {Clipboard.setData(ClipboardData(text: widget.card.ch_name));
                    Fluttertoast.showToast(msg: 'Copied!',
                        gravity: ToastGravity.CENTER);},
                        icon: Icon(Icons.copy))
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Expires: ',
                      style: TextStyle(color: widget.theme.colorScheme.onSurface, fontSize: 14),
                    ),
                    Text(
                      expiry,
                      style: TextStyle(
                        color: widget.theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                        onPressed: () {Clipboard.setData(ClipboardData(text: widget.card.expiry_date));
                    Fluttertoast.showToast(msg: 'Copied!',
                        gravity: ToastGravity.CENTER);},
                        icon: Icon(Icons.copy)),
                    Text(
                      'CVV: ',
                      style: TextStyle(color: widget.theme.colorScheme.onSurface, fontSize: 14),
                    ),
                    Text(
                      cvv,
                      style: TextStyle(
                        color: widget.theme.colorScheme.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(onPressed: () {Clipboard.setData(ClipboardData(text: widget.card.cvv));
                    Fluttertoast.showToast(msg: 'Copied!',
                        gravity: ToastGravity.CENTER);},
                        icon: Icon(Icons.copy)),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: widget.theme.scaffoldBackgroundColor,
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _isSensitiveVisible = !_isSensitiveVisible;
                          });
                        },
                        icon: Icon(
                          _isSensitiveVisible
                              ? Icons.credit_card_off
                              : Icons.credit_card,
                          color: widget.theme.colorScheme.onSurface,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: widget.theme.scaffoldBackgroundColor,
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreditCardDetailsPage(card: widget.card),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.read_more_outlined,
                          color: widget.theme.colorScheme.onSurface,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}