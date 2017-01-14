import 'package:scriptbots/foodmodel.dart';
import 'randomization.dart';

class RandomFoodModel extends FoodModel {

  Randomization _random;
  int _updateFreq;
  double _foodMax;

  RandomFoodModel(
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
      }
    }
  }

  @override
  void update(int modCounter) {
    if (modCounter % _updateFreq == 0) {
      int fx = _random.nextInt(width);
      int fy = _random.nextInt(height);
      set(fx, fy, _foodMax);
    }
  }

}