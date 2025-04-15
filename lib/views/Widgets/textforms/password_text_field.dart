import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyvalut/services/password_generator.dart'; // Import the PasswordGenerator class

class PasswordManager extends StatefulWidget {
  final TextEditingController controller;
  const PasswordManager({super.key, required this.controller});

  @override
  State<PasswordManager> createState() => _PasswordManagerState();
}

class _PasswordManagerState extends State<PasswordManager> {
  bool includeUppercase = true;
  bool includeLowercase = true;
  bool includeNumbers = true;
  bool includeSpecial = true;
  int passwordLength = 8;
  bool _showPassword = false;
  late PasswordGenerator generator; // Add PasswordGenerator instance

  @override
  void initState() {
    super.initState();
    // Initialize the PasswordGenerator with the default values
    generator = PasswordGenerator(
      includeUppercase: includeUppercase,
      includeLowercase: includeLowercase,
      includeNumbers: includeNumbers,
      includeSymbols: includeSpecial,
      passwordLength: passwordLength,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller,
            style: const TextStyle(fontSize: 20),
            obscureText: !_showPassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.key),
              hintText: 'Required',
              label: const Text('Password (Required)'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(48),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 4),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove_red_eye,
                      color: _showPassword ? Theme.of(context).colorScheme.primary : Colors.grey,
                    ),
                    iconSize: 20,
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.copy, color: Theme.of(context).colorScheme.primary),
                    iconSize: 20,
                    onPressed: () {
                      if (widget.controller.text.isNotEmpty) {
                        Clipboard.setData(
                          ClipboardData(text: widget.controller.text),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Center(child: Text('Copied!')),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: includeUppercase,
                    onChanged: (bool? value) {
                      setState(() {
                        includeUppercase = value ?? false;
                        generator.includeUppercase = includeUppercase; // Update generator
                      });
                    },
                  ),
                  const Text('Uppercase'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: includeLowercase,
                    onChanged: (bool? value) {
                      setState(() {
                        includeLowercase = value ?? false;
                        generator.includeLowercase = includeLowercase; // Update generator
                      });
                    },
                  ),
                  const Text('Lowercase'),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: includeNumbers,
                    onChanged: (bool? value) {
                      setState(() {
                        includeNumbers = value ?? false;
                        generator.includeNumbers = includeNumbers; // Update generator
                      });
                    },
                  ),
                  const Text('Numbers'),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: includeSpecial,
                    onChanged: (bool? value) {
                      setState(() {
                        includeSpecial = value ?? false;
                        generator.includeSymbols = includeSpecial; // Update generator
                      });
                    },
                  ),
                  const Text('Specials'),
                ],
              ),
            ],
          ),
          Slider(
            value: passwordLength.toDouble(),
            thumbColor: Theme.of(context).colorScheme.primary,
            activeColor: Theme.of(context).colorScheme.primary,
            min: 4,
            max: 32,
            divisions: 28,
            label: passwordLength.toString(),
            onChanged: (double value) {
              setState(() {
                passwordLength = value.toInt();
                generator.passwordLength = passwordLength; // Update generator
              });
            },
          ),
          Text('Password Length: $passwordLength'),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: () {
                  // Update the generator's properties before generating the password
                  generator.includeUppercase = includeUppercase;
                  generator.includeLowercase = includeLowercase;
                  generator.includeNumbers = includeNumbers;
                  generator.includeSymbols = includeSpecial;
                  generator.passwordLength = passwordLength;

                  String generatedPassword = generator.generatePassword();
                  if (generatedPassword.isNotEmpty) {
                    setState(() {
                      widget.controller.text = generatedPassword;
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.black,
                ),
                child: const Text('Generate Password'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
