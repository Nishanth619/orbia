import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  AudioService._();
  static final AudioService instance = AudioService._();

  bool sfxEnabled = true;
  bool musicEnabled = true;
  bool _bgMusicReady = false;
  bool _tapReady = false;
  bool _deathReady = false;
  bool _coinReady = false;

  static const String _bgMusic = 'music/bg_loop.ogg';
  static const String _tapSfx = 'sfx/tap.ogg';
  static const String _deathSfx = 'sfx/death.ogg';
  static const String _coinSfx = 'sfx/coin.ogg';

  Future<void> init() async {
    _bgMusicReady = await _tryLoad(_bgMusic);
    _tapReady = await _tryLoad(_tapSfx);
    _deathReady = await _tryLoad(_deathSfx);
    _coinReady = await _tryLoad(_coinSfx);
  }

  Future<bool> _tryLoad(String assetPath) async {
    try {
      await FlameAudio.audioCache.load(assetPath);
      return true;
    } catch (e) {
      debugPrint('[AudioService] Failed to preload $assetPath: $e');
      return false;
    }
  }

  Future<void> playBackgroundMusic() async {
    if (!musicEnabled || !_bgMusicReady) return;
    try {
      await FlameAudio.bgm.play(_bgMusic, volume: 0.4);
    } catch (_) {}
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await FlameAudio.bgm.stop();
    } catch (_) {}
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await FlameAudio.bgm.pause();
    } catch (_) {}
  }

  Future<void> resumeBackgroundMusic() async {
    if (!musicEnabled) return;
    try {
      await FlameAudio.bgm.resume();
    } catch (_) {}
  }

  void playTap() {
    if (!sfxEnabled || !_tapReady) return;
    try {
      FlameAudio.play(_tapSfx, volume: 0.7);
    } catch (_) {}
  }

  void playDeath() {
    if (!sfxEnabled || !_deathReady) return;
    try {
      FlameAudio.play(_deathSfx, volume: 1.0);
    } catch (_) {}
  }

  void playCoin() {
    if (!sfxEnabled || !_coinReady) return;
    try {
      FlameAudio.play(_coinSfx, volume: 0.6);
    } catch (_) {}
  }

  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabled = enabled;
    if (enabled) {
      await resumeBackgroundMusic();
    } else {
      await pauseBackgroundMusic();
    }
  }

  void setSfxEnabled(bool enabled) => sfxEnabled = enabled;
}
