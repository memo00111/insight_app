import 'package:flutter/material.dart';
import '../providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'dart:io';

/// Helper class for handling network errors and showing appropriate messages
class NetworkErrorHelper {
  /// Shows an appropriate error message based on the error type
  static void handleError(
    BuildContext context,
    Object error,
    String defaultMessage,
    Function onRetry,
  ) {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final bool isOnline = appProvider.isOnline;
    String message = defaultMessage;

    if (!isOnline) {
      message = 'أنت غير متصل بالإنترنت. يرجى التحقق من اتصالك والمحاولة مرة أخرى.';
    } else if (error is SocketException || error.toString().contains('SocketException')) {
      message = 'تعذر الاتصال بالخادم. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
    } else if (error.toString().contains('timeout')) {
      message = 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('خطأ في الاتصال'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              !isOnline ? Icons.wifi_off : Icons.error_outline,
              size: 48,
              color: !isOnline ? Colors.orange : Colors.red,
            ),
            SizedBox(height: 16),
            Text(message),
            if (!isOnline) ...[
              SizedBox(height: 8),
              Text(
                'يمكنك استخدام بعض الميزات دون اتصال بالإنترنت.',
                style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('إغلاق'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// Shows a snackbar with an appropriate message based on network status
  static void showNetworkStatusSnackBar(BuildContext context, bool isConnected) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isConnected 
            ? 'تم استعادة الاتصال بالإنترنت' 
            : 'أنت الآن غير متصل بالإنترنت. بعض الميزات قد لا تعمل',
        ),
        backgroundColor: isConnected ? Colors.green : Colors.orange,
        duration: Duration(seconds: 3),
        action: isConnected ? null : SnackBarAction(
          label: 'حسناً',
          onPressed: () {},
        ),
      ),
    );
  }
}
