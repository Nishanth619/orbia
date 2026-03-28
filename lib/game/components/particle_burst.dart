import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../models/game_config.dart';

final class _Particle {
  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.radius,
    required this.lifetime,
  });

  Vector2 position;
  Vector2 velocity;
  Color color;
  double radius;
  double lifetime;
  double age = 0.0;

  bool get isDead => age >= lifetime;
  double get progress => age / lifetime;
}

/// One-shot death explosion. Self-removes when all particles expire.
/// All particles allocated in [onLoad] — zero allocation during update.
final class ParticleBurst extends Component {
  ParticleBurst({
    required this.worldPosition,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final Vector2 worldPosition;
  final Color primaryColor;
  final Color secondaryColor;

  late final List<_Particle> _particles;
  final Paint _paint = Paint()..style = PaintingStyle.fill;

  static const double _minSpeed = 60.0;
  static const double _maxSpeed = 220.0;
  static const double _minLifetime = 0.4;
  static const double _maxLifetime = 0.9;
  static const double _minRadius = 2.0;
  static const double _maxRadius = 6.0;
  static const double _gravity = 80.0;

  @override
  Future<void> onLoad() async {
    final math.Random rng = math.Random();
    const int count = GameConfig.deathParticleCount;

    _particles = List<_Particle>.generate(count, (int i) {
      final double baseAngle = (i / count) * math.pi * 2;
      final double jitter = (rng.nextDouble() - 0.5) * 0.4;
      final double angle = baseAngle + jitter;
      final double speed =
          _minSpeed + rng.nextDouble() * (_maxSpeed - _minSpeed);
      final int alpha = ((0.7 + rng.nextDouble() * 0.3) * 255).round();

      final Color color =
          (i.isEven ? primaryColor : secondaryColor).withAlpha(alpha);

      return _Particle(
        position: worldPosition.clone(),
        velocity: Vector2(math.cos(angle) * speed, math.sin(angle) * speed),
        color: color,
        radius: _minRadius + rng.nextDouble() * (_maxRadius - _minRadius),
        lifetime:
            _minLifetime + rng.nextDouble() * (_maxLifetime - _minLifetime),
      );
    }, growable: false);
  }

  @override
  void update(double dt) {
    bool anyAlive = false;
    for (int i = 0; i < _particles.length; i++) {
      final _Particle p = _particles[i];
      if (p.isDead) continue;
      anyAlive = true;
      p.age += dt;
      p.position.x += p.velocity.x * dt;
      p.position.y += p.velocity.y * dt;
      p.velocity.y += _gravity * dt;
      p.velocity.x *= 0.97;
      p.velocity.y *= 0.97;
    }
    if (!anyAlive) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    for (int i = 0; i < _particles.length; i++) {
      final _Particle p = _particles[i];
      if (p.isDead) continue;
      final double alpha = (1.0 - p.progress) * (p.color.a / 255.0);
      final double radius =
          (p.radius * (1.0 - p.progress * 0.6)).clamp(0.5, _maxRadius);
      _paint.color = p.color.withAlpha((alpha.clamp(0.0, 1.0) * 255).round());
      canvas.drawCircle(Offset(p.position.x, p.position.y), radius, _paint);
    }
  }
}
