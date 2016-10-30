import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart';
import 'agent.dart';
import 'config.dart' as config;
import 'helper.dart';
import 'randomization.dart';
import 'view.dart';


class World {

  final Randomization random;

  List<int> numCarnivore;
  List<int> numHerbivore;
  int ptr;

  factory World.create([seed]) {
    return new World(new Randomization(seed));
  }

  World(this.random) {
    assert(random != null);

    if (config.WIDTH % config.CZ != 0 || config.HEIGHT % config.CZ != 0) {
      var message = "CAREFUL! The cell size variable config.CZ should divide "
          "evenly into both config.WIDTH and config.HEIGHT! "
          "It doesn't right now!";
      throw new ArgumentError(message);
    }

    int numColumns = config.WIDTH ~/ config.CZ;
    int numRows = config.HEIGHT ~/ config.CZ;
    food = new Array2D(numColumns, numRows);

    modcounter = 0;
    current_epoch = 0;
    idcounter = 0;
    FW = config.WIDTH ~/ config.CZ;
    FH = config.HEIGHT ~/ config.CZ;
    CLOSED = false;

    addRandomBots(config.NUMBOTS);

    //inititalize food layer
    for (int x = 0; x < FW; x++) {
      for (int y = 0; y < FH; y++) {
        food.set(x, y, 0.0);
      }
    }

    numCarnivore = new List<int>.filled(200, 0);
    numHerbivore = new List<int>.filled(200, 0);
    ptr = 0;
  }

  void update() {
    modcounter++;

    //Process periodic events
    //Age goes up!
    if (modcounter % 100 == 0) {
      agents.forEach((a) => a.age += 1);
    }

    if (modcounter % 1000 == 0) {
      var num_herbs_carns = numHerbCarnivores();
      numHerbivore[ptr] = num_herbs_carns.first;
      numCarnivore[ptr] = num_herbs_carns.second;
      ptr++;
      if (ptr == numHerbivore.length) ptr = 0;
    }

    if (modcounter % 1000 == 0) writeReport();

    if (modcounter >= 10000) {
      modcounter = 0;
      current_epoch++;
    }

    if (modcounter % config.FOODADDFREQ == 0) {
      fx = random.nextInt(FW);
      fy = random.nextInt(FH);
      food.set(fx, fy, config.FOODMAX);
    }

    //reset any counter variables per agent
    agents.forEach((agent) {
      agent.spiked = false;
    });

    //give input to every agent. Sets inputs[] array
    setInputs();

    //brains tick. computes inputs[] -> outputs[]
    brainsTick();

    //read output and process consequences of bots on environment. requires outputs[]
    processOutputs();


    //process bots: health and deaths
    agents.forEach((agent) {
      double baseloss = 0.0002; // + 0.0001*(abs(agents[i].w1) + abs(agents[i].w2))/2;
      //if (agents[i].w1<0.1 && agents[i].w2<0.1) baseloss=0.0001; //hibernation :p
      //baseloss += 0.00005*agents[i].soundmul; //shouting costs energy. just a tiny bit

      if (agent.boost) {
        //boost carries its price, and it's pretty heavy!
        agent.health -= baseloss * config.BOOSTSIZEMULT * 1.3;
      } else {
        agent.health -= baseloss;
      }
    });


    //process temperature preferences
    agents.forEach((agent) {
      //calculate temperature at the agents spot. (based on distance from equator)
      double dd = 2.0 * (agent.pos.x / config.WIDTH - 0.5).abs();
      double discomfort = (dd - agent.temperature_preference).abs();
      discomfort = discomfort * discomfort;
      if (discomfort < 0.08) discomfort = 0.0;
      agent.health -= config.TEMPERATURE_DISCOMFORT * discomfort;
    });

    //process indicator (used in drawing)
    agents.forEach((agent) {
      if (agent.indicator > 0) agent.indicator -= 1;
    });


    //remove dead agents.
    //first distribute foods
    agents.forEach((agent) {
      //if this agent was spiked this round as well (i.e. killed). This will make it so that
      //natural deaths can't be capitalized on. I feel I must do this or otherwise agents
      //will sit on spot and wait for things to die around them. They must do work!
      if (agent.health <= 0 && agent.spiked) {
        //distribute its food. It will be erased soon
        //first figure out how many are around, to distribute this evenly
        int numaround = 0;
        agents.forEach((a) {
          if (a.health > 0) {
            double d = (agent.pos - a.pos).length;
            if (d < config.FOOD_DISTRIBUTION_RADIUS) {
              numaround++;
            }
          }
        });

        //young killed agents should give very little resources
        //at age 5, they mature and give full. This can also help prevent
        //agents eating their young right away
        double agemult = 1.0;
        if (agent.age < 5) agemult = agent.age * 0.2;

        if (numaround > 0) {
          //distribute its food evenly
          agents.forEach((a) {
            if (a.health > 0) {
              double d = (agent.pos - a.pos).length;
              if (d < config.FOOD_DISTRIBUTION_RADIUS) {
                a.health += 5 * (1 - a.herbivore) * (1 - a.herbivore) /
                    Math.pow(numaround, 1.25) * agemult;
                a.repcounter -=
                    config.REPMULT * (1 - a.herbivore) * (1 - a.herbivore) /
                        Math.pow(numaround, 1.25) *
                        agemult; //good job, can use spare parts to make copies
                if (a.health > 2) a.health = 2.0; //cap it!
                a.initEvent(30.0, 1.0, 1.0, 1.0); //white means they ate! nice
              }
            }
          }
          );
        }
      }
    });

    agents.retainWhere((a) => a.health > 0);

    //handle reproduction
    var newAgents = [];
    agents.forEach((agent) {
      if (agent.repcounter < 0 && agent.health > 0.65 && modcounter % 15 == 0 &&
          random.bet(
              0.1)) { //agent is healthy and is ready to reproduce. Also inject a bit non-determinism
        //agent.health= 0.8; //the agent is left vulnerable and weak, a bit
        reproduce(agent, agent.MUTRATE1, agent.MUTRATE2,
            newAgents); //this adds config.BABIES new agents to agents[]
        agent.repcounter = agent.herbivore *
            random.between(config.REPRATEH - 0.1, config.REPRATEH + 0.1) +
            (1 - agent.herbivore) *
                random.between(config.REPRATEC - 0.1, config.REPRATEC + 0.1);
      }
    });
    agents.addAll(newAgents);


    //add new agents, if environment isn't closed
    if (!CLOSED) {
      //make sure environment is always populated with at least NUMBOTS bots
      if (agents.length < config.NUMBOTS) {
        //add new agent
        addRandomBots(1);
      }
      if (modcounter % 100 == 0) {
        if (random.fiftyFifty()) {
          addRandomBots(1); //every now and then add random bots in
        } else
          addNewByCrossover(); //or by crossover
      }
    }
  }

  void reset() {
    agents.clear();
    addRandomBots(config.NUMBOTS);
  }

  void draw(View view, bool drawfood) {
    //draw food
    if (drawfood) {
      for (int i = 0; i < FW; i++) {
        for (int j = 0; j < FH; j++) {
          double f = 0.5 * food.get(i, j) / config.FOODMAX;
          view.drawFood(i, j, f);
        }
      }
    }

    //draw all agents
    agents.forEach((a) => view.drawAgent(a));

    view.drawMisc();
  }

  bool isClosed() => CLOSED;


  void setClosed(bool close) {
    CLOSED = close;
  }


  /**
   * Returns the number of herbivores and
   * carnivores in the world.
   * first : num herbs
   * second : num carns
   */
  Pair<int, int> numHerbCarnivores() {
    int numherb = 0;
    int numcarn = 0;
    agents.forEach((agent) {
      if (agent.herbivore > 0.5)
        numherb++;
      else
        numcarn++;
    });

    return new Pair(numherb, numcarn);
  }

  int numAgents() => agents.length;

  int epoch() => current_epoch;

  //mouse interaction
  void processMouse(int button, int state, int x, int y) {
    //FIXME
  }

  void addNewByCrossover() {
    //find two success cases
    int i1 = random.betweenInt(0, agents.length);
    int i2 = random.betweenInt(0, agents.length);
    for (int i = 0; i < agents.length; i++) {
      if (agents[i].age > agents[i1].age && random.bet(0.1)) {
        i1 = i;
      }
      if (agents[i].age > agents[i2].age && random.bet(0.1) && i != i1) {
        i2 = i;
      }
    }

    Agent a1 = agents[i1];
    Agent a2 = agents[i2];


    //cross brains
    Agent anew = a1.crossover(a2);


    //maybe do mutation here? I dont know. So far its only crossover
    anew.id = idcounter;
    idcounter++;
    agents.add(anew);
  }

  void addRandomBots(int num) {
    for (int i = 0; i < num; i++) {
      Agent a = new Agent(random);
      a.id = idcounter;
      idcounter++;
      agents.add(a);
    }
  }

  void addCarnivore() {
    Agent a = new Agent(random);
    a.id = idcounter;
    idcounter++;
    a.herbivore = random.between(0.0, 0.1);
    agents.add(a);
  }

  void addHerbivore() {
    Agent a = new Agent(random);
    a.id = idcounter;
    idcounter++;
    a.herbivore = random.between(0.9, 1.0);
    agents.add(a);
  }

  Math.Point positionOfInterest(int type) {
    return null;
  }

  //FIXME -- PRIVATE SECTION

  void setInputs() {
    //P1 R1 G1 B1 FOOD P2 R2 G2 B2 SOUND SMELL HEALTH P3 R3 G3 B3 CLOCK1 CLOCK 2 HEARING     BLOOD_SENSOR   TEMPERATURE_SENSOR
    //0   1  2  3  4   5   6  7 8   9     10     11   12 13 14 15 16       17      18           19                 20

    double PI8 = Math.PI / 8 / 2; //pi/8/2
    double PI38 = 3 * PI8; //3pi/8/2

    agents.forEach((a) {
      //HEALTH
      a.inputs[11] = cap(a.health / 2); //divide by 2 since health is in [0,2]

      //FOOD
      int cx = a.pos.x ~/ config.CZ;
      int cy = a.pos.y ~/ config.CZ;
      a.inputs[4] = food.get(cx, cy) / config.FOODMAX;


      //SOUND SMELL EYES
      var p = new List<double>.filled(config.NUMEYES, 0.0);
      var r = new List<double>.filled(config.NUMEYES, 0.0);
      var g = new List<double>.filled(config.NUMEYES, 0.0);
      var b = new List<double>.filled(config.NUMEYES, 0.0);

      double soaccum = 0.0;
      double smaccum = 0.0;
      double hearaccum = 0.0;

      //BLOOD ESTIMATOR
      double blood = 0.0;

      agents
          .where((a2) {
        if (a2 == a) return false;
        bool outOfReach =
        (a.pos.x < a2.pos.x - config.DIST || a.pos.x > a2.pos.x + config.DIST
            || a.pos.y > a2.pos.y + config.DIST ||
            a.pos.y < a2.pos.y - config.DIST);
        return !outOfReach;
      })
          .forEach((a2) {
        double d = (a.pos - a2.pos).length;

        if (d < config.DIST) {
          //smell
          smaccum += (config.DIST - d) / config.DIST;

          //sound
          soaccum += (config.DIST - d) / config.DIST *
              (Math.max(a2.w1.abs(), a2.w2.abs()));

          //hearing. Listening to other agents
          hearaccum += a2.soundmul * (config.DIST - d) / config.DIST;

          //FIXME PORT MOVE TO HELPER CLASS?
          var get_angle = (Vector2 v) {
            if (v.x == 0 && v.y == 0) return 0.0;
            return Math.atan2(v.y, v.x);
          };

          double ang = get_angle(a2.pos - a.pos); //current angle between bots

          for (int q = 0; q < config.NUMEYES; q++) {
            double aa = a.angle + a.eyedir[q];
            if (aa < -Math.PI) aa += 2 * Math.PI;
            if (aa > Math.PI) aa -= 2 * Math.PI;

            double diff1 = aa - ang;
            if (diff1.abs() > Math.PI) diff1 = 2 * Math.PI - diff1.abs();
            diff1 = diff1.abs();

            double fov = a.eyefov[q];
            if (diff1 < fov) {
              //we see a2 with this eye. Accumulate stats
              double mul1 = a.eyesensmod * ((fov - diff1).abs() / fov) *
                  ((config.DIST - d) / config.DIST);
              p[q] += mul1 * (d / config.DIST);
              r[q] += mul1 * a2.red;
              g[q] += mul1 * a2.gre;
              b[q] += mul1 * a2.blu;
            }
          }

          //blood sensor
          double forwangle = a.angle;
          double diff4 = forwangle - ang;
          if (forwangle.abs() > Math.PI) diff4 = 2 * Math.PI - forwangle.abs();
          diff4 = diff4.abs();
          if (diff4 < PI38) {
            double mul4 = ((PI38 - diff4) / PI38) *
                ((config.DIST - d) / config.DIST);
            //if we can see an agent close with both eyes in front of us
            blood += mul4 * (1 - a2.health / 2); //remember: health is in [0 2]
            //agents with high life dont bleed. low life makes them bleed more
          }
        }
      });


      smaccum *= a.smellmod;
      soaccum *= a.soundmod;
      hearaccum *= a.hearmod;
      blood *= a.bloodmod;

      a.inputs[0] = cap(p[0]);
      a.inputs[1] = cap(r[0]);
      a.inputs[2] = cap(g[0]);
      a.inputs[3] = cap(b[0]);

      a.inputs[5] = cap(p[1]);
      a.inputs[6] = cap(r[1]);
      a.inputs[7] = cap(g[1]);
      a.inputs[8] = cap(b[1]);
      a.inputs[9] = cap(soaccum);
      a.inputs[10] = cap(smaccum);

      a.inputs[12] = cap(p[2]);
      a.inputs[13] = cap(r[2]);
      a.inputs[14] = cap(g[2]);
      a.inputs[15] = cap(b[2]);
      a.inputs[16] = (Math.sin(modcounter / a.clockf1)).abs();
      a.inputs[17] = (Math.sin(modcounter / a.clockf2)).abs();
      a.inputs[18] = cap(hearaccum);
      a.inputs[19] = cap(blood);

      //temperature varies from 0 to 1 across screen.
      //it is 0 at equator (in middle), and 1 on edges. Agents can sense discomfort
      double dd = 2.0 * (a.pos.x / config.WIDTH - 0.5).abs();
      double discomfort = (dd - a.temperature_preference).abs();
      a.inputs[20] = discomfort;

      a.inputs[21] = cap(p[3]);
      a.inputs[22] = cap(r[3]);
      a.inputs[23] = cap(g[3]);
      a.inputs[24] = cap(b[3]);

    });
  }

  void processOutputs() {
    //assign meaning
    //LEFT RIGHT R G B SPIKE BOOST SOUND_MULTIPLIER GIVING
    // 0    1    2 3 4   5     6         7             8
    agents.forEach((a) {
      a.red = a.outputs[2];
      a.gre = a.outputs[3];
      a.blu = a.outputs[4];
      a.w1 = a.outputs[0]; //-(2*a.out[0]-1);
      a.w2 = a.outputs[1]; //-(2*a.out[1]-1);
      a.boost = a.outputs[6] > 0.5;
      a.soundmul = a.outputs[7];
      a.give = a.outputs[8];

      //spike length should slowly tend towards out[5]
      double g = a.outputs[5];
      if (a.spikeLength < g)
        a.spikeLength += config.SPIKESPEED;
      else if (a.spikeLength > g)
        a.spikeLength = g; //its easy to retract spike, just hard to put it up
    });

    //move bots
    //#pragma omp parallel for
    agents.forEach((a) {
      Vector2 v = new Vector2(config.BOTRADIUS / 2, 0.0);
      //FIXME PORT : why PI/2 here?
      v.postmultiply(new Matrix2.rotation(a.angle + Math.PI / 2));

      Vector2 w1p = a.pos + v; //wheel positions
      Vector2 w2p = a.pos - v;

      double BW1 = config.BOTSPEED * a.w1;
      double BW2 = config.BOTSPEED * a.w2;
      if (a.boost) {
        BW1 = BW1 * config.BOOSTSIZEMULT;
      }
      if (a.boost) {
        BW2 = BW2 * config.BOOSTSIZEMULT;
      }

      //move bots
      Vector2 vv = w2p - a.pos;
      vv.postmultiply(new Matrix2.rotation(-BW1));
      a.pos = w2p - vv;
      a.angle -= BW1;
      if (a.angle < -Math.PI) a.angle = Math.PI - (-Math.PI - a.angle);
      vv = a.pos - w1p;
      vv.postmultiply(new Matrix2.rotation(BW2));
      a.pos = w1p + vv;
      a.angle += BW2;
      if (a.angle > Math.PI) a.angle = -Math.PI + (a.angle - Math.PI);

      //wrap around the map
      if (a.pos.x < 0) a.pos.x = config.WIDTH + a.pos.x;
      if (a.pos.x >= config.WIDTH) a.pos.x = a.pos.x - config.WIDTH;
      if (a.pos.y < 0) a.pos.y = config.HEIGHT + a.pos.y;
      if (a.pos.y >= config.HEIGHT) a.pos.y = a.pos.y - config.HEIGHT;
    });

    //process food intake for herbivors
    agents.forEach((agent) {
      int cx = agent.pos.x ~/ config.CZ;
      int cy = agent.pos.y ~/ config.CZ;
      double f = food.get(cx, cy);
      if (f > 0 && agent.health < 2) {
        //agent eats the food
        double itk = Math.min(f, config.FOODINTAKE);
        double speedmul = (1 - (agent.w1.abs() + agent.w2.abs()) / 2) * 0.7 +
            0.3;
        itk = itk * agent.herbivore *
            speedmul; //herbivores gain more from ground food
        agent.health += itk;
        agent.repcounter -= 3 * itk;
        var t = food.get(cx, cy) - Math.min(f, config.FOODWASTE);
        food.set(cx, cy, t);
      }
    });

    //process giving and receiving of food
    agents.forEach((a) {
      a.dfood = 0.0;
    });

    agents.forEach((giver) {
      if (giver.give > 0.5) {
        agents.forEach((receiver) {
          double d = (giver.pos - receiver.pos).length;
          if (d < config.FOOD_SHARING_DISTANCE) {
            //initiate transfer
            if (receiver.health < 2) receiver.health += config.FOODTRANSFER;
            giver.health -= config.FOODTRANSFER;
            receiver.dfood += config.FOODTRANSFER; //only for drawing
            giver.dfood -= config.FOODTRANSFER;
          }
        });
      }
    });

    //process spike dynamics for carnivors
    if (modcounter % 2 ==
        0) { //we dont need to do this TOO often. can save efficiency here since this is n^2 op in #agents
      agents
          .where((agent) {
        //NOTE: herbivore cant attack. TODO: hmmmmm
        //fot now ok: I want herbivores to run away from carnivores, not kill them back
        return !(agent.herbivore > 0.8 || agent.spikeLength < 0.2 ||
            agent.w1 < 0.5 || agent.w2 < 0.5);
      })
          .forEach((agent) {
        agents
            .where((candidate) => candidate != agent)
            .forEach((other) {
          double d = (agent.pos - other.pos).length;

          if (d < 2 * config.BOTRADIUS) {
            //these two are in collision and agent i has extended spike and is going decent fast!
            Vector2 v = new Vector2(1.0, 0.0);
            v.postmultiply(new Matrix2.rotation(agent.angle));

            //FIXME PORT correct angle?
            double diff = angle_between2(v, other.pos - agent.pos);

            if (diff.abs() < Math.PI / 8) {
              //bot i is also properly aligned!!! that's a hit
              //PORT NOTE: mult not used
              //double mult=1.0;
              //if (agent.boost) mult = config.BOOSTSIZEMULT;
              double DMG = config.SPIKEMULT * agent.spikeLength *
                  Math.max(agent.w1.abs(), agent.w2.abs()) *
                  config.BOOSTSIZEMULT;

              other.health -= DMG;

              if (agent.health > 2) agent.health = 2; //cap health at 2
              agent.spikeLength = 0.0; //retract spike back down

              agent.initEvent(40 * DMG, 1.0, 1.0,
                  0.0); //yellow event means bot has spiked other bot. nice!

              Vector2 v2 = new Vector2(1.0, 0.0);
              v2.postmultiply(new Matrix2.rotation(other.angle));
              //FIXME PORT correct angle?
              double adiff = angle_between2(v, v2);
              if (adiff.abs() < Math.PI / 2) {
                //this was attack from the back. Retract spike of the other agent (startle!)
                //this is done so that the other agent cant right away "by accident" attack this agent
                other.spikeLength = 0.0;
              }

              other.spiked =
              true; //set a flag saying that this agent was hit this turn
            }
          }
        });
      });
    }
  }

  //takes inputs[] to outputs[] for every agent
  void brainsTick() {
    //#pragma omp parallel for
    agents.forEach((a) => a.tick());
  }

  void writeReport() {
    //FIXME - NOT PORTED - ORIGINAL CODE WAS COMMENTED OUT
    //TODO fix reporting
    //save all kinds of nice data stuff
    //     int numherb=0;
    //     int numcarn=0;
    //     int topcarn=0;
    //     int topherb=0;
    //     for(int i=0;i<agents.size();i++){
    //         if(agents[i].herbivore>0.5) numherb++;
    //         else numcarn++;
    //
    //         if(agents[i].herbivore>0.5 && agents[i].gencount>topherb) topherb= agents[i].gencount;
    //         if(agents[i].herbivore<0.5 && agents[i].gencount>topcarn) topcarn= agents[i].gencount;
    //     }
    //
    //     FILE* fp = fopen("report.txt", "a");
    //     fprintf(fp, "%i %i %i %i\n", numherb, numcarn, topcarn, topherb);
    //     fclose(fp);
  }

  void reproduce(Agent agent, double MR, double MR2, List<Agent> newAgents) {
    if (random.bet(0.04)) MR = MR * random.between(1.0, 10.0);
    if (random.bet(0.04)) MR2 = MR2 * random.between(1.0, 10.0);

    agent.initEvent(30.0, 0.0, 0.8, 0.0); //green event means agent reproduced.
    for (int i = 0; i < config.BABIES; i++) {
      Agent a2 = agent.reproduce(MR, MR2);
      a2.id = idcounter;
      idcounter++;
      newAgents.add(a2);

      //TODO fix recording
      //record this
      //FILE* fp = fopen("log.txt", "a");
      //fprintf(fp, "%i %i %i\n", 1, this->id, a2.id); //1 marks the event: child is born
      //fclose(fp);
    }
  }

  int modcounter;
  int current_epoch;
  int idcounter;

  List<Agent> agents = [];

  // food
  int FW;
  int FH;
  int fx;
  int fy;

  Array2D<double> food;
  bool CLOSED; //if environment is closed, then no random bots are added per time interval
}
