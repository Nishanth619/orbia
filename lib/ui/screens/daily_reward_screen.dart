import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/game_config.dart';
import '../../services/daily_reward_service.dart';
import '../../services/storage_service.dart';
import '../../state/achievement_provider.dart';
import '../../state/economy_provider.dart';
import '../widgets/orbia_button.dart';

class DailyRewardScreen extends ConsumerStatefulWidget {
  const DailyRewardScreen({super.key});

  @override
  ConsumerState<DailyRewardScreen> createState() => _DailyRewardScreenState();
}

class _DailyRewardScreenState extends ConsumerState<DailyRewardScreen>
    with SingleTickerProviderStateMixin {
  late DailyRewardResult _status;
  bool _claimed = false;

  late final AnimationController _popCtrl;
  late final Animation<double> _popAnim;

  @override
  void initState() {
    super.initState();
    _status = DailyRewardService.instance.checkStatus();

    _popCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _popAnim = CurvedAnimation(parent: _popCtrl, curve: Curves.elasticOut);
    _popCtrl.forward();
  }

  @override
  void dispose() {
    _popCtrl.dispose();
    super.dispose();
  }

  Future<void> _claim() async {
    final DailyRewardResult result =
        await DailyRewardService.instance.claimReward();
    ref.read(economyProvider.notifier).refresh();

    final save = StorageService.instance.loadSave();
    final achievementNotifier = ref.read(achievementProvider.notifier);
    await achievementNotifier.checkStreak(save.dailyStreakDay);
    await achievementNotifier.checkCoins(save.totalCoinsEverEarned);

    setState(() {
      _status = result;
      _claimed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Center(
        child: ScaleTransition(
          scale: _popAnim,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF3D0020),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (_status.isStreakReset)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('STREAK RESET',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          letterSpacing: 3,
                        )),
                  ),

                Text(
                  _claimed ? 'CLAIMED!' : 'DAILY REWARD',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    letterSpacing: 4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Day ${_status.streakDay} of 7',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 13)),

                const SizedBox(height: 20),
                _DayBubbleRow(currentDay: _status.streakDay),
                const SizedBox(height: 20),

                // Coin reward
                Text('+${_status.coinsReward}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                    )),
                const Text('CRYSTALS',
                    style: TextStyle(
                        color: Colors.white54, fontSize: 11, letterSpacing: 3)),

                const SizedBox(height: 24),
                if (!_claimed)
                  OrbiaButton(label: 'CLAIM', onTap: _claim)
                else
                  OrbiaButton(
                    label: 'CONTINUE',
                    onTap: () => Navigator.of(context).pop(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayBubbleRow extends StatelessWidget {
  const _DayBubbleRow({required this.currentDay});
  final int currentDay;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(7, (int i) {
        final int day = i + 1;
        final bool past = day < currentDay;
        final bool today = day == currentDay;
        final int coins = GameConfig.dailyRewardSchedule[i];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Column(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: today ? 34 : 26,
                height: today ? 34 : 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: today
                      ? Colors.white
                      : past
                          ? Colors.white38
                          : Colors.transparent,
                  border: Border.all(color: Colors.white54, width: 1.2),
                ),
                alignment: Alignment.center,
                child: Text('$day',
                    style: TextStyle(
                      color: today ? Colors.black : Colors.white70,
                      fontSize: today ? 13 : 10,
                      fontWeight: FontWeight.w700,
                    )),
              ),
              const SizedBox(height: 3),
              Text('$coins',
                  style: const TextStyle(color: Colors.white38, fontSize: 9)),
            ],
          ),
        );
      }),
    );
  }
}
