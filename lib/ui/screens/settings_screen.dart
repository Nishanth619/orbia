import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/audio_service.dart';
import '../../state/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SettingsState settings = ref.watch(settingsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF2A0015),
              Color(0xFF7A0A00),
              Color(0xFFCC3300),
            ],
            stops: <double>[0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              // ── Header ─────────────────────────────────────────────
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Text('SETTINGS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 4,
                          )),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // ── Toggle rows ────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  children: <Widget>[
                    const _SectionLabel('AUDIO'),
                    _ToggleRow(
                      label: 'Sound Effects',
                      value: settings.sfxEnabled,
                      onChanged: (bool v) {
                        ref.read(settingsProvider.notifier).toggleSfx();
                        AudioService.instance.setSfxEnabled(v);
                      },
                    ),
                    _ToggleRow(
                      label: 'Music',
                      value: settings.musicEnabled,
                      onChanged: (bool v) {
                        ref.read(settingsProvider.notifier).toggleMusic();
                        AudioService.instance.setMusicEnabled(v);
                      },
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel('FEEL'),
                    _ToggleRow(
                      label: 'Haptic Feedback',
                      value: settings.hapticsEnabled,
                      onChanged: (_) =>
                          ref.read(settingsProvider.notifier).toggleHaptics(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            )),
      );
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
          ),
        ],
      );
}
