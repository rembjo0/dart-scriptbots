import 'dart:math' as Math;
import 'package:scriptbots/foodmodel.dart';
import 'randomization.dart';

class GrowingFoodModel extends FoodModel {

  Randomization _random;
  int _updateFreq;
  double _foodMax;

  double seasonFactor = 1.0;

  final List rCell = new List.unmodifiable([
    [-1, -1], [0, -1], [1, -1]
    , [-1, 0], [1, 0]
    , [-1, 1], [0, 1], [1, 1]
  ]);


  GrowingFoodModel(
      int width,
      int height,
      this._updateFreq,
      this._foodMax,
      this._random
      ) : super(width, height);

  @override
  void populate() {
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        set(x, y, 0.0);
        //set(x, y, _random.bet(0.5) ? _foodMax : 0.0);
      }
    }

    for (int i=0; i<(width*height)~/2; i++) {
      growFoodAtRandomPoint();
    }
  }

  @override
  void update(int modCounter) {
    if (modCounter % _updateFreq == 0 && _random.bet(seasonFactor)) {
      growFoodAtRandomPoint();
    }
  }

  void growFoodAtRandomPoint() {
    bool bet = _random.bet(0.4); //grow more food globally bet
    int fx = bet ? _nextInt(width) : (width ~/ 4 + _nextInt(width ~/ 2));
    int fy = bet ? _nextInt(height) : (height ~/ 4 + _nextInt(height ~/ 2));
    growOneCell(fx, fy);
  }

  int _nextInt (int x) => _random.nextInt(x);

  bool recursiveFoodCellGrow(int x, int y, int level) {
    if (level > 100) return false;

    int c;
    int r;
    for (int i = 0; i < 4; i++) {
      var p = rCell[_nextInt(rCell.length)];
      c = (x + p[0]) % width;
      r = (y + p[1]) % height;
      double pv = get(c, r);
      if (pv < 0.1) {
        set(c, r, 0.2);
        return true;
      }
    }
    return recursiveFoodCellGrow(c, r, level + 1);
  }

  void growOneCell(int x, int y) {
    //if (random.bet(0.001)) {
    //  food.set(x, y, Math.min(config.FOODMAX, food.get(x,y)+0.2));
    //  return;
    //}

    int fx = x;
    int fy = y;
    for (int i = 0; i < width~/8; i++) {
      fx = (fx + 1) % width;
      for (int j = 0; j < height~/8; j++) {
        fy = (fy + 1) % height;
        double fv = get(fx, fy);
        if (fv > 0.0) {
          if (fv < _foodMax - 0.2 && _random.bet(0.9)) {
            set(fx, fy, Math.min(_foodMax, get(x, y) + 0.2));
            return;
          } else {
            if (recursiveFoodCellGrow(fx, fy, 0)) {
              return;
            }
          }
        }
      }
    }

    set(x, y, Math.min(_foodMax, get(x, y) + 0.2));
  }

}