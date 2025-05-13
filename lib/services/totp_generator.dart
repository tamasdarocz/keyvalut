import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class TOTPGenerator {
  static String generateTOTP(String base32Secret, {int period = 30, int digits = 6}) {
    final secretBytes = base32Decode(base32Secret);

    final time = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;

    var counter = time ~/ period;

    final counterBytes = Uint8List(8);
    for (int i = 7; i >= 0; i--) {
      counterBytes[i] = counter & 0xFF;
      counter >>= 8;
    }

    final hmac = Hmac(sha1, secretBytes);
    final hash = hmac.convert(counterBytes).bytes;

    final offset = hash[hash.length - 1] & 0x0F;
    final binary = ((hash[offset] & 0x7F) << 24) |
    ((hash[offset + 1] & 0xFF) << 16) |
    ((hash[offset + 2] & 0xFF) << 8) |
    (hash[offset + 3] & 0xFF);

    final code = (binary % 1000000).toString().padLeft(digits, '0');

    return code;
  }

  static Uint8List base32Decode(String input) {
    const base32Alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    input = input.replaceAll('=', '').toUpperCase().trim();
    if (input.isEmpty || !RegExp(r'^[A-Z2-7]+$').hasMatch(input)) {
      throw const FormatException('Invalid base32 secret: Only A-Z and 2-7 are allowed');
    }
    var bits = '';
    for (var char in input.split('')) {
      var value = base32Alphabet.indexOf(char);
      if (value == -1) {
        throw const FormatException('Invalid character in base32 secret');
      }
      bits += value.toRadixString(2).padLeft(5, '0');
    }
    var bytes = <int>[];
    for (var i = 0; i < bits.length - (bits.length % 8); i += 8) {
      var byte = bits.substring(i, i + 8);
      bytes.add(int.parse(byte, radix: 2));
    }
    return Uint8List.fromList(bytes);
  }

  static int getRemainingSeconds({int period = 30}) {
    final time = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return period - (time % period);
  }
}