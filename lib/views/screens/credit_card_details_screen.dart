import 'package:flutter/material.dart';
import '../../data/database_model.dart';

class CreditCardDetailsPage extends StatefulWidget {
  final CreditCard card;

  const CreditCardDetailsPage({super.key, required this.card});

  @override
  _CreditCardDetailsPageState createState() => _CreditCardDetailsPageState();
}

class _CreditCardDetailsPageState extends State<CreditCardDetailsPage> {
  bool _isSensitiveVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maskedNumber = _isSensitiveVisible
        ? widget.card.card_number
        : '**** **** **** ${widget.card.card_number.substring(widget.card.card_number.length - 4)}';
    final expiry = _isSensitiveVisible ? widget.card.expiry_date : '****';
    final cvv = _isSensitiveVisible ? widget.card.cvv : '***';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.title),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Container
            Container(
              margin: const EdgeInsets.all(8),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.blueGrey.shade600, // Match the screenshot background color
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(8),
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
                          const Spacer(),
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
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.card.card_type != null) ...[
                    const Text(
                      'Card Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.card.card_type!,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (widget.card.billing_address != null) ...[
                    const Text(
                      'Billing Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.card.billing_address!,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (widget.card.notes != null) ...[
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.card.notes!,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}