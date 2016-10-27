library brain;

import 'dart:math';


abstract class Brain<T extends Brain> {

  final int seed;
  final int brainsize;
  final int connections;
  final int numberOfInputs;
  final int numberOfOutputs;

  final Random _rand;

  Brain(int seed,
      this.brainsize,
      this.connections,
      this.numberOfInputs,
      this.numberOfOutputs)
      :
        this.seed = seed,
        this._rand = new Random(seed) {
    assert(brainsize > 0);
    assert(connections > 0);
    assert(brainsize > connections); //should be much greater actually
    assert(numberOfInputs > 0);
    assert(numberOfOutputs > 0);
  }

  void tick(List<double> inputs, List<double> outputs);

  void mutate(final double probability, final double adjustFactor);

  T copy();

  T crossover(T otherBrain);


  double rand(double min, double max) {
    assert(max > min);
    return min + (_rand.nextDouble() * (max - min));
  }

  bool fiftyFifty() {
    return _rand.nextDouble() < 0.5;
  }

  int randi(min, max) {
    assert(max > min);
    return min + (_rand.nextInt(max - min));
  }

}
