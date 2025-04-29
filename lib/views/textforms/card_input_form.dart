import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyvalut/views/textforms/billing_adress_input_form.dart';
import '../../data/database_helper.dart';
import '../../data/database_model.dart';
import '../Widgets/top_message.dart';

class CardInputForm extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final CreditCard? card;

  const CardInputForm({
    super.key,
    required this.dbHelper,
    this.card,
  });

  @override
  _CardInputFormState createState() => _CardInputFormState();
}

class _CardInputFormState extends State<CardInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _chNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardTypeController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.card != null) {
      _titleController.text = widget.card!.title;
      _bankNameController.text = widget.card!.bank_name ?? '';
      _chNameController.text = widget.card!.ch_name;
      _cardNumberController.text = widget.card!.card_number;
      _expiryDateController.text = widget.card!.expiry_date;
      _cvvController.text = widget.card!.cvv;
      _cardTypeController.text = widget.card!.card_type ?? '';
      _billingAddressController.text = widget.card!.billing_address ?? '';
      _notesController.text = widget.card!.notes ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bankNameController.dispose();
    _chNameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _cardTypeController.dispose();
    _billingAddressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveCard() async {
    if (_formKey.currentState!.validate()) {
      final card = CreditCard(
        id: widget.card?.id,
        title: _titleController.text,
        bank_name: _bankNameController.text.isNotEmpty ? _bankNameController.text : null,
        ch_name: _chNameController.text,
        card_number: _cardNumberController.text,
        expiry_date: _expiryDateController.text,
        cvv: _cvvController.text,
        card_type: _cardTypeController.text.isNotEmpty ? _cardTypeController.text : null,
        billing_address: _billingAddressController.text.isNotEmpty ? _billingAddressController.text : null,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        isArchived: widget.card?.isArchived ?? false,
        archivedAt: widget.card?.archivedAt,
      );

      try {
        if (widget.card == null) {
          await widget.dbHelper.insertCreditCard(card);
        } else {
          await widget.dbHelper.updateCreditCard(card);
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        TopMessage.show(
          context: context,
          message: 'Failed to save card',
          backgroundColor: Theme.of(context).colorScheme.error,
          textColor: Theme.of(context).colorScheme.onError,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card == null ? 'Add Card' : 'Edit Card'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              SizedBox(height: 12,),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Required',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _chNameController,
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'Required',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter cardholder name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: 'Required',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Enter card number';
                  if (value.length != 16) return 'Must be 16 digits';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: TextFormField(
                        textAlign: TextAlign.center,
                        controller: _expiryDateController,
                        decoration: InputDecoration(
                          labelText: 'Expiry (MM/YY)',
                          hintText: 'Required',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: theme.cardColor,
                        ),
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                          LengthLimitingTextInputFormatter(5),
                          _ExpiryDateFormatter(),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter expiry';
                          if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(value)) {
                            return 'Use MM/YY';
                          }
                          return null;
                        },
                      ),
                  ),
                  const SizedBox(width: 12),
                   Flexible(
                     flex: 2,
                     child: TextFormField(
                        textAlign: TextAlign.center,
                        controller: _cvvController,
                        decoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: 'Required',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: theme.cardColor,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Enter CVV';
                          if (value.length != 3) return 'Must be 3 digits';
                          return null;
                        },
                      ),
                   ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: TextFormField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          labelText: 'Bank Name',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: theme.cardColor,
                        ),
                      ),
                  ),
                 SizedBox(width: 12),
                 Flexible(
                   flex: 1,
                   child: TextFormField(
                        textAlign: TextAlign.center,
                        controller: _cardTypeController,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: theme.cardColor,
                        ),
                      ),
                 ),

                ],
              ),
              const SizedBox(height: 12),
              BillingAddressInput(),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveCard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: Text(widget.card == null ? 'Save' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text;
    if (text.length == 2 && oldValue.text.length < 2) {
      text += '/';
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}