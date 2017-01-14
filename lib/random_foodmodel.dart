import 'package:scriptbots/food_model.dart';

class RandomFoodModel extends FoodModel {

  int _updateFreq;

  RandomFoodModel(int width, int height, this._updateFreq) : super(width, height);

  void init() {
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        set(x, y, 0.0);
      }
    }
  }

  @override
  void update(int modCounter) {

  }

}