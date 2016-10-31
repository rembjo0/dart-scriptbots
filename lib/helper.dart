
import 'dart:math' as Math;
import 'package:quiver/core.dart';
import 'package:vector_math/vector_math.dart';

/**
 * cap double value between 0 and 1
 */
double cap(double a){
  if (a<0.0) return 0.0;
  if (a>1.0) return 1.0;
  return a;
}

/**
 * From: https://github.com/dart-lang/collection/issues/29
 */
class Pair<T1,T2> {
  final T1 first;
  final T2 second;
  Pair(this.first, this.second);

  bool operator==(final Pair other) {
    return first == other.first && second == other.second;
  }
  int get hashCode => hash2(first.hashCode,second.hashCode);
}

class Array2<T> {
  final int numColumns;
  final int numRows;
  final List<T> _storage;

  Array2 (int numColumns, int numRows)
      : numColumns = numColumns,
        numRows = numRows,
        _storage = _initStorage(numColumns, numRows);


  void set(int c, int r, T v) {
    assert(c > -1 && c < numColumns);
    assert(r > -1 && r < numRows);

    _storage[c + (numColumns*r)] = v;
  }

  T get(int c, int r) {
    assert(c > -1 && c < numColumns);
    assert(r > -1 && r < numRows);

    return _storage[c + (numColumns*r)];
  }


  static List _initStorage(int c, int r) {
    assert(c > 0);
    assert(r > 0);

    return new List(c*r);
  }

}


double angle_between2(Vector2 a, Vector2 b) {
  return Math.atan2(a.cross(b), a.dot(b));
}



void main () {

  Vector2 a = new Vector2(0.0, 1.0);
  Vector2 b = new Vector2(1.0, 0.0);
  double angle = angle_between2(a, b);

  var v = new Vector2(0.0, 1.0)..postmultiply(new Matrix2.rotation(-angle));

  print ("-- angle ${angle}");
  print ("-- rotated ${v}");


  Array2<String> a2d = new Array2(5, 3);

  for (int r=0; r<a2d.numRows; r++) {
    for (int c=0; c<a2d.numColumns; c++) {
      a2d.set(c, r, "${c}x${r}");
    }
  }

  for (int r=0; r<a2d.numRows; r++) {
    List row = [];
    for (int c=0; c<a2d.numColumns; c++) {
      row.add(a2d.get(c, r));
    }
    print(row.join(' '));
  }

}
