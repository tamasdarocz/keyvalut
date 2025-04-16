import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:keyvalut/data/credentialProvider.dart';
import 'package:keyvalut/views/Tabs/qr_scanner.dart'; // Placeholder for QR scanner integration if needed

class CreateCreditCardForm extends StatefulWidget {
  final Map<String, dynamic>? creditCard;
  const CreateCreditCardForm({super.key, this.creditCard});

  @override
  _CreateCreditCardFormState createState() => _CreateCreditCardFormState();
}

class _CreateCreditCardFormState extends State<CreateCreditCardForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardholderNameController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.creditCard != null) {
      _cardholderNameController.text = widget.creditCard!['cardholderName'];
      _cardNumberController.text = widget.creditCard!['cardNumber'];
      _expiryDateController.text = widget.creditCard!['expiryDate'];
      _cvvController.text = widget.creditCard!['cvv'];
    }
  }

  @override
  void dispose() {
    _cardholderNameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  bool get _isValid {
    return _cardholderNameController.text.isNotEmpty &&
        _cardNumberController.text.isNotEmpty &&
        _expiryDateController.text.isNotEmpty &&
        _cvvController.text.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.creditCard != null ? 'Edit Credit Card' : 'Add Credit Card'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextFormField(
                controller: _cardholderNameController,
                decoration: const InputDecoration(labelText: 'Cardholder Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(labelText: 'Card Number'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _expiryDateController,
                decoration: const InputDecoration(labelText: 'Expiry Date (MM/YY)'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _cvvController,
                decoration: const InputDecoration(labelText: 'CVV'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final creditCard = {
                      'id': widget.creditCard?['id'],
                      'cardholderName': _cardholderNameController.text,
                      'cardNumber': _cardNumberController.text,
                      'expiryDate': _expiryDateController.text,
                      'cvv': _cvvController.text,
                    };
                    final provider = Provider.of<CredentialProvider>(context, listen: false);
                    if (widget.creditCard != null) {
                      await provider.updateCreditCard(creditCard);
                    } else {
                      await provider.addCreditCard(creditCard);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(widget.creditCard != null ? 'Update' : 'Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}