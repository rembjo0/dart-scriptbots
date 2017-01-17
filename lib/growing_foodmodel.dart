import 'dart:math' as Math;
import 'package:scriptbots/foodmodel.dart';
import 'randomization.dart';

final List _rCell = new List.unmodifiable([
  [-1, -1],
  [0, -1],
  [1, -1],
  [-1, 0],
  [1, 0],
  [-1, 1],
  [0, 1],
  [1, 1]
]);

class Season {
  final String name;
  final double factor;
  final int seasonLength;

  Season(this.name, this.factor, this.seasonLength);

  @override
  String toString() => "${name}:${factor}";
}

final Season SPRING = new Season("spring", 0.3, 5000);
final Season SUMMER = new Season("summer", 1.0, 5000);
final Season AUTUMN = new Season("autumn", 0.2, 5000);
final Season WINTER = new Season("winter", 0.05, 5000);

class GrowingFoodModel extends FoodModel {
  Randomization _random;
  int _updateFreq;
  double _foodMax;

  List<Season> seasons = [SPRING, SUMMER, AUTUMN, WINTER];
  int seasonIndex = 0;
  int seasonCounter = 0;

  GrowingFoodModel(
      int width, int height, this._updateFreq, this._foodMax, this._random)
      : super(width, height);

  int _nextInt(int x) => _random.nextInt(x);

  @override
  void populate() {
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        set(x, y, 0.0);
        //set(x, y, _random.bet(0.5) ? _foodMax : 0.0);
      }
    }

    for (int i = 0; i < (width * height) ~/ 4; i++) {
      growFoodAtRandomPoint();
    }
  }

  @override
  void update(int modCounter) {
    Season season = _updateSeason();

    if (modCounter % _updateFreq == 0 && _random.bet(season.factor)) {
      growFoodAtRandomPoint();
    }
  }

  Season _updateSeason() {
    Season season = seasons[seasonIndex];
    seasonCounter++;
    if (seasonCounter > season.seasonLength) {
      seasonIndex = (seasonIndex + 1) % seasons.length;
      seasonCounter = 0;
      season = seasons[seasonIndex];
      print("-- season changed: ${season}");
    }
    return season;
  }

  void growFoodAtRandomPoint() {
    bool bet = _random.bet(0.4); //grow more food globally bet
    int fx = bet ? _nextInt(width) : (width ~/ 4 + _nextInt(width ~/ 2));
    int fy = bet ? _nextInt(height) : (height ~/ 4 + _nextInt(height ~/ 2));
    growOneCell(fx, fy);
  }

  bool recursiveFoodCellGrow(int x, int y, int level) {
    if (level > 100) return false;

    int c, r;
    for (int i = 0; i < 4; i++) {
      var p = _rCell[_nextInt(_rCell.length)];
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
    int fx = x;
    int fy = y;
    for (int i = 0; i < width ~/ 8; i++) {
      fx = (fx + 1) % width;
      for (int j = 0; j < height ~/ 8; j++) {
        fy = (fy + 1) % height;
        double fv = get(fx, fy);
        if (fv > 0.0) {
          if (fv < _foodMax - 0.2 && _random.bet(0.9)) {
            set(fx, fy, Math.min(_foodMax, fv + 0.2));
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
