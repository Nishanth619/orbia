import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orbia_game/ui/overlays/hud_overlay.dart';
import 'package:orbia_game/services/storage_service.dart';
import 'package:orbia_game/state/game_state_provider.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageService.instance.init();
  });

  testWidgets('HudOverlay renders LEVEL and CRYSTALS labels', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: HudOverlay()),
        ),
      ),
    );
    expect(find.text('LEVEL'),    findsOneWidget);
    expect(find.text('CRYSTALS'), findsOneWidget);
  });

  testWidgets('HudOverlay updates when score changes', (
    WidgetTester tester,
  ) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (BuildContext ctx, WidgetRef ref, _) {
                capturedRef = ref;
                return const HudOverlay();
              },
            ),
          ),
        ),
      ),
    );

    capturedRef.read(gameStateProvider.notifier).nodeReached(1);
    await tester.pump();

    expect(find.textContaining('1 /'), findsOneWidget);
  });
}
