
import 'dart:math' as Math;

int get _msSinceEpoch => new DateTime.now().millisecondsSinceEpoch;

int _newSeedIfNull(int seed) => seed != null ? seed : _msSinceEpoch;


class Randomization {
  final int seed;

  final Math.Random _rand;

  Randomization._internal (int seed)
      : seed = seed,
        _rand = new Math.Random(seed);

  Randomization([int seed]) : this._internal(_newSeedIfNull(seed));

  /** true with a given probability, 0.2 is 20% chance of true */
  bool bet(double p) => _rand.nextDouble() < p;

  bool fiftyFifty() => bet(0.5);

  /** [0.0, 1.0) */
  double next() => _rand.nextDouble();

  /** [min, max) */
  int nextInt(int max) => _rand.nextInt(max);

  /** [min, max) */
  double between(double min, double max) {
    assert(max > min);
    return min + (_rand.nextDouble() * (max - min));
  }

  /** [min, max) */
  int betweenInt(int min, int max) {
    assert(max > min);
    return min + (_rand.nextInt(max - min));
  }


  bool _deviateAvailable=false;	//	flag
  double _storedDeviate;			//	deviate from previous calculation

  /**
   * normalvariate random N(mu, sigma)
   */
  double randn(double mu, double sigma) {

    double polar, rsquared, var1, var2;
    if (!_deviateAvailable) {
      do {
        var1=2.0*( _rand.nextDouble() ) - 1.0;
        var2=2.0*( _rand.nextDouble() ) - 1.0;
        rsquared=var1*var1+var2*var2;
      } while ( rsquared>=1.0 || rsquared == 0.0);
      polar= Math.sqrt(-2.0*Math.log(rsquared)/rsquared);
      _storedDeviate=var1*polar;
      _deviateAvailable=true;
      return var2*polar*sigma + mu;
    }
    else {
      _deviateAvailable=false;
      return _storedDeviate*sigma + mu;
    }
  }

}



void main () {
  Randomization r = new Randomization();

  Map<double, int> d = {};

  for (int i=0; i<1000; i++) {
    var x = r.randn(0.1, 0.6);
    x = (x*10).floorToDouble()/10.0;
    var v = d[x] ?? 0;
    d[x] = v+1;
  }

  var l = d.keys.toList()..sort();
  l.forEach((k) {
    var s = new List.filled(d[k], '*').join();
    print("${k}\t\t${s}");
  });
}
