import 'package:flutter/material.dart';

class BillingAddressInput extends StatefulWidget {
  final String? initialAddress;
  final Color? fillColor;

  const BillingAddressInput({
    super.key,
    this.initialAddress,
    this.fillColor,
  });

  @override
  State<BillingAddressInput> createState() => _BillingAddressInputState();
}

class _BillingAddressInputState extends State<BillingAddressInput> {
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postalCodeController = TextEditingController();
  final countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialAddress != null) {
      // Basic parsing assuming a simple multi-line format
      final lines = widget.initialAddress!.split('\n');
      if (lines.length > 0) streetController.text = lines[0];
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fill = widget.fillColor ?? theme.cardColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildField('Street Address', streetController, fill),
        const SizedBox(height: 8),
        _buildField('City', cityController, fill),
        const SizedBox(height: 8),
        _buildField('State/Province', stateController, fill),
        const SizedBox(height: 8),
        _buildField('Postal Code', postalCodeController, fill),
        const SizedBox(height: 8),
        _buildField('Country', countryController, fill),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller, Color fill) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: fill,
      ),
    );
  }
}
