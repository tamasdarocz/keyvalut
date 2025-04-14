import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  void dispose() {
    super.dispose();
  }

  String generatePassword() {
    String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    String numbers = '0123456789';
    String special = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeUppercase) chars += uppercase;
    if (includeLowercase) chars += lowercase;
    if (includeNumbers) chars += numbers;
    if (includeSpecial) chars += special;

    if (chars.isEmpty) return '';

    String password = '';
    Random random = Random();
    for (int i = 0; i < passwordLength; i++) {
      int randomIndex = random.nextInt(chars.length);
      password += chars[randomIndex];
    }

    return password;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: widget.controller, // Use the passed controller
            style: const TextStyle(fontSize: 20),
            obscureText: !_showPassword,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.key),
              hintText: 'Required',
              label: const Text('Password (Required)'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(48),
                borderSide: const BorderSide(color: Colors.amber, width: 4),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.remove_red_eye,
                      color: _showPassword ? Colors.amber : Colors.grey,
                    ),
                    iconSize: 20,
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.amber),
                    iconSize: 20,
                    onPressed: () {
                      if (widget.controller.text.isNotEmpty) {
                        // Use widget.controller
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
            thumbColor: Colors.amber,
            activeColor: Colors.amber,
            min: 4,
            max: 32,
            divisions: 28,
            label: passwordLength.toString(),
            onChanged: (double value) {
              setState(() {
                passwordLength = value.toInt();
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
                  String generatedPassword = generatePassword();
                  if (generatedPassword.isNotEmpty) {
                    setState(() {
                      widget.controller.text =
                          generatedPassword; // Update the passed controller
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
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
