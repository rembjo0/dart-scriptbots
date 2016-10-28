
import 'randomization.dart';

abstract class Brain<T extends Brain> {

  final Randomization random;
  final int brainsize;
  final int connections;
  final int numberOfInputs;
  final int numberOfOutputs;

  Brain(this.random,
      this.brainsize,
      this.connections,
      this.numberOfInputs,
      this.numberOfOutputs) {
    assert(random != null);
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


}
