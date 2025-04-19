import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../data/credential_provider.dart';
import '../../data/database_helper.dart';
import '../../data/credential_model.dart';
import '../screens/credit_card_details_page.dart';
import '../textforms/card_input_form.dart';


class CardListView extends StatelessWidget {
  const CardListView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CredentialProvider>(context);
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      provider.loadCreditCards();
    });

    return Consumer<CredentialProvider>(
      builder: (context, provider, child) {
        if (provider.creditCards.isEmpty) {
          return Center(
              child: Text('No cards found',
                  style: TextStyle(color: theme.colorScheme.onSurface)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: provider.creditCards.length,
          itemBuilder: (context, index) {
            final card = provider.creditCards[index];
            return CreditCardItem(card: card);
          },
        );
      },
    );
  }
}

class CreditCardItem extends StatefulWidget {
  final CreditCard card;

  const CreditCardItem({super.key, required this.card});

  @override
  _CreditCardItemState createState() => _CreditCardItemState();
}

class _CreditCardItemState extends State<CreditCardItem> {
  bool _isSensitiveVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<CredentialProvider>(context, listen: false);
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
                await provider.moveCreditCardToArchive(widget.card.id!);
                Fluttertoast.showToast(
                  msg: 'Card Archived',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  backgroundColor: theme.colorScheme.primary,
                  textColor: theme.colorScheme.onPrimary,
                );
              }
            },
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
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
                await provider.deleteCreditCard(widget.card.id!);
                Fluttertoast.showToast(
                  msg: 'Card Moved to Deleted Items',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.TOP,
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
                  builder: (context) => CardInputForm(
                    dbHelper: DatabaseHelper.instance,
                    card: widget.card,
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
      child: Container(
        height: 200,
        margin: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.blueGrey.shade600, // Solid color matching CreditCardDetailsPage
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.card.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              maskedNumber,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                letterSpacing: 2,
                fontFamily: 'Courier',
              ),
            ),
            const SizedBox(height: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Card Holder',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  widget.card.ch_name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Expires ',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      expiry,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      'CCV ',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Text(
                      cvv,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 60),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CreditCardDetailsPage(card: widget.card),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.read_more_outlined,
                          color: Colors.white,
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