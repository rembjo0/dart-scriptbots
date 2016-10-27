library dwraonbrain;

import 'brain.dart';


/**
 * Damped Weighted Recurrent AND/OR Network brain implementation ported from
 * https://github.com/karpathy/scriptsbots/blob/master/DWRAONBrain.cpp
 */
class Box {
  int type = 0; //0: AND 1:OR
  double kp = 0.0; //damping strength
  List<double> w; //weight of each connecting box (in [0,inf]
  List<int> id; //id in boxes[] of the connecting box
  List<bool> notted; //is this input notted before coming in?
  double bias = 0.0;

  //state variables
  double target = 0.0; //target value this node is going toward
  double out = 0.0; //current output, and history. 0 is farthest back. -1 is latest


  Box._empty () {

  }

  Box.allocate(Brain brain) {
    w = new List.filled(brain.connections, 0.0);
    id = new List.filled(brain.connections, 0);
    notted = new List.filled(brain.connections, false);
  }

  Box copy() {
    var box = new Box._empty();
    box.type = type;
    box.kp = kp;
    box.w = new List.from(w, growable: false);
    box.id = new List.from(id, growable: false);
    box.notted = new List.from(notted, growable: false);
    box.bias = bias;
    box.target = target;
    box.out = out;

    return box;
  }

  factory Box.random(Brain brain) {
    Box b = new Box.allocate(brain);

    //constructor
    for (int i = 0; i < brain.connections; i++) {
      b.w[i] = brain.rand(0.1, 2.0);
      b.id[i] = brain.randi(0, brain.brainsize);

      //20% of the brain AT LEAST should connect to input.
      if (brain.rand(0.0, 1.0) < 0.2)
        b.id[i] = brain.randi(0, brain.numberOfInputs);

      b.notted[i] = brain.rand(0.0, 1.0) < 0.5;
    }

    b.type = (brain.rand(0.0, 1.0) > 0.5) ? (0) : (1);
    b.kp = brain.rand(0.8, 1.0);
    b.bias = brain.rand(-1.0, 1.0);

    return b;
  }

}

class DwraonBrain extends Brain<DwraonBrain> {

  static int _c = 1000;

  String id;
  List<Box> boxes;


  DwraonBrain._blank(int seed,
      int brainsize,
      int connections,
      int numberOfInputs,
      int numberOfOutputs)
      : super(seed, brainsize, connections, numberOfInputs, numberOfOutputs) {
    assert(numberOfInputs > 0);
    assert(numberOfOutputs > 0);
    assert(brainsize >= numberOfInputs + numberOfOutputs);
    assert(connections > 0);
    assert(connections < brainsize);

    boxes = new List(brainsize);

    _c++;
    id = "[${_c}]";
  }

  factory DwraonBrain.random(int seed,
      int brainsize,
      int connections,
      int numberOfInputs,
      int numberOfOutputs)
  {
    DwraonBrain brain = new DwraonBrain._blank(
        seed,
        brainsize,
        connections,
        numberOfInputs,
        numberOfOutputs);

    for (int i = 0; i < brainsize; i++) {
      brain.boxes[i] = new Box.random(brain);

      //Forcing brain to connect to inputs is also
      //coded in the _Box class (20% originally).
      //Here the first half of the brain points to the inputs
      if (i < brainsize / 2) {
        for (int j = 0; j < connections; j++) {
          brain.boxes[i].id[j] = brain.randi(0, numberOfInputs);
        }
      }
    }

    return brain;
  }

  DwraonBrain copy() {
    DwraonBrain b = new DwraonBrain._blank(
        seed, brainsize, connections, numberOfInputs, numberOfOutputs);

    b.id = id;

    for (int i = 0; i < boxes.length; i++) {
      b.boxes[i] = boxes[i].copy();
    }

    return b;
  }

  DwraonBrain crossover(DwraonBrain otherBrain) {
    DwraonBrain newBrain = copy();

    newBrain.id = "[${id}+${otherBrain.id}]";
    for (int i = 0; i < boxes.length; i++) {
      var box = newBrain.boxes[i];
      var other = otherBrain.boxes[i];

      //FIXME keep values from original brain, reset or do crossover?
      //Original code uses values from this.
      //box.out = 0.0;
      //box.target = 0.0;

      box.bias = fiftyFifty() ? boxes[i].bias : other.bias;
      box.kp = fiftyFifty() ? boxes[i].kp : other.kp;
      box.type = fiftyFifty() ? boxes[i].type : other.type;

      for (int j = 0; j < boxes[i].id.length; j++) {
        box.id[j] = fiftyFifty() ? boxes[i].id[j] : other.id[j];
        box.notted[j] = fiftyFifty() ? boxes[i].notted[j] : other.notted[j];
        box.w[j] = fiftyFifty() ? boxes[i].w[j] : other.w[j];
      }
    }

    return newBrain;
  }


  /**
   * do a single tick of the brain
   */
  @override
  void tick(List<double> inputs, List<double> outputs) {
    assert(inputs != null);
    assert(inputs.length == numberOfInputs);
    assert(outputs != null);
    assert(outputs.length == numberOfOutputs);

    //take first few boxes and set their out to in[].
    for (int i = 0; i < numberOfInputs; i++) {
      boxes[i].out = inputs[i];
    }

    //then do a dynamics tick and set all targets
    boxes.skip(numberOfInputs).forEach((box) {
      if (box.type == 0) {
        //AND NODE
        double res = 1.0;
        for (int j = 0; j < connections; j++) {
          int idx = box.id[j];
          double val = boxes[idx].out;
          if (box.notted[j]) val = 1 - val;
          //res= res * pow(val, abox->w[j]);
          res = res * val;
        }

        res *= box.bias;
        box.target = res;
      } else {
        //OR NODE
        double res = 0.0;
        for (int j = 0; j < connections; j++) {
          int idx = box.id[j];
          double val = boxes[idx].out;
          if (box.notted[j]) val = 1 - val;
          res = res + val * box.w[j];
        }
        res += box.bias;
        box.target = res;
      }

      //clamp target
      if (box.target < 0.0) box.target = 0.0;
      if (box.target > 1.0) box.target = 1.0;
    });

    //make all boxes go a bit toward target
    boxes.skip(numberOfInputs).forEach((box) {
      box.out = box.out + (box.target - box.out) * box.kp;
    });

    //finally set out[] to the last few boxes output
    for (int i = 0; i < numberOfOutputs; i++) {
      outputs[i] = boxes[brainsize - 1 - i].out;
    }
  }

  void mutate(final double probability, final double adjustFactor) {
    int mc = 0;
    boxes.forEach((box) {
      if (rand(0.0, 1.0) < probability * 3) {
        box.bias += rand(0.0, adjustFactor);
        //a2.mutations.push_back("bias jiggled\n");
        mc++;
      }

      //if (rand(0.0, 1.0) < MR * 3) {
      //  box.kp += rand(0.0, MR2);
      //  if (box.kp < 0.01) box.kp = 0.01;
      //  if (box.kp > 1.0) box.kp = 1.0;
      //  //a2.mutations.push_back("kp jiggled\n");
      //  mc++;
      //}

      if (rand(0.0, 1.0) < probability * 3) {
        int rc = randi(0, connections);
        box.w[rc] += rand(0.0, adjustFactor);
        if (box.w[rc] < 0.01) box.w[rc] = 0.01;
        mc++;
        //a2.mutations.push_back("weight jiggled\n");
      }

      //more unlikely changes here
      if (rand(0.0, 1.0) < probability) {
        int rc = randi(0, connections);
        int ri = randi(0, brainsize);
        box.id[rc] = ri;
        mc++;
        //a2.mutations.push_back("connectivity changed\n");
      }

      if (rand(0.0, 1.0) < probability) {
        int rc = randi(0, connections);
        box.notted[rc] = !box.notted[rc];
        mc++;
        //a2.mutations.push_back("notted was flipped\n");
      }

      if (rand(0.0, 1.0) < probability) {
        box.type = 1 - box.type;
        mc++;
        //a2.mutations.push_back("type of a box was changed\n");
      }
    });

    if (mc > 0) id = "${id}!${mc}";
  }


}