import 'package:flutter/material.dart';

class GlobalSnackbar {

  static void _show(
      BuildContext context, {
        required String message,
        required Color color,
        required IconData icon,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void general(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: const Color(0xFF323232),
      icon: Icons.info_outline,
    );
  }

  static void success(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: Colors.green,
      icon: Icons.check_circle,
    );
  }

  static void error(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: Colors.red,
      icon: Icons.error,
    );
  }

  static void warning(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: Colors.orange,
      icon: Icons.warning,
    );
  }

  static void info(BuildContext context, String message) {
    _show(
      context,
      message: message,
      color: Colors.blue,
      icon: Icons.info,
    );
  }
}