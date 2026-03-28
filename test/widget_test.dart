import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:orbia_game/services/storage_service.dart';
import 'package:orbia_game/ui/screens/main_menu_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await StorageService.instance.init();
    await StorageService.instance.nukeAllData();
  });

  testWidgets('main menu renders primary actions', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MainMenuScreen(),
        ),
      ),
    );

    expect(find.text('ORBIA'), findsOneWidget);
    expect(find.text('PLAY'), findsOneWidget);
    expect(find.text('SHOP'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });
}
