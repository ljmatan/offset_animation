import 'dart:async';

abstract class ItemsController {
  static List _items;
  static List get items => _items;

  static StreamController _streamController;

  static void init() {
    _items = [];
    _streamController = StreamController.broadcast();
  }

  static Stream get stream => _streamController.stream;

  static void add(value) {
    _items.add(value);
    _streamController.add(value);
  }

  static void dispose() {
    _streamController.close();
    _items = null;
  }
}
