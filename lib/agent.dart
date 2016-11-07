import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart';
import 'config.dart' as config;
import 'brain.dart';
import 'randomization.dart';
import 'helper.dart';
import 'dwraon_brain.dart';

class Agent {

  Randomization random;

  Vector2 pos;

  double health; //in [0,2]. I cant remember why.
  double angle; //of the bot

  double red;
  double gre;
  double blu;

  double w1; //wheel speeds
  double w2;
  bool boost; //is this agent boosting

  double spikeLength;
  int age;

  bool spiked;

  //port: renamed in & out to inputs/outputs
  List<
      double> inputs; //input: 2 eyes, sensors for R,G,B,proximity each, then Sound, Smell, Health
  List<double> outputs; //output: Left, Right, R, G, B, SPIKE

  double repcounter; //when repcounter gets to 0, this bot reproduces
  int gencount; //generation counter
  bool hybrid; //is this agent result of crossover?
  double clockf1, clockf2; //the frequencies of the two clocks of this bot
  double soundmul; //sound multiplier of this bot. It can scream, or be very sneaky. This is actually always set to output 8

  //variables for drawing purposes
  double indicator;

  //indicator colors
  double ir;
  double ig;
  double ib;

  int selectflag; //is this agent selected?
  double dfood; //what is change in health of this agent due to giving/receiving?

  double give; //is this agent attempting to give food to other agent?

  static int _nextId = 0;
  int id;

  //inherited stuff
  double herbivore; //is this agent a herbivore? between 0 and 1
  double MUTRATE1; //how often do mutations occur?
  double MUTRATE2; //how significant are they?
  double temperature_preference; //what temperature does this agent like? [0 to 1]

  double smellmod;
  double soundmod;
  double hearmod;
  double eyesensmod;
  double bloodmod;

  List<double> eyefov; //field of view for each eye
  List<double> eyedir; //direction of each eye

  Brain brain;

  //will store the mutations that this agent has from its parent
  //can be used to tune the mutation rate
  List<String> mutations;

  Agent(this.random) {
    var rPos = (num n) => random.betweenInt(0, n);

    pos =
    new Vector2(rPos(config.WIDTH).toDouble(), rPos(config.HEIGHT).toDouble());
    angle = random.between(-Math.PI, Math.PI);
    health = 1.0 + random.between(0.0, 0.1);
    age = 0;
    spikeLength = 0.0;
    red = 0.0;
    gre = 0.0;
    blu = 0.0;
    w1 = 0.0;
    w2 = 0.0;
    soundmul = 1.0;
    give = 0.0;
    clockf1 = random.between(5.0, 100.0);
    clockf2 = random.between(5.0, 100.0);
    boost = false;
    indicator = 0.0;
    gencount = 0;
    selectflag = 0;
    ir = 0.0;
    ig = 0.0;
    ib = 0.0;
    temperature_preference = random.next();
    hybrid = false;
    herbivore = random.next();
    repcounter =
        herbivore * random.between(config.REPRATEH - 0.1, config.REPRATEH + 0.1)
            + (1 - herbivore) *
            random.between(config.REPRATEC - 0.1, config.REPRATEC + 0.1);

    id = _nextId++;

    smellmod = random.between(0.1, 0.5);
    soundmod = random.between(0.2, 0.6);
    hearmod = random.between(0.7, 1.3);
    eyesensmod = random.between(1.0, 3.0);
    bloodmod = random.between(1.0, 3.0);

    MUTRATE1 = random.between(0.001, 0.005);
    MUTRATE2 = random.between(0.03, 0.07);

    spiked = false;

    inputs = new List.filled(config.INPUTSIZE, 0.0);
    outputs = new List.filled(config.OUTPUTSIZE, 0.0);

    eyefov = new List.filled(config.NUMEYES, 0.0);
    eyedir = new List.filled(config.NUMEYES, 0.0);
    for (int i = 0; i < config.NUMEYES; i++) {
      eyefov[i] = random.between(0.5, 2.0);
      eyedir[i] = random.between(0.0, 2 * Math.PI);
    }

    brain = new DwraonBrain.random(
        random, config.BRAINSIZE, config.CONNS, config.INPUTSIZE,
        config.OUTPUTSIZE);
  }

  void printSelf() {
    print("Agent age=${age}\n");
    if (mutations.isNotEmpty) print("${mutations}\n");
  }

  //for drawing purposes
  void initEvent(double size, double r, double g, double b) {
    indicator = size;
    ir = r;
    ig = g;
    ib = b;
  }

  void tick() {
    brain.tick(inputs, outputs);
  }

  Agent reproduce(double MR, double MR2) {
    bool BDEBUG = false;
    if (BDEBUG) print("New birth---------------\n");

    Agent a2 = new Agent(this.random);

    //spawn the baby somewhere closeby behind agent
    //we want to spawn behind so that agents dont accidentally eat their young right away
    Vector2 fb = new Vector2(config.BOTRADIUS, 0.0)
      ..postmultiply(new Matrix2.rotation(-a2.angle));


    a2.pos = pos + fb + new Vector2(
        random.between(-config.BOTRADIUS * 2, config.BOTRADIUS * 2),
        random.between(-config.BOTRADIUS * 2, config.BOTRADIUS * 2));
    if (a2.pos.x < 0) a2.pos.x = config.WIDTH + a2.pos.x;
    if (a2.pos.x >= config.WIDTH) a2.pos.x = a2.pos.x - config.WIDTH;
    if (a2.pos.y < 0) a2.pos.y = config.HEIGHT + a2.pos.y;
    if (a2.pos.y >= config.HEIGHT) a2.pos.y = a2.pos.y - config.HEIGHT;


    a2.gencount = gencount + 1;
    a2.repcounter = a2.herbivore *
        random.between(config.REPRATEH - 0.1, config.REPRATEH + 0.1) +
        (1 - a2.herbivore) *
            random.between(config.REPRATEC - 0.1, config.REPRATEC + 0.1);


    //noisy attribute passing
    a2.MUTRATE1 = MUTRATE1;
    a2.MUTRATE2 = MUTRATE2;
    if (random.bet(0.1))
      a2.MUTRATE1 = random.randn(MUTRATE1, config.METAMUTRATE1);
    if (random.bet(0.1))
      a2.MUTRATE2 = random.randn(MUTRATE2, config.METAMUTRATE2);
    if (MUTRATE1 < 0.001) MUTRATE1 = 0.001;
    if (MUTRATE2 < 0.02) MUTRATE2 = 0.02;
    a2.herbivore = cap(random.randn(herbivore, 0.03));
    if (random.bet(MR * 5)) a2.clockf1 = random.randn(a2.clockf1, MR2);
    if (a2.clockf1 < 2) a2.clockf1 = 2.0;
    if (random.bet(MR * 5)) a2.clockf2 = random.randn(a2.clockf2, MR2);
    if (a2.clockf2 < 2) a2.clockf2 = 2.0;


    a2.smellmod = smellmod;
    a2.soundmod = soundmod;
    a2.hearmod = hearmod;
    a2.eyesensmod = eyesensmod;
    a2.bloodmod = bloodmod;

    if (random.bet(MR * 5)) {
      double oo = a2.smellmod;
      a2.smellmod = random.randn(a2.smellmod, MR2);
      if (BDEBUG) print("smell mutated from ${oo} to ${a2.smellmod}");
    }
    if (random.bet(MR * 5)) {
      double oo = a2.soundmod;
      a2.soundmod = random.randn(a2.soundmod, MR2);
      if (BDEBUG) print("sound mutated from ${oo} to ${a2.soundmod}");
    }
    if (random.bet(MR * 5)) {
      double oo = a2.hearmod;
      a2.hearmod = random.randn(a2.hearmod, MR2);
      if (BDEBUG) print("hear mutated from ${oo} to ${a2.hearmod}");
    }
    if (random.bet(MR * 5)) {
      double oo = a2.eyesensmod;
      a2.eyesensmod = random.randn(a2.eyesensmod, MR2);
      if (BDEBUG) print("eyesens mutated from ${oo} to ${a2.eyesensmod}");
    }
    if (random.bet(MR * 5)) {
      double oo = a2.bloodmod;
      a2.bloodmod = random.randn(a2.bloodmod, MR2);
      if (BDEBUG) print("blood mutated from ${oo} to ${a2.bloodmod}");
    }


    a2.eyefov = eyefov;
    a2.eyedir = eyedir;
    for (int i = 0; i < config.NUMEYES; i++) {
      if (random.bet(MR * 5)) a2.eyefov[i] = random.randn(a2.eyefov[i], MR2);
      if (a2.eyefov[i] < 0) a2.eyefov[i] = 0.0;

      if (random.bet(MR * 5)) a2.eyedir[i] = random.randn(a2.eyedir[i], MR2);
      if (a2.eyedir[i] < 0) a2.eyedir[i] = 0.0;
      if (a2.eyedir[i] > 2 * Math.PI) a2.eyedir[i] = 2 * Math.PI;
    }

    a2.temperature_preference =
        cap(random.randn(temperature_preference, 0.005));
    //a2.temperature_preference= this->temperature_preference;

    //mutate brain here
    a2.brain = brain.copy();
    a2.brain.mutate(MR, MR2);

    return a2;
  }

  Agent crossover(Agent other) {
    Agent anew = new Agent(random);
    anew.hybrid = true; //set this non-default flag
    anew.gencount = gencount;

    if (other.gencount < anew.gencount) anew.gencount = other.gencount;

    //agent heredity attributes
    anew.clockf1 = random.fiftyFifty() ? clockf1 : other.clockf1;
    anew.clockf2 = random.fiftyFifty() ? clockf2 : other.clockf2;
    anew.herbivore = random.fiftyFifty() ? herbivore : other.herbivore;
    anew.MUTRATE1 = random.fiftyFifty() ? MUTRATE1 : other.MUTRATE1;
    anew.MUTRATE2 = random.fiftyFifty() ? MUTRATE2 : other.MUTRATE2;
    anew.temperature_preference =
    random.fiftyFifty() ? temperature_preference : other.temperature_preference;

    anew.smellmod = random.fiftyFifty() ? smellmod : other.smellmod;
    anew.soundmod = random.fiftyFifty() ? soundmod : other.soundmod;
    anew.hearmod = random.fiftyFifty() ? hearmod : other.hearmod;
    anew.eyesensmod = random.fiftyFifty() ? eyesensmod : other.eyesensmod;
    anew.bloodmod = random.fiftyFifty() ? bloodmod : other.bloodmod;

    anew.eyefov = random.fiftyFifty() ? eyefov : other.eyefov;
    anew.eyedir = random.fiftyFifty() ? eyedir : other.eyedir;

    anew.brain = brain.crossover(other.brain);

    return anew;
  }


}