import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../game/components/background.dart';
import '../../state/game_state_provider.dart';

/// Full-screen Flutter overlay that plays when the player completes a level.
///
/// Sequence:
///   0.00s  Triggered by justLeveledUp flag
///   0.00s  Dark overlay fades in
///   0.15s  "LEVEL COMPLETE" slides down from top
///   0.35s  Level number pops in with elastic scale
///   0.60s  Theme name fades in
///   1.00s  Stars rain from top
///   2.00s  Everything fades out, overlay dismisses
///
/// The game world is paused during this overlay.
class LevelCompleteOverlay extends ConsumerStatefulWidget {
  const LevelCompleteOverlay({super.key});

  @override
  ConsumerState<LevelCompleteOverlay> createState() =>
      _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends ConsumerState<LevelCompleteOverlay>
    with TickerProviderStateMixin {

  late final AnimationController _mainCtrl;
  late final AnimationController _starsCtrl;

  // Animations
  late final Animation<double> _backdropFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _levelScale;
  late final Animation<double> _levelFade;
  late final Animation<double> _themeFade;
  late final Animation<double> _exitFade;

  int    _level     = 1;
  String _themeName = '';
  Color  _themeColor = const Color(0xFFFFFFFF);

  // Star particles
  final List<_Star> _stars = <_Star>[];
  final math.Random _rng   = math.Random();

  static const double _totalDuration = 3.0; // seconds

  @override
  void initState() {
    super.initState();

    _mainCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_totalDuration * 1000).round()),
    );

    _starsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    // Backdrop: fade in 0→0.15, hold, fade out 0.80→1.0
    _backdropFade = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.75), weight: 15),
      TweenSequenceItem(tween: ConstantTween(0.75),           weight: 65),
      TweenSequenceItem(tween: Tween(begin: 0.75, end: 0.0),  weight: 20),
    ]).animate(_mainCtrl);

    // Title: slides down from above at 0.12s
    _titleSlide = Tween<Offset>(
      begin: const Offset(0, -3.0),
      end:   Offset.zero,
    ).animate(CurvedAnimation(
      parent: _mainCtrl,
      curve: const Interval(0.12, 0.35, curve: Curves.elasticOut),
    ));

    // Level number: scale pop at 0.30s
    _levelScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.28, 0.50, curve: Curves.elasticOut),
      ),
    );

    _levelFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.28, 0.45, curve: Curves.easeIn),
      ),
    );

    // Theme name: fade in at 0.50s
    _themeFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.48, 0.65, curve: Curves.easeIn),
      ),
    );

    // Exit: fade everything out at 0.78s
    _exitFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainCtrl,
        curve: const Interval(0.78, 1.0, curve: Curves.easeOut),
      ),
    );

    // Generate star particles.
    for (int i = 0; i < 28; i++) {
      _stars.add(_Star(
        x:     _rng.nextDouble(),
        delay: _rng.nextDouble() * 1.0,
        speed: 0.15 + _rng.nextDouble() * 0.25,
        size:  2.0 + _rng.nextDouble() * 4.0,
      ));
    }

    _mainCtrl.forward().whenComplete(() {
      if (mounted) {
        ref.read(gameStateProvider.notifier).completeLevelAnimation();
      }
    });

    _starsCtrl.repeat();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _starsCtrl.dispose();
    super.dispose();
  }

  void _readLevelInfo() {
    final GameSessionState state = ref.read(gameStateProvider);
    _level = state.level;
    final int themeIndex = ((_level - 1) % kLevelThemes.length);
    final LevelTheme theme = kLevelThemes[themeIndex];
    _themeName  = theme.name;
    _themeColor = theme.bottomColor;
  }

  @override
  Widget build(BuildContext context) {
    _readLevelInfo();
    final Size screen = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _mainCtrl,
      builder: (BuildContext context, Widget? _) {
        return Stack(
          children: <Widget>[

            // ── Dark backdrop ───────────────────────────────────────
            Opacity(
              opacity: _backdropFade.value,
              child: Container(color: const Color(0xFF000000)),
            ),

            // ── Star rain ──────────────────────────────────────────
            AnimatedBuilder(
              animation: _starsCtrl,
              builder: (_, __) {
                return CustomPaint(
                  size: screen,
                  painter: _StarRainPainter(
                    stars:      _stars,
                    progress:   _starsCtrl.value,
                    themeColor: _themeColor,
                    opacity:    _exitFade.value,
                  ),
                );
              },
            ),

            // ── Content ─────────────────────────────────────────────
            Opacity(
              opacity: _exitFade.value,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[

                    // "LEVEL COMPLETE" title
                    SlideTransition(
                      position: _titleSlide,
                      child: Column(
                        children: <Widget>[
                          Text(
                            'LEVEL COMPLETE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontSize: 15,
                              letterSpacing: 6,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Glowing line under title
                          Container(
                            width: 180,
                            height: 1.5,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: <Color>[
                                Colors.transparent,
                                _themeColor,
                                Colors.transparent,
                              ]),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Level number — big, bold, animated scale
                    ScaleTransition(
                      scale: _levelScale,
                      child: FadeTransition(
                        opacity: _levelFade,
                        child: Text(
                          '$_level',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 110,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                            shadows: <Shadow>[
                              Shadow(
                                color: _themeColor.withValues(alpha: 0.8),
                                blurRadius: 40,
                              ),
                              Shadow(
                                color: _themeColor.withValues(alpha: 0.4),
                                blurRadius: 80,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Theme name
                    FadeTransition(
                      opacity: _themeFade,
                      child: Column(
                        children: <Widget>[
                          Text(
                            _themeName.toUpperCase(),
                            style: TextStyle(
                              color: _themeColor,
                              fontSize: 18,
                              letterSpacing: 5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Stars row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List<Widget>.generate(3, (int i) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6),
                                child: Icon(
                                  Icons.star,
                                  color: _themeColor,
                                  size: 24,
                                  shadows: <Shadow>[
                                    Shadow(
                                      color: _themeColor,
                                      blurRadius: 12,
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                  ],
                ),
              ),
            ),

          ],
        );
      },
    );
  }
}

// ── Star rain painter ──────────────────────────────────────────────────────────

class _Star {
  _Star({
    required this.x,
    required this.delay,
    required this.speed,
    required this.size,
  });

  final double x;
  final double delay;
  final double speed;
  final double size;
}

class _StarRainPainter extends CustomPainter {
  _StarRainPainter({
    required this.stars,
    required this.progress,
    required this.themeColor,
    required this.opacity,
  });

  final List<_Star> stars;
  final double      progress;
  final Color       themeColor;
  final double      opacity;

  final Paint _paint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    for (final _Star star in stars) {
      final double relProgress =
          ((progress - star.delay) / star.speed).clamp(0.0, 1.0);
      if (relProgress <= 0) continue;

      final double x     = star.x * size.width;
      final double y     = relProgress * (size.height + 40) - 20;
      final double alpha = math.sin(relProgress * math.pi) * opacity * 0.7;

      if (alpha <= 0) continue;

      // Alternate white and theme color
      _paint.color = stars.indexOf(star).isEven
          ? Colors.white.withValues(alpha: alpha)
          : themeColor.withValues(alpha: alpha);

      canvas.drawCircle(Offset(x, y), star.size, _paint);
    }
  }

  @override
  bool shouldRepaint(_StarRainPainter old) => true;
}
