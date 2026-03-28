import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_save_data.dart';
import '../models/skin_model.dart';
import '../services/storage_service.dart';
import 'achievement_provider.dart';
import 'economy_provider.dart';

final class SkinState {
  const SkinState({
    required this.allSkins,
    required this.unlockedIds,
    required this.selectedId,
  });

  factory SkinState.fromSave(PlayerSaveData save) => SkinState(
        allSkins: SkinCatalogue.all,
        unlockedIds: save.unlockedSkinIds,
        selectedId: save.selectedSkinId,
      );

  final List<SkinModel> allSkins;
  final List<String> unlockedIds;
  final String selectedId;

  SkinModel get activeSkin =>
      SkinCatalogue.findById(selectedId) ?? SkinCatalogue.all.first;

  bool isUnlocked(String id) => unlockedIds.contains(id);

  SkinState copyWith({List<String>? unlockedIds, String? selectedId}) =>
      SkinState(
        allSkins: allSkins,
        unlockedIds: unlockedIds ?? this.unlockedIds,
        selectedId: selectedId ?? this.selectedId,
      );
}

class SkinNotifier extends StateNotifier<SkinState> {
  SkinNotifier(this._ref)
      : super(SkinState.fromSave(StorageService.instance.loadSave()));

  final Ref _ref;

  Future<void> selectSkin(String skinId) async {
    if (!state.isUnlocked(skinId)) return;
    await StorageService.instance.selectSkin(skinId);
    state = state.copyWith(selectedId: skinId);
  }

  Future<bool> purchaseSkin(String skinId) async {
    final SkinModel? skin = SkinCatalogue.findById(skinId);
    if (skin == null || state.isUnlocked(skinId)) {
      return state.isUnlocked(skinId);
    }
    final bool ok =
        await _ref.read(economyProvider.notifier).spendCoins(skin.cost);
    if (!ok) {
      return false;
    }
    await StorageService.instance.unlockSkin(skinId);
    state = state.copyWith(unlockedIds: <String>[...state.unlockedIds, skinId]);
    await _ref.read(achievementProvider.notifier).checkShopPurchase(
          state.unlockedIds.length,
        );
    return true;
  }

  Future<void> forceUnlock(String skinId) async {
    if (state.isUnlocked(skinId)) return;
    await StorageService.instance.unlockSkin(skinId);
    state = state.copyWith(unlockedIds: <String>[...state.unlockedIds, skinId]);
  }
}

final StateNotifierProvider<SkinNotifier, SkinState> skinProvider =
    StateNotifierProvider<SkinNotifier, SkinState>((ref) => SkinNotifier(ref));

final Provider<SkinModel> activeSkinProvider =
    Provider<SkinModel>((ref) => ref.watch(skinProvider).activeSkin);
