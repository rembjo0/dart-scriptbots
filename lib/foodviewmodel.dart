import 'dart:math';
import 'package:scriptbots/foodmodel.dart';

class FoodViewModel {

  final FoodModel _food;

  List<Point<int>> _dirtyCells = [];
  bool _allDirty = true;

  bool _drawFoodEnabled = true;

  FoodViewModel(this._food) {
    _food.foodListener = this.cellModifiedListener;
  }

  int get width => _food.width;

  int get height => _food.height;


  bool isFoodDrawingEnabled()  => _drawFoodEnabled;

  void setFoodDrawingEnabled (bool b) {
    _drawFoodEnabled = b;
    _setAllDirty();
  }

  void cellModifiedListener(int c, int r) {

    if (_allDirty) {
      return;
    }

    int limit = ((width*height)*0.75).toInt();

    // If too many dirty cells, then just mark all as dirty and stop tracking.
    if (_dirtyCells.length > limit) {
      _setAllDirty();
      print("-- food view, dirty limit reached. Not tracking.");
    } else {
      //mark as dirty, note... we do not check duplicates, should be few
      _dirtyCells.add(new Point(c, r));
    }
  }

  void _setAllDirty() {
    _allDirty = true;
    _dirtyCells = [];
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
    return _food.get(c, r);
  }


}
