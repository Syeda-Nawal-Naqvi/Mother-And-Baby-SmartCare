import 'package:flutter/widgets.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final void Function(bool resumed) onStateChanged;

  AppLifecycleObserver({required this.onStateChanged});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged(state == AppLifecycleState.resumed);
  }
}
