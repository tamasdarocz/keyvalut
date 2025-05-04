import 'package:flutter/material.dart';

class PeriodDropdown extends StatelessWidget {
  final ValueNotifier<String?> periodNotifier;

  const PeriodDropdown({
    super.key,
    required this.periodNotifier,
  });

  @override
  Widget build(BuildContext context) {
    if (periodNotifier.value == null) {
      periodNotifier.value = 'None';
  }
    return ValueListenableBuilder<String?>(
      valueListenable: periodNotifier,
      builder: (context, period, child) {
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Period',
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
          ),
          value: period,
          items: const [
            DropdownMenuItem<String>(
              value: "None",
              child: Text('None'),
            ),
            DropdownMenuItem<String>(
              value: "Weekly",
              child: Text('Weekly'),
            ),
            DropdownMenuItem<String>(
              value: "Monthly",
              child: Text('Monthly'),
            ),
            DropdownMenuItem<String>(
              value: "Yearly",
              child: Text('Yearly'),
            ),
          ],
          onChanged: (value) => periodNotifier.value = value,
        );
      },
    );
  }
}
