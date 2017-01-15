
const int INPUTSIZE = 25;
const int OUTPUTSIZE = 9;
const int NUMEYES = 4;
const int BRAINSIZE = 200;
const int CONNS = 4;

const int WIDTH = 6000*2;  //width and height of simulation
const int HEIGHT = 3000*2;

const int CZ = 50; //cell size in pixels, for food squares. Should divide well into Width Height

const int NUMBOTS=70; //initially, and minimally
const double BOTRADIUS=10.0; //for drawing
const double BOTSPEED= 0.3;
const double SPIKESPEED= 0.005; //how quickly can attack spike go up?
const double SPIKEMULT= 1.0; //essentially the strength of every spike impact
const int BABIES=2; //number of babies per agent when they reproduce
const double BOOSTSIZEMULT=2.0; //how much boost do agents get? when boost neuron is on
const double REPRATEH=7.0; //reproduction rate for herbivors
const double REPRATEC=7.0; //reproduction rate for carnivors

const double DIST= 150.0;		//how far can the eyes see on each bot?
const double METAMUTRATE1= 0.002; //what is the change in MUTRATE1 and 2 on reproduction? lol
const double METAMUTRATE2= 0.05;

const double FOODINTAKE= 0.002; //how much does every agent consume?
const double FOODWASTE= 0.001; //how much food disapears if agent eats?
const double FOODMAX= 0.5; //how much food per cell can there be at max?
const int FOODADDFREQ= 4; //(15 default) how often does random square get to full food?

const double FOODTRANSFER= 0.001; //how much is transfered between two agents trading food? per iteration
const double FOOD_SHARING_DISTANCE= 50.0; //how far away is food shared between bots?

const double TEMPERATURE_DISCOMFORT = 0.0; //how quickly does health drain in nonpreferred temperatures (0= disabled. 0.005 is decent value)

const double FOOD_DISTRIBUTION_RADIUS=100.0; //when bot is killed, how far is its body distributed?

const double REPMULT = 5.0; //when a body of dead animal is distributed, how much of it goes toward increasing birth counter for surrounding bots?
