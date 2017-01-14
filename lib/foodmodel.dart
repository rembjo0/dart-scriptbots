library food_model;
import 'helper.dart';

typedef void FoodListenerFnc(int x, int y);

abstract class FoodModel {

  FoodListenerFnc foodListener;

  final Array2<double> _store;

  FoodModel(int width, int height) : _store = new Array2(width, height);

  int get width => _store.numColumns;

  int get height => _store.numRows;

  void update(int modCounter);

  void set(int x, int y, double v) {
    _store.set(x, y, v);

    if (foodListener != null) {
      foodListener(x, y);
    }
  }

  double get(int c, int r) {
    return _store.get(c, r);
  }

}