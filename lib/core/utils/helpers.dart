import 'package:flutter/material.dart';

class Helpers {
  Helpers._();

  static void showSnackBar(
    BuildContext context,
    String message, {
    Color? backgroundColor,
  }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: backgroundColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  static String formatCurrency(num amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  static String formatKg(num weight) {
    return '${weight.toStringAsFixed(1)} kg';
  }

  static String formatCount(int count, String singularWord) {
    if (count == 1) {
      return '1 $singularWord';
    }
    return '$count ${singularWord}s';
  }

  static String getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || name.trim().isEmpty) {
      return '';
    }

    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }

    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
