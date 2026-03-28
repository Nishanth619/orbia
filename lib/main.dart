import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'state/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Storage must be first — every provider reads from it on construction.
  await StorageService.instance.init();

  // Preload audio assets.
  await AudioService.instance.init();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  AudioService.instance.setSfxEnabled(
    prefs.getBool(kSettingsSfxKey) ?? true,
  );
  await AudioService.instance.setMusicEnabled(
    prefs.getBool(kSettingsMusicKey) ?? true,
  );

  // Lock to portrait — arcade game is portrait-only.
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // True full-screen immersion.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  runApp(
    const ProviderScope(
      child: OrbiaApp(),
    ),
  );
}
