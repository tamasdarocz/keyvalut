import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:keyvalut/data/database_helper.dart';

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
  final files = await directory.list().toList();
  final databaseFiles = files
      .where((file) => file is File && file.path.endsWith('.db'))
      .map((file) => file.path.split(Platform.pathSeparator).last.replaceAll('.db', ''))
      .toList();

  print('fetchDatabaseNames - Found database files: $databaseFiles'); // Detailed log

  // Check if 'default' is in the list and log a stack trace if found
  if (databaseFiles.contains('default')) {
    print('fetchDatabaseNames - "default" database found at: ${StackTrace.current}');
  }

  return databaseFiles;
}