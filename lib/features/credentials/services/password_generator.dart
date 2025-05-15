import 'dart:math';

class PasswordGenerator {
  bool includeUppercase;
  bool includeLowercase;
  bool includeNumbers;
  bool includeSymbols;
  int passwordLength;

  PasswordGenerator({
    this.includeUppercase = false,
    this.includeLowercase = true,
    this.includeNumbers = false,
    this.includeSymbols = false,
    this.passwordLength = 12,
  });

  String generatePassword() {
    const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String numbers = '0123456789';
    const String symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeLowercase) chars += lowercase;
    if (includeUppercase) chars += uppercase;
    if (includeNumbers) chars += numbers;
    if (includeSymbols) chars += symbols;

    if (chars.isEmpty) {
      chars = lowercase; // Default to lowercase if no options are selected
    }

    final Random random = Random();
    String password = '';
    for (int i = 0; i < passwordLength; i++) {
      password += chars[random.nextInt(chars.length)];
    }

    return password;
  }
}
