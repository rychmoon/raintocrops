import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:raintocrops/core/networks/network_controller.dart';
import 'package:raintocrops/core/networks/network_ui.dart';

typedef GuardedAction = Future<void> Function();

class NetworkAuthGuard {
  static Future<void> run(
      BuildContext context, {
        required GuardedAction action,
        bool showDialogOnOffline = true,
      }) async {
    final network = context.read<NetworkController>();
    final online = await network.checkNow();

    if (!online) {
      if (showDialogOnOffline) {
        await NetworkUi.showOfflineDialog(context);
      } else {
        NetworkUi.showOfflineSnackBar(context);
      }
      return;
    }

    await action();
  }
}