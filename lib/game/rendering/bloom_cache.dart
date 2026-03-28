import 'dart:ui';

final class BloomLayer {
  const BloomLayer({
    required this.radiusMultiplier,
    required this.opacity,
    required this.blurSigma,
  });

  final double radiusMultiplier;
  final double opacity;
  final double blurSigma;
}

abstract final class BloomPresets {
  static const List<BloomLayer> standard = <BloomLayer>[
    BloomLayer(radiusMultiplier: 2.8, opacity: 0.18, blurSigma: 18.0),
    BloomLayer(radiusMultiplier: 1.9, opacity: 0.32, blurSigma: 9.0),
    BloomLayer(radiusMultiplier: 1.0, opacity: 1.00, blurSigma: 0.0),
  ];

  static const List<BloomLayer> dashBoost = <BloomLayer>[
    BloomLayer(radiusMultiplier: 3.4, opacity: 0.22, blurSigma: 22.0),
    BloomLayer(radiusMultiplier: 2.2, opacity: 0.38, blurSigma: 11.0),
    BloomLayer(radiusMultiplier: 1.0, opacity: 1.00, blurSigma: 0.0),
  ];

  static const List<BloomLayer> node = <BloomLayer>[
    BloomLayer(radiusMultiplier: 3.2, opacity: 0.14, blurSigma: 16.0),
    BloomLayer(radiusMultiplier: 2.0, opacity: 0.28, blurSigma: 8.0),
    BloomLayer(radiusMultiplier: 1.0, opacity: 1.00, blurSigma: 0.0),
  ];
}

/// Pre-allocated Paint set for a neon bloom stack.
/// Zero allocation per frame — all Paints built once in constructor.
final class BloomPaintSet {
  BloomPaintSet({required Color color, required List<BloomLayer> layers})
      : _layers = layers,
        _paints = _buildPaints(color, layers);

  final List<BloomLayer> _layers;
  final List<Paint> _paints;

  static List<Paint> _buildPaints(Color color, List<BloomLayer> layers) =>
      List<Paint>.generate(layers.length, (int i) {
        final Paint p = Paint()
          ..style = PaintingStyle.fill
          ..color = color.withAlpha((layers[i].opacity * 255).round());
        if (layers[i].blurSigma > 0.0) {
          p.maskFilter = MaskFilter.blur(BlurStyle.normal, layers[i].blurSigma);
        }
        return p;
      }, growable: false);

  void updateColor(Color color) {
    for (int i = 0; i < _layers.length; i++) {
      _paints[i].color = color.withAlpha((_layers[i].opacity * 255).round());
    }
  }

  void renderBloom(Canvas canvas, Offset center, double baseRadius) {
    for (int i = 0; i < _layers.length; i++) {
      canvas.drawCircle(
          center, baseRadius * _layers[i].radiusMultiplier, _paints[i]);
    }
  }
}
