import 'package:flutter/material.dart';

class CoinDisplay extends StatelessWidget {
  const CoinDisplay({super.key, required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Transform.rotate(
          angle: 0.785,
          child: Container(width: 12, height: 12, color: Colors.white),
        ),
        const SizedBox(width: 6),
        Text('$balance',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            )),
      ],
    );
  }
}
