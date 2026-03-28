import 'package:flutter_test/flutter_test.dart';

class _Item {
  bool isActive = false;
  int value = 0;
  void reset() {
    isActive = false;
    value = 0;
  }
}

class _Pool {
  _Pool(int size) : _items = List<_Item>.generate(size, (_) => _Item());
  final List<_Item> _items;

  _Item? acquire() {
    for (final _Item i in _items) {
      if (!i.isActive) {
        i.isActive = true;
        return i;
      }
    }
    return null;
  }

  void release(_Item item) => item.reset();
  int get activeCount => _items.where((_Item i) => i.isActive).length;
}

void main() {
  group('ObjectPool', () {
    late _Pool pool;
    setUp(() => pool = _Pool(5));

    test('acquire returns inactive item', () {
      expect(pool.acquire(), isNotNull);
    });

    test('acquired item marked active', () {
      pool.acquire();
      expect(pool.activeCount, 1);
    });

    test('release resets item', () {
      final _Item item = pool.acquire()!;
      item.value = 42;
      pool.release(item);
      expect(item.isActive, isFalse);
      expect(item.value, 0);
    });

    test('returns null when exhausted', () {
      for (int i = 0; i < 5; i++) {
        pool.acquire();
      }
      expect(pool.acquire(), isNull);
    });

    test('releasing from exhausted pool re-enables acquire', () {
      final List<_Item> all = <_Item>[];
      for (int i = 0; i < 5; i++) {
        all.add(pool.acquire()!);
      }
      pool.release(all.first);
      expect(pool.acquire(), isNotNull);
    });
  });
}
