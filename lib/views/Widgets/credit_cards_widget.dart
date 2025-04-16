import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keyvalut/data/credentialProvider.dart';
import 'create_credit_card_form.dart';

class CreditCardsWidget extends StatefulWidget {
  const CreditCardsWidget({super.key});

  @override
  _CreditCardsWidgetState createState() => _CreditCardsWidgetState();
}

class _CreditCardsWidgetState extends State<CreditCardsWidget> {
  Map<int, bool> _revealMap = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CredentialProvider>(context, listen: false).loadCreditCards();
    });
  }

  void _toggleReveal(int id) {
    setState(() {
      _revealMap[id] = !(_revealMap[id] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CredentialProvider>(
      builder: (context, provider, child) {
        if (provider.creditCards.isEmpty) {
          return const Center(child: Text('No credit cards found'));
        }
        return ListView.builder(
          itemCount: provider.creditCards.length,
          itemBuilder: (context, index) {
            final creditCard = provider.creditCards[index];
            final isRevealed = _revealMap[creditCard['id']] ?? false;
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(creditCard['cardholderName']),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Card Number: ${isRevealed ? creditCard['cardNumber'] : '•••• •••• •••• ••••'}'),
                    Text('Expiry: ${isRevealed ? creditCard['expiryDate'] : '••/••'}'),
                    Text('CVV: ${isRevealed ? creditCard['cvv'] : '•••'}'),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(
                    isRevealed ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => _toggleReveal(creditCard['id']),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CreateCreditCardForm(creditCard: creditCard),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}