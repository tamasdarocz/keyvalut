import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

enum AuthMode { pin, password }

class AppException implements Exception {
  final String message;
  AppException(this.message);
}

// Utility to show toast messages
void showToast(String message, {Color backgroundColor = Colors.red, Color textColor = Colors.white}) {
  Fluttertoast.showToast(
    msg: message,
    gravity: ToastGravity.CENTER,
    toastLength: Toast.LENGTH_SHORT,
    backgroundColor: backgroundColor,
    textColor: textColor,
  );
}

// Centralized error handling
void handleError(Object e) {
  final message = e is AppException ? e.message : 'Error: $e';
  showToast(message);
}

// Validate PIN or password input
void validateInput(String input, AuthMode authMode) {
  if (authMode == AuthMode.pin) {
    if (input.length < 6 || !RegExp(r'^\d+$').hasMatch(input)) {
      throw AppException('PIN must be at least 6 digits');
    }
  } else {
    if (input.length < 8) {
      throw AppException('Password must be at least 8 characters');
    }
  }
}

// Fetch database names from storage
Future<List<String>> fetchDatabaseNames() async {
  final directory = await getApplicationDocumentsDirectory();
  return directory
      .listSync()
      .where((file) => file.path.endsWith('.db') && file is File)
      .map((file) => file.path.split('/').last.replaceAll('.db', ''))
      .toList();
}