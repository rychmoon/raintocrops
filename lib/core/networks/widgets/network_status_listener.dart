import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../network_controller.dart';
import '../network_service.dart';
import '../network_ui.dart';

class NetworkStatusListener extends StatefulWidget {
  final Widget child;
  const NetworkStatusListener({super.key, required this.child});

  @override
  State<NetworkStatusListener> createState() => _NetworkStatusListenerState();
}

class _NetworkStatusListenerState extends State<NetworkStatusListener> {
  NetworkStatus? _prev;
  bool _dialogOpen = false;

  @override
  Widget build(BuildContext context) {
    final status = context.watch<NetworkController>().status;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      // first build: just cache state
      if (_prev == null) {
        _prev = status;
        return;
      }

      // online -> offline
      if (_prev == NetworkStatus.online && status == NetworkStatus.offline) {
        NetworkUi.showOfflineSnackBar(context); // optional
        if (!_dialogOpen) {
          _dialogOpen = true;
          await NetworkUi.showOfflineDialog(context);
          _dialogOpen = false;
        }
      }

      // offline -> online
      if (_prev == NetworkStatus.offline && status == NetworkStatus.online) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Back online'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }

      _prev = status;
    });

    return widget.child;
  }
}