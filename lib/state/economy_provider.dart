import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/player_save_data.dart';
import '../services/storage_service.dart';

final class EconomyState {
  const EconomyState({required this.coinBalance, required this.adsRemoved});

  factory EconomyState.fromSave(PlayerSaveData save) =>
      EconomyState(coinBalance: save.coinBalance, adsRemoved: save.adsRemoved);

  final int  coinBalance;
  final bool adsRemoved;

  EconomyState copyWith({int? coinBalance, bool? adsRemoved}) => EconomyState(
      coinBalance: coinBalance ?? this.coinBalance,
      adsRemoved:  adsRemoved  ?? this.adsRemoved);
}

class EconomyNotifier extends StateNotifier<EconomyState> {
  EconomyNotifier()
      : super(EconomyState.fromSave(StorageService.instance.loadSave()));

  Future<void> addCoins(int amount) async {
    await StorageService.instance.addCoins(amount);
    state = state.copyWith(coinBalance: state.coinBalance + amount);
  }

  Future<bool> spendCoins(int amount) async {
    if (state.coinBalance < amount) return false;
    final bool ok = await StorageService.instance.spendCoins(amount);
    if (ok) state = state.copyWith(coinBalance: state.coinBalance - amount);
    return ok;
  }

  Future<void> applyRemoveAdsPurchase() async {
    await StorageService.instance.setAdsRemoved();
    state = state.copyWith(adsRemoved: true);
  }

  void refresh() {
    state = EconomyState.fromSave(StorageService.instance.loadSave());
  }
}

final StateNotifierProvider<EconomyNotifier, EconomyState> economyProvider =
    StateNotifierProvider<EconomyNotifier, EconomyState>(
        (_) => EconomyNotifier());
