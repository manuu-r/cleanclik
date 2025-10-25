import 'package:flutter/material.dart';

/// AR-specific theme configuration
class ARTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color overlayColor;

  const ARTheme({
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.green,
    this.backgroundColor = Colors.black,
    this.overlayColor = Colors.white,
  });

  static const ARTheme defaultTheme = ARTheme();
}
