import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../utils/network_error_helper.dart';

/// ويدجت لمراقبة حالة الاتصال وعرض شريط تنبيه عند تغير الاتصال
class ConnectionMonitor extends StatefulWidget {
  final Widget child;
  
  const ConnectionMonitor({super.key, required this.child});

  @override
  State<ConnectionMonitor> createState() => _ConnectionMonitorState();
}

class _ConnectionMonitorState extends State<ConnectionMonitor> {
  bool? _previousConnectionState;
  
  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, _) {
        bool isOnline = appProvider.isOnline;
        
        // إظهار شريط التنبيه فقط عند تغير حالة الاتصال
        if (_previousConnectionState != null && _previousConnectionState != isOnline) {
          // تأخير قصير لضمان بناء الواجهة قبل عرض التنبيه
          WidgetsBinding.instance.addPostFrameCallback((_) {
            NetworkErrorHelper.showNetworkStatusSnackBar(context, isOnline);
          });
        }
        
        // تحديث حالة الاتصال السابقة
        _previousConnectionState = isOnline;
        
        return widget.child;
      },
    );
  }
}
