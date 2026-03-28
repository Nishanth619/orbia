import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/settings_provider.dart';

/// Reusable button matching the Orbia warm-red aesthetic.
/// White border, white text — clean and minimal.
class OrbiaButton extends ConsumerStatefulWidget {
  const OrbiaButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 220,
  });

  final String label;
  final VoidCallback onTap;
  final double width;

  @override
  ConsumerState<OrbiaButton> createState() => _OrbiaButtonState();
}

class _OrbiaButtonState extends ConsumerState<OrbiaButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _down(TapDownDetails _) => _ctrl.forward();

  Future<void> _up(TapUpDetails _) async {
    await _ctrl.reverse();
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    widget.onTap();
  }

  Future<void> _cancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white, width: 1.8),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }
}
