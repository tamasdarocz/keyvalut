import 'package:flutter/material.dart';

class BillingAddressInput extends StatefulWidget {
  final String? initialAddress;

  const BillingAddressInput({
    super.key,
    this.initialAddress,
  });

  @override
  State<BillingAddressInput> createState() => BillingAddressInputState();
}

class BillingAddressInputState extends State<BillingAddressInput> {
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      final lines = widget.initialAddress!.split('\n');
      if (lines.isNotEmpty) streetController.text = lines[0];
      if (lines.length > 1) cityController.text = lines[1];
      if (lines.length > 2) stateController.text = lines[2];
      if (lines.length > 3) postalCodeController.text = lines[3];
      if (lines.length > 4) countryController.text = lines[4];
    }
  }

  @override
  void dispose() {
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    postalCodeController.dispose();
    countryController.dispose();
    super.dispose();
  }

  /// Public method to get the combined billing address string.
  String getFormattedAddress() {
    return [
      streetController.text,
      cityController.text,
      stateController.text,
      postalCodeController.text,
      countryController.text,
    ].where((part) => part.isNotEmpty).join('\n');
  }

  /// Validates the form and returns true if valid.

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Billing address',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const Divider(),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: countryController,
                decoration: InputDecoration(
                  labelText: 'Country',
                  labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: stateController,
                decoration: InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextFormField(
                controller: postalCodeController,
                decoration: InputDecoration(
                  labelText: 'Postal Code',
                  border: OutlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: streetController,
          decoration: InputDecoration(
            labelText: 'Street Address',
            border: OutlineInputBorder(
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 1)
            ),
          ),
        ),
        const SizedBox(height: 4),
        const Divider(),
      ],
    );
  }
}