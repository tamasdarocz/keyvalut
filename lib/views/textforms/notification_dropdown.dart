import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class NotificationDropdown extends StatelessWidget {
  final ValueNotifier<String?> notificationSetting;

  const NotificationDropdown({
    super.key,
    required this.notificationSetting,
  });

  @override
  Widget build(BuildContext context) {
    // Set a default value if null to avoid UI issues
    if (notificationSetting.value == null) {
      notificationSetting.value = 'Disabled';
    }

    return ValueListenableBuilder<String?>(
      valueListenable: notificationSetting,
      builder: (context, setting, child) {
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Billing Notification',
            prefixIcon: const Icon(Icons.notifications),
            border: OutlineInputBorder(
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1,
              ),
            ),
          ),
          value: setting,
          items: const [
            DropdownMenuItem<String>(
              value: "Disabled",
              child: Text('Disabled'),
            ),
            DropdownMenuItem<String>(
              value: "1 day before",
              child: Text('1 day before'),
            ),
            DropdownMenuItem<String>(
              value: "2 days before",
              child: Text('2 days before'),
            ),
          ],
          onChanged: (value) {
            notificationSetting.value = value;
          },
        );
      },
    );
  }
}