import 'package:flutter_test/flutter_test.dart';

bool circlesOverlap(double x1, double y1, double r1,
                    double x2, double y2, double r2) {
  final double dx = x2 - x1;
  final double dy = y2 - y1;
  final double radiiSum = r1 + r2;
  return (dx * dx + dy * dy) < radiiSum * radiiSum;
}

void main() {
  group('Circle collision', () {
    test('overlapping circles → true',  () =>
        expect(circlesOverlap(0, 0, 10, 5,  0, 10), isTrue));
    test('separated circles → false',   () =>
        expect(circlesOverlap(0, 0, 5,  100, 0, 5),  isFalse));
    test('touching boundary → false',   () =>
        expect(circlesOverlap(0, 0, 10, 20,  0, 10), isFalse));
    test('concentric → true',           () =>
        expect(circlesOverlap(0, 0, 10, 0,  0, 5),  isTrue));
    test('diagonal overlap → true',     () =>
        expect(circlesOverlap(0, 0, 2,  2,  2, 2),  isTrue));
    test('no sqrt needed — squared check works', () {
      const double dx = 15, dy = 0, r1 = 10, r2 = 10;
      expect(dx * dx + dy * dy < (r1 + r2) * (r1 + r2), isTrue);
    });
  });
}
