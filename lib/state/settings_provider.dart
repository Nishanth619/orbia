import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kSettingsSfxKey = 'settings_sfx';
const String kSettingsMusicKey = 'settings_music';
const String kSettingsHapticsKey = 'settings_haptics';

final class SettingsState {
  const SettingsState({
    required this.sfxEnabled,
    required this.musicEnabled,
    required this.hapticsEnabled,
  });

  factory SettingsState.defaults() => const SettingsState(
      sfxEnabled: true, musicEnabled: true, hapticsEnabled: true);

  final bool sfxEnabled;
  final bool musicEnabled;
  final bool hapticsEnabled;

  SettingsState copyWith(
          {bool? sfxEnabled, bool? musicEnabled, bool? hapticsEnabled}) =>
      SettingsState(
        sfxEnabled: sfxEnabled ?? this.sfxEnabled,
        musicEnabled: musicEnabled ?? this.musicEnabled,
        hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      );
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(SettingsState.defaults()) {
    _load();
  }

  SharedPreferences? _prefs;

  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      sfxEnabled: _prefs!.getBool(kSettingsSfxKey) ?? true,
      musicEnabled: _prefs!.getBool(kSettingsMusicKey) ?? true,
      hapticsEnabled: _prefs!.getBool(kSettingsHapticsKey) ?? true,
    );
  }

  Future<void> toggleSfx() async {
    final bool next = !state.sfxEnabled;
    await _prefs?.setBool(kSettingsSfxKey, next);
    state = state.copyWith(sfxEnabled: next);
  }

  Future<void> toggleMusic() async {
    final bool next = !state.musicEnabled;
    await _prefs?.setBool(kSettingsMusicKey, next);
    state = state.copyWith(musicEnabled: next);
  }

  Future<void> toggleHaptics() async {
    final bool next = !state.hapticsEnabled;
    await _prefs?.setBool(kSettingsHapticsKey, next);
    state = state.copyWith(hapticsEnabled: next);
  }
}

final StateNotifierProvider<SettingsNotifier, SettingsState> settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>(
        (_) => SettingsNotifier());
