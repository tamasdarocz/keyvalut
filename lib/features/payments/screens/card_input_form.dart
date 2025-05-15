import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:keyvalut/core/model/database_model.dart';
import 'package:keyvalut/core/services/database_helper.dart';
import 'package:keyvalut/features/shared/widgets/billing_address_input_form.dart';
import 'package:keyvalut/features/shared/widgets/title_input_field.dart';


class CardInputForm extends StatefulWidget {
  final DatabaseHelper dbHelper;
  final CreditCard? card;

  const CardInputForm({
    super.key,
    required this.dbHelper,
    this.card,
  });

  @override
  CardInputFormState createState() {
    return CardInputFormState();
  }
}

class CardInputFormState extends State<CardInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _chNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCardType; // To store the dropdown value

  // Key to access the BillingAddressInput state
  final _billingAddressKey = GlobalKey<BillingAddressInputState>();

  // List of card types for the dropdown
  final List<String> _cardTypes = [
    'Mastercard',
    'Visa',
    'Virtual',
    'American Express',
    'Discover',
    'Diners Club',
    'JCB',
    'UnionPay',
  ];

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
      _selectedCardType = widget.card!.card_type; // Prefill dropdown
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
        card_type: _selectedCardType, // Use dropdown value
        billing_address: _billingAddressKey.currentState!.getFormattedAddress().isNotEmpty
            ? _billingAddressKey.currentState!.getFormattedAddress()
            : null,
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
        Fluttertoast.showToast(msg: 'Failed to save card', gravity: ToastGravity.CENTER );
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
              const SizedBox(height: 12),
              TitleInputField(controller: _titleController),
              const SizedBox(height: 12),
              TextFormField(
                controller: _chNameController,
                decoration: InputDecoration(
                  labelText: 'Cardholder Name',
                  hintText: 'Required',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Enter cardholder name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cardNumberController,
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  hintText: 'Required',
                  border: const OutlineInputBorder(),
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
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.datetime,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[\d/]')),
                        LengthLimitingTextInputFormatter(5),
                        _ExpiryDateFormatter(),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Enter expiry';
                        if (!RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(value)) {
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
                        border: const OutlineInputBorder(),
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
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCardType,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        border: const OutlineInputBorder(),
                      ),
                      items: _cardTypes.map((String type) {
                        return DropdownMenuItem<String>(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCardType = newValue;
                        });
                      },
                      isExpanded: true, // Ensures the dropdown takes full width
                      hint: const Text('Select Type'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BillingAddressInput(
                key: _billingAddressKey,
                initialAddress: widget.card?.billing_address,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: const OutlineInputBorder(),
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