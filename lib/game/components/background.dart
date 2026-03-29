import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart'
    show Alignment, LinearGradient, Color, Colors;

final class LevelTheme {
  const LevelTheme({
    required this.name,
    required this.topColor,
    required this.midColor,
    required this.bottomColor,
    required this.silhouetteColor,
    required this.silhouetteMidColor,
    required this.dustColor,
    required this.silhouetteType,
    required this.dustCount,
  });

  final String name;
  final Color topColor;
  final Color midColor;
  final Color bottomColor;
  final Color silhouetteColor;
  final Color silhouetteMidColor;
  final Color dustColor;
  final SilhouetteType silhouetteType;
  final int dustCount;
}

enum SilhouetteType {
  mountains,
  waves,
  hills,
  trees,
  icebergs,
  lava,
  stars,
  pyramids,
}

const List<LevelTheme> kLevelThemes = <LevelTheme>[
  LevelTheme(
    name: 'Crimson Heights',
    topColor: Color(0xFF2A0015),
    midColor: Color(0xFF7A0A00),
    bottomColor: Color(0xFFCC3300),
    silhouetteColor: Color(0xFF1A0008),
    silhouetteMidColor: Color(0xFF2D000F),
    dustColor: Color(0x33FF6600),
    silhouetteType: SilhouetteType.mountains,
    dustCount: 55,
  ),
  LevelTheme(
    name: 'Midnight Ocean',
    topColor: Color(0xFF000A1F),
    midColor: Color(0xFF001A4D),
    bottomColor: Color(0xFF003399),
    silhouetteColor: Color(0xFF000814),
    silhouetteMidColor: Color(0xFF001030),
    dustColor: Color(0x2200AAFF),
    silhouetteType: SilhouetteType.waves,
    dustCount: 40,
  ),
  LevelTheme(
    name: 'Purple Dusk',
    topColor: Color(0xFF1A0033),
    midColor: Color(0xFF6600AA),
    bottomColor: Color(0xFFFF6699),
    silhouetteColor: Color(0xFF110022),
    silhouetteMidColor: Color(0xFF220044),
    dustColor: Color(0x33FF99CC),
    silhouetteType: SilhouetteType.hills,
    dustCount: 50,
  ),
  LevelTheme(
    name: 'Dark Forest',
    topColor: Color(0xFF001A00),
    midColor: Color(0xFF004400),
    bottomColor: Color(0xFF006622),
    silhouetteColor: Color(0xFF001100),
    silhouetteMidColor: Color(0xFF002200),
    dustColor: Color(0x2200FF66),
    silhouetteType: SilhouetteType.trees,
    dustCount: 35,
  ),
  LevelTheme(
    name: 'Arctic Frost',
    topColor: Color(0xFF001A2A),
    midColor: Color(0xFF006699),
    bottomColor: Color(0xFF99DDFF),
    silhouetteColor: Color(0xFF002233),
    silhouetteMidColor: Color(0xFF003344),
    dustColor: Color(0x44AAEEFF),
    silhouetteType: SilhouetteType.icebergs,
    dustCount: 60,
  ),
  LevelTheme(
    name: 'Volcanic Core',
    topColor: Color(0xFF0A0000),
    midColor: Color(0xFF330000),
    bottomColor: Color(0xFFFF4400),
    silhouetteColor: Color(0xFF050000),
    silhouetteMidColor: Color(0xFF1A0000),
    dustColor: Color(0x44FF2200),
    silhouetteType: SilhouetteType.lava,
    dustCount: 45,
  ),
  LevelTheme(
    name: 'Deep Galaxy',
    topColor: Color(0xFF000005),
    midColor: Color(0xFF0A0022),
    bottomColor: Color(0xFF220055),
    silhouetteColor: Color(0xFF000000),
    silhouetteMidColor: Color(0xFF050010),
    dustColor: Color(0x55FFFFFF),
    silhouetteType: SilhouetteType.stars,
    dustCount: 120,
  ),
  LevelTheme(
    name: 'Golden Dawn',
    topColor: Color(0xFF1A0F00),
    midColor: Color(0xFF8B4500),
    bottomColor: Color(0xFFFFCC00),
    silhouetteColor: Color(0xFF100800),
    silhouetteMidColor: Color(0xFF1A0D00),
    dustColor: Color(0x33FFDD00),
    silhouetteType: SilhouetteType.pyramids,
    dustCount: 40,
  ),
];

final class Background extends PositionComponent {
  Background({
    required this.screenSize,
    required this.cameraRef,
  }) : super(priority: -100);

  final Vector2 screenSize;
  final CameraComponent cameraRef;

  int _currentThemeIndex = 0;
  Picture? _currentPicture;
  Picture? _previousPicture;
  double _fadeProgress = 1.0;
  bool _transitioning = false;

  static const double _fadeDuration = 0.9;
  double _fadeTimer = 0.0;

  final Paint _mainPaint = Paint();
  final Paint _previousPaint = Paint();

  @override
  Future<void> onLoad() async {
    size = screenSize;
    _snapToCamera();
    _currentPicture = _buildPicture(kLevelThemes[0]);
  }

  void transitionToLevel(int level) {
    final int index = ((level - 1) % kLevelThemes.length);
    if (index == _currentThemeIndex && _currentPicture != null) return;

    _previousPicture = _currentPicture;
    _currentThemeIndex = index;
    _currentPicture = _buildPicture(kLevelThemes[index]);
    _fadeProgress = 0.0;
    _fadeTimer = 0.0;
    _transitioning = true;
  }

  @override
  void update(double dt) {
    _snapToCamera();

    if (_transitioning) {
      _fadeTimer += dt;
      _fadeProgress = (_fadeTimer / _fadeDuration).clamp(0.0, 1.0);
      if (_fadeProgress >= 1.0) {
        _transitioning = false;
        _previousPicture = null;
      }
    }
  }

  void _snapToCamera() {
    final Vector2 cam = cameraRef.viewfinder.position;
    position.setValues(cam.x - screenSize.x / 2.0, cam.y - screenSize.y / 2.0);
  }

  @override
  void render(Canvas canvas) {
    if (_transitioning && _previousPicture != null) {
      _previousPaint.color = Colors.white.withOpacity(1.0 - _fadeProgress);
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
        _previousPaint,
      );
      canvas.drawPicture(_previousPicture!);
      canvas.restore();

      _mainPaint.color = Colors.white.withOpacity(_fadeProgress);
      canvas.saveLayer(
        Rect.fromLTWH(0, 0, screenSize.x, screenSize.y),
        _mainPaint,
      );
      if (_currentPicture != null) canvas.drawPicture(_currentPicture!);
      canvas.restore();
    } else {
      if (_currentPicture != null) canvas.drawPicture(_currentPicture!);
    }
  }

  Picture _buildPicture(LevelTheme theme) {
    final PictureRecorder recorder = PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final double w = screenSize.x;
    final double h = screenSize.y;
    final math.Random rng = math.Random(theme.name.hashCode);

    final Paint gradPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[theme.topColor, theme.midColor, theme.bottomColor],
        stops: const <double>[0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), gradPaint);

    _drawDust(canvas, theme, w, h, rng);
    _drawSilhouette(canvas, theme, w, h, rng);

    return recorder.endRecording();
  }

  void _drawDust(Canvas canvas, LevelTheme theme, double w, double h, math.Random rng) {
    final Paint dp = Paint()
      ..style = PaintingStyle.fill
      ..color = theme.dustColor;

    final bool isGalaxy = theme.silhouetteType == SilhouetteType.stars;

    for (int i = 0; i < theme.dustCount; i++) {
      final double x = rng.nextDouble() * w;
      final double y = rng.nextDouble() * h;
      final double r = isGalaxy ? 0.5 + rng.nextDouble() * 2.0 : 0.6 + rng.nextDouble() * 1.8;
      canvas.drawCircle(Offset(x, y), r, dp);
    }

    if (isGalaxy) {
      final Paint brightStar = Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.white.withOpacity(0.9);
      for (int i = 0; i < 15; i++) {
        canvas.drawCircle(
          Offset(rng.nextDouble() * w, rng.nextDouble() * h),
          1.5 + rng.nextDouble() * 2.0,
          brightStar,
        );
      }
    }
  }

  void _drawSilhouette(Canvas canvas, LevelTheme theme, double w, double h, math.Random rng) {
    switch (theme.silhouetteType) {
      case SilhouetteType.mountains:
        _drawMountains(canvas, theme, w, h);
      case SilhouetteType.waves:
        _drawWaves(canvas, theme, w, h);
      case SilhouetteType.hills:
        _drawHills(canvas, theme, w, h, rng);
      case SilhouetteType.trees:
        _drawTrees(canvas, theme, w, h, rng);
      case SilhouetteType.icebergs:
        _drawIcebergs(canvas, theme, w, h);
      case SilhouetteType.lava:
        _drawLava(canvas, theme, w, h);
      case SilhouetteType.stars:
        break;
      case SilhouetteType.pyramids:
        _drawPyramids(canvas, theme, w, h);
    }
  }

  void _drawMountains(Canvas canvas, LevelTheme t, double w, double h) {
    _drawTriangleLayer(canvas, t.silhouetteColor, w, h, h, h * 0.20, 7, 0.0);
    _drawTriangleLayer(canvas, t.silhouetteMidColor, w, h, h * 1.02, h * 0.13, 9, w * 0.06);
  }

  void _drawIcebergs(Canvas canvas, LevelTheme t, double w, double h) {
    _drawTriangleLayer(canvas, t.silhouetteColor, w, h, h, h * 0.28, 6, 0.0);
    _drawTriangleLayer(canvas, t.silhouetteMidColor, w, h, h * 1.03, h * 0.16, 8, w * 0.08);
  }

  void _drawLava(Canvas canvas, LevelTheme t, double w, double h) {
    _drawTriangleLayer(canvas, t.silhouetteColor, w, h, h, h * 0.15, 10, 0.0);
    _drawTriangleLayer(canvas, t.silhouetteMidColor, w, h, h * 1.02, h * 0.08, 14, w * 0.04);
    final Paint lavaPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0x55FF3300);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.88, w, h * 0.12), lavaPaint);
  }

  void _drawPyramids(Canvas canvas, LevelTheme t, double w, double h) {
    final Paint p = Paint()..style = PaintingStyle.fill..color = t.silhouetteColor;
    final Paint p2 = Paint()..style = PaintingStyle.fill..color = t.silhouetteMidColor;

    final List<List<double>> pyramids = <List<double>>[
      <double>[w * 0.05, h * 0.78, w * 0.38, h],
      <double>[w * 0.30, h * 0.65, w * 0.62, h],
      <double>[w * 0.58, h * 0.72, w * 0.88, h],
    ];
    for (final List<double> py in pyramids) {
      final double midX = (py[0] + py[2]) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(py[0], py[3])
          ..lineTo(midX, py[1])
          ..lineTo(py[2], py[3])
          ..close(),
        p,
      );
    }

    final List<List<double>> pyramids2 = <List<double>>[
      <double>[w * 0.70, h * 0.80, w * 1.0, h],
      <double>[w * -0.02, h * 0.82, w * 0.18, h],
    ];
    for (final List<double> py in pyramids2) {
      final double midX = (py[0] + py[2]) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(py[0], py[3])
          ..lineTo(midX, py[1])
          ..lineTo(py[2], py[3])
          ..close(),
        p2,
      );
    }
  }

  void _drawWaves(Canvas canvas, LevelTheme t, double w, double h) {
    final Paint wavePaint = Paint()..style = PaintingStyle.fill..color = t.silhouetteColor;
    final Paint wavePaint2 = Paint()..style = PaintingStyle.fill..color = t.silhouetteMidColor;

    _drawWaveLayer(canvas, wavePaint, w, h, h * 0.82, h * 0.10);
    _drawWaveLayer(canvas, wavePaint2, w, h, h * 0.88, h * 0.07);
  }

  void _drawWaveLayer(Canvas canvas, Paint paint, double w, double h, double baseY, double amplitude) {
    final Path path = Path()..moveTo(0, baseY);
    const int waves = 4;
    final double segW = w / waves;
    for (int i = 0; i < waves; i++) {
      final double x0 = i * segW;
      final double x1 = x0 + segW / 2;
      final double x2 = x0 + segW;
      path.quadraticBezierTo(x1, baseY - amplitude, x2, baseY);
    }
    path..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path, paint);
  }

  void _drawHills(Canvas canvas, LevelTheme t, double w, double h, math.Random rng) {
    final Paint p = Paint()..style = PaintingStyle.fill..color = t.silhouetteColor;
    final Paint p2 = Paint()..style = PaintingStyle.fill..color = t.silhouetteMidColor;

    _drawHillLayer(canvas, p, w, h, h * 0.80, h * 0.18);
    _drawHillLayer(canvas, p2, w, h, h * 0.88, h * 0.10);
  }

  void _drawHillLayer(Canvas canvas, Paint paint, double w, double h, double baseY, double height) {
    final Path path = Path()..moveTo(0, baseY);
    const int hills = 3;
    final double segW = w / hills;
    for (int i = 0; i < hills; i++) {
      final double x0 = i * segW;
      final double x1 = x0 + segW / 2;
      final double x2 = x0 + segW;
      path.quadraticBezierTo(x1, baseY - height, x2, baseY);
    }
    path..lineTo(w, h)..lineTo(0, h)..close();
    canvas.drawPath(path, paint);
  }

  void _drawTrees(Canvas canvas, LevelTheme t, double w, double h, math.Random rng) {
    final Paint p = Paint()..style = PaintingStyle.fill..color = t.silhouetteColor;
    final Paint p2 = Paint()..style = PaintingStyle.fill..color = t.silhouetteMidColor;

    _drawTreeRow(canvas, p, w, h, 8, h * 0.75, h * 0.22, rng, 42);
    _drawTreeRow(canvas, p2, w, h, 6, h * 0.83, h * 0.16, rng, 99);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.9, w, h * 0.1), p);
  }

  void _drawTreeRow(Canvas canvas, Paint paint, double w, double h, int count, double baseY, double treeH, math.Random rng, int seed) {
    final math.Random tr = math.Random(seed);
    final double spacing = w / count;
    for (int i = 0; i < count; i++) {
      final double cx = i * spacing + spacing / 2 + (tr.nextDouble() - 0.5) * spacing * 0.3;
      final double trunkW = spacing * 0.08;
      final double trunkH = treeH * 0.25;
      canvas.drawRect(
        Rect.fromLTWH(cx - trunkW / 2, baseY - trunkH, trunkW, trunkH),
        paint,
      );
      for (int tier = 0; tier < 3; tier++) {
        final double tierY = baseY - trunkH - treeH * 0.25 * tier;
        final double tierW = spacing * (0.5 - tier * 0.1);
        canvas.drawPath(
          Path()
            ..moveTo(cx - tierW, tierY)
            ..lineTo(cx, tierY - treeH * 0.32)
            ..lineTo(cx + tierW, tierY)
            ..close(),
          paint,
        );
      }
    }
  }

  void _drawTriangleLayer(Canvas canvas, Color color, double w, double h, double baseY, double peakH, int count, double offset) {
    final Paint p = Paint()..style = PaintingStyle.fill..color = color;
    final double segW = w / count;
    for (int i = 0; i < count; i++) {
      final double left = i * segW + offset - segW * 0.1;
      final double right = left + segW * 1.2;
      final double mid = (left + right) / 2;
      canvas.drawPath(
        Path()
          ..moveTo(left, baseY)
          ..lineTo(mid, baseY - peakH)
          ..lineTo(right, baseY)
          ..close(),
        p,
      );
    }
  }
}
