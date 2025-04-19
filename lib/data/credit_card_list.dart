import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../data/credential_provider.dart';
import '../../data/database_helper.dart';
import '../../data/credential_model.dart';
import '../views/Widgets/top_message.dart';
import '../views/textforms/card_input_form.dart';

class CreditCardList extends StatelessWidget {
  const CreditCardList({super.key});

  @override
  Widget build(BuildContext context) {
    final credentialProvider = Provider.of<CredentialProvider>(context);
    final theme = Theme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      credentialProvider.loadCreditCards();
    });

    return Consumer<CredentialProvider>(
      builder: (context, provider, child) {
        if (provider.creditCards.isEmpty) {
          return Center(child: Text('No credit cards found', style: TextStyle(color: theme.colorScheme.onSurface)));
        }

        return ListView.builder(
          itemCount: provider.creditCards.length,
          itemBuilder: (context, index) {
            final card = provider.creditCards[index];
            final maskedNumber = '**** **** **** ${card.card_number.substring(card.card_number.length - 4)}';

            return Slidable(
              key: ValueKey(card.id),
              startActionPane: ActionPane(
                motion: const ScrollMotion(),
                children: [
                  SlidableAction(
                    onPressed: (context) async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Credit Card'),
                          content: const Text('Are you sure you want to delete this card?'),
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
                      if (confirmed == true && card.id != null) {
                        await provider.deleteCreditCard(card.id!);
                        TopMessage.show(
                          context: context,
                          message: 'Card deleted',
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
                            card: card, // Changed from creditCard to card
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
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ExpansionTile(
                    backgroundColor: Colors.transparent,
                    leading: Icon(
                      card.card_type?.toLowerCase() == 'visa' ? Icons.credit_card : Icons.credit_card_outlined,
                      color: theme.colorScheme.onPrimary,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            card.ch_name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          maskedNumber,
                          style: TextStyle(
                            fontSize: 16,
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      card.title,
                      style: TextStyle(color: theme.colorScheme.onPrimary.withOpacity(0.8)),
                    ),
                    children: [
                      Container(
                        color: theme.cardColor,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (card.bank_name != null && card.bank_name!.isNotEmpty)
                              _buildDetailRow(context, 'Bank', card.bank_name!),
                            _buildDetailRow(context, 'Card Number', card.card_number, isSensitive: true),
                            _buildDetailRow(context, 'Expiry Date', card.expiry_date, isSensitive: true),
                            _buildDetailRow(context, 'CVV', card.cvv, isSensitive: true),
                            if (card.card_type != null && card.card_type!.isNotEmpty)
                              _buildDetailRow(context, 'Card Type', card.card_type!),
                            if (card.billing_address != null && card.billing_address!.isNotEmpty)
                              _buildDetailRow(context, 'Billing Address', card.billing_address!),
                            if (card.notes != null && card.notes!.isNotEmpty)
                              _buildDetailRow(context, 'Notes', card.notes!),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isSensitive = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: isSensitive
                ? _SensitiveText(value: value, theme: theme)
                : Text(
              value,
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 20, color: theme.colorScheme.onSurface),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              TopMessage.show(
                context: context,
                message: '$label copied!',
                backgroundColor: theme.colorScheme.primary,
                textColor: theme.colorScheme.onPrimary,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SensitiveText extends StatefulWidget {
  final String value;
  final ThemeData theme;

  const _SensitiveText({required this.value, required this.theme});

  @override
  _SensitiveTextState createState() => _SensitiveTextState();
}

class _SensitiveTextState extends State<_SensitiveText> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          _isVisible ? widget.value : '****',
          style: TextStyle(color: widget.theme.colorScheme.onSurface),
        ),
        IconButton(
          icon: Icon(
            _isVisible ? Icons.visibility_off : Icons.visibility,
            size: 20,
            color: widget.theme.colorScheme.onSurface,
          ),
          onPressed: () {
            setState(() {
              _isVisible = !_isVisible;
            });
          },
        ),
      ],
    );
  }
}