
import 'dart:math';
import 'helper.dart';

class FoodMatrix {

  final Array2<double> _store;

  List<Point<int>> _dirtyCells = [];
  bool _allDirty = true;

  FoodMatrix(int columns, int rows) : _store = new Array2(columns, rows);

  void set(int c, int r, double v) {
    _store.set(c, r, v);

    if (_allDirty) {
      return;
    }

    int limit = ((_store.numColumns*_store.numRows)*0.75).toInt();

    // If too many dirty cells, then just mark all as dirty and stop tracking.
    if (_dirtyCells.length > limit) {
      _allDirty = true;
      _dirtyCells = [];
    } else {
      //mark as dirty, note... we do not check duplicates, should be few
      _dirtyCells.add(new Point(c, r));
    }
  }

  /**
   * When true, all cells should be considered dirty.
   * Dirty cells return empty.
   */
  bool get allDirty => _allDirty;

  void clearAllDirty () {
    _allDirty = false;
  }

  /**
   * Takes dirty cells (clears the dirty list).
   * Note: This list is empty if allDirty is true.
   */
  List<Point<int>> takeDirtyCells () {
    var t = _dirtyCells;
    _dirtyCells = [];
    return t;
  }

  double get(int c, int r) {
    return _store.get(c, r);
  }

  int get numColumns => _store.numColumns;

  int get numRows => _store.numRows;

}
