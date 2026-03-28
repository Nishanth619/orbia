import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/daily_reward_service.dart';
import 'ui/screens/daily_reward_screen.dart';
import 'ui/screens/main_menu_screen.dart';

class OrbiaApp extends ConsumerWidget {
  const OrbiaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Orbia',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      home: const _StartupRouter(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF2A0015),
      fontFamily: 'NeonFont',
      colorScheme: const ColorScheme.dark(
        primary:   Color(0xFFFFFFFF),
        secondary: Color(0xFFFF6600),
        surface:   Color(0xFF3D0020),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

/// Checks for a claimable daily reward on cold start and routes accordingly.
class _StartupRouter extends StatefulWidget {
  const _StartupRouter();

  @override
  State<_StartupRouter> createState() => _StartupRouterState();
}

class _StartupRouterState extends State<_StartupRouter> {
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  void _check() {
    final bool canClaim =
        DailyRewardService.instance.checkStatus().canClaim;
    if (canClaim && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const DailyRewardScreen(),
          ),
        );
      });
    }
    setState(() => _checked = true);
  }

  @override
  Widget build(BuildContext context) =>
      _checked ? const MainMenuScreen() : const SizedBox.shrink();
}
