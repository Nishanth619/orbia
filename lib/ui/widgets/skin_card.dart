import 'package:flutter/material.dart';

import '../../models/skin_model.dart';

class SkinCard extends StatelessWidget {
  const SkinCard({
    super.key,
    required this.skin,
    required this.isUnlocked,
    required this.isSelected,
    required this.onTap,
  });

  final SkinModel    skin;
  final bool         isUnlocked;
  final bool         isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color skinColor = Color(skin.colorHex);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF3D0020),
          border: Border.all(
            color: isSelected ? Colors.white : Colors.white24,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isUnlocked ? skinColor : Colors.white12,
              ),
              child: isUnlocked
                  ? null
                  : const Icon(Icons.lock_rounded,
                      color: Colors.white38, size: 22),
            ),
            const SizedBox(height: 10),
            Text(skin.displayName,
                style: TextStyle(
                  color: isUnlocked ? Colors.white : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            if (isSelected)
              const Text('EQUIPPED',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    letterSpacing: 1,
                  ))
            else if (!isUnlocked)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Transform.rotate(
                    angle: 0.785,
                    child: Container(width: 8, height: 8, color: Colors.white60),
                  ),
                  const SizedBox(width: 4),
                  Text('${skin.cost}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
