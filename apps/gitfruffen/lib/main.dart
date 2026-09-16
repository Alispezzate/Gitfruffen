import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow(
    const WindowOptions(
      size: Size(1440, 900),
      minimumSize: Size(1024, 640),
      center: true,
      title: 'Gitfruffen',
    ),
    () => windowManager.show(),
  );

  final preferences = await SharedPreferences.getInstance();

  runApp(App(preferences: preferences));
}
