import 'package:flutter/material.dart';
import 'package:keyvalut/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class SettingsMenu extends StatelessWidget {
  const SettingsMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Select Theme'),
                trailing: DropdownButton<AppTheme>(
                  value: themeProvider.currentTheme,
                  onChanged: (AppTheme? newTheme) {
                    if (newTheme != null) {
                      themeProvider.setTheme(newTheme);
                    }
                  },
                  items: AppTheme.values.map((AppTheme theme) {
                    return DropdownMenuItem<AppTheme>(
                      value: theme,
                      child: Text(theme.toString().split('.').last),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}