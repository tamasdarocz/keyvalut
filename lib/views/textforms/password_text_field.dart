import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:keyvalut/services/password_generator.dart'; // Ensure this path matches your project

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
  late PasswordGenerator generator;

  @override
  void initState() {
    super.initState();
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
            obscureText: !_showPassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.key),
              hintText: 'Required',
              label: const Text('Password (Required)'),
              border: OutlineInputBorder(
                borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary, width: 1),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility : Icons.visibility_off,
                      color: _showPassword
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.copy,
                        color: Theme.of(context).colorScheme.primary),
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
          // First row: Uppercase and Lowercase ChoiceChips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ChoiceChip(
                label: const Text('A-Z'),
                selected: includeUppercase,
                onSelected: (bool selected) {
                  setState(() {
                    includeUppercase = selected;
                    generator.includeUppercase = includeUppercase;
                  });
                },
                selectedColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: includeUppercase
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              ChoiceChip(
                label: const Text('a-z'),
                selected: includeLowercase,
                onSelected: (bool selected) {
                  setState(() {
                    includeLowercase = selected;
                    generator.includeLowercase = includeLowercase;
                  });
                },
                selectedColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: includeLowercase
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              ChoiceChip(
                label: const Text('0-9'),
                selected: includeNumbers,
                onSelected: (bool selected) {
                  setState(() {
                    includeNumbers = selected;
                    generator.includeNumbers = includeNumbers;
                  });
                },
                selectedColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: includeNumbers
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
              ),
              ChoiceChip(
                label: const Text('@#\$'),
                selected: includeSpecial,
                onSelected: (bool selected) {
                  setState(() {
                    includeSpecial = selected;
                    generator.includeSymbols = includeSpecial;
                  });
                },
                selectedColor:
                    Theme.of(context).colorScheme.primary.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: includeSpecial
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey,
                ),
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
                generator.passwordLength = passwordLength;
              });
            },
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Text('Password Length: $passwordLength'),
              ElevatedButton(
                onPressed: () {
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
