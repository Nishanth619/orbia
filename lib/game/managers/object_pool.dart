import 'package:flutter/foundation.dart';

abstract interface class Poolable {
  void reset();
  bool get isActive;
  set isActive(bool value);
}

final class ObjectPool<T extends Poolable> {
  ObjectPool({required int size, required T Function() factory})
      : _items = List<T>.generate(size, (_) => factory(), growable: false) {
    assert(size > 0);
  }

  final List<T> _items;

  int get capacity => _items.length;
  int get activeCount => _items.where((T i) => i.isActive).length;
  int get freeCount => capacity - activeCount;

  T? acquire() {
    for (int i = 0; i < _items.length; i++) {
      if (!_items[i].isActive) {
        _items[i].isActive = true;
        return _items[i];
      }
    }
    debugPrint('[ObjectPool<$T>] exhausted (capacity: $capacity)');
    return null;
  }

  void release(T item) {
    item.reset();
    item.isActive = false;
  }

  void releaseAll() {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isActive) {
        _items[i].reset();
        _items[i].isActive = false;
      }
    }
  }

  void forEachActive(void Function(T item) action) {
    for (int i = 0; i < _items.length; i++) {
      if (_items[i].isActive) action(_items[i]);
    }
  }

  void forEachItem(void Function(T item) action) {
    for (int i = 0; i < _items.length; i++) {
      action(_items[i]);
    }
  }
}
