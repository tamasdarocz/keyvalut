import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../main.dart';

const secureStorage = FlutterSecureStorage();

Future<List<int>> _getEncryptionKey() async {
  final encryptionKey = await secureStorage.read(key: 'hive_encryption_key');

  if (encryptionKey == null) {
    // Generate a new key if none exists
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'hive_encryption_key',
      value: base64UrlEncode(key),
    );
    return key;
  }

  return base64Url.decode(encryptionKey);
}
