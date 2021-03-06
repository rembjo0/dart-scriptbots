import 'dart:html';
import 'dart:math';
import 'agent.dart';
import 'foodviewmodel.dart';

import 'config.dart' as config;
import 'helper.dart' show cap;

class _OffscreenCanvas {
  CanvasElement canvas;
  CanvasRenderingContext2D ctx;

  _OffscreenCanvas({int width, int height}) {
    canvas = new CanvasElement(width: width, height: height);
    ctx = canvas.getContext('2d');
  }

  int get width => canvas.width;
  int get height => canvas.height;

  void canvasResize(int width, int height) {
    canvas.width = width;
    canvas.height = height;
  }

  void clear() {
    ctx.save();
    try {
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      //ctx.setFillColorRgb(255, 255, 255);
      ctx.clearRect(0, 0, canvas.width, canvas.height);
    } finally {
      ctx.restore();
    }
  }
}


class _FoodCanvas extends _OffscreenCanvas {

  bool redrawAll = true;

  void canvasResize(int width, int height) {
    redrawAll = true;
    super.canvasResize(width, height);
  }
}


class View {

  final CanvasRenderingContext2D ctx;

  int _width = 0;
  int _height = 0;

  double _backgroundAlpha = 1.0;
  double _scale = 1.0;
  double _zoomFactor = 1.0;
  int _translateX = 0;
  int _translateY = 0;

  _FoodCanvas foodCanvas;

  View(this.ctx) {
    foodCanvas = new _FoodCanvas();
  }


  void reduceBackgroundAlpha() {
    _backgroundAlpha = _backgroundAlpha * 0.75;
    if (_backgroundAlpha < 0.1) _backgroundAlpha = 0.05;
    print("-- backgroundAlpha ${_backgroundAlpha}");
  }

  void increaseBackgroundAlpha() {
    _backgroundAlpha = _backgroundAlpha * 1.25;
    if (_backgroundAlpha > 1.0) _backgroundAlpha = 1.0;
    print("-- backgroundAlpha ${_backgroundAlpha}");
  }

  void translateScreen(Point start, Point end) {
    Point t = screenToScene(end) - screenToScene(start);
    setSceneTranslate(_translateX + t.x, _translateY + t.y);
  }

  void centerSceneAt(int x, int y) {
    Point s = sceneToScreen(new Point(x, y));
    Point c = new Point(_width~/2, _height~/2);
    translateScreen(s, c);
  }

  void setSceneTranslate(int x, int y) {
    _translateX = x;
    _translateY = y;
    _clearAndRedrawAll();
  }

  void _updateScale() {
    var viewportScale = min(_width / config.WIDTH, _height / config.HEIGHT);
    _scale = _zoomFactor * viewportScale;
  }

  double get zoomFactor => _zoomFactor;

  void set zoomFactor(double f) {
    if (f == _zoomFactor) return;

    var screenCenter = new Point(_width ~/ 2, _height ~/ 2);
    Point<int> oldCenter = screenToScene(screenCenter);

    _zoomFactor = max(0.1, f);
    _updateScale();

    Point<int> newCenter = screenToScene(screenCenter);

    _translateX -= oldCenter.x - newCenter.x;
    _translateY -= oldCenter.y - newCenter.y;

    _clearAndRedrawAll();
  }

  void _clearAndRedrawAll() {
    foodCanvas.redrawAll = true;
    foodCanvas.clear();
    clearScreen();
  }

  void canvasResize(int width, int height) {
    _width = width;
    _height = height;
    _updateScale();
    foodCanvas.canvasResize(_width, _height);
  }

  Point<int> screenToScene(Point p) {
    double x = (p.x / _scale) - _translateX;
    double y = (p.y / _scale) - _translateY;
    return new Point(x.toInt(), y.toInt());
  }

  Point<int> sceneToScreen(Point p) {
    double x = (p.x + _translateX) * _scale;
    double y = (p.y + _translateY) * _scale;
    return new Point(x.toInt(), y.toInt());
  }

  void _setViewportOnContex(CanvasRenderingContext2D ctx) {
    ctx.scale(_scale, _scale);
    ctx.translate(_translateX, _translateY);
  }

  void _setViewport() {
    _setViewportOnContex(ctx);
  }

 void renderEmptyFoodCanvas () {
   foodCanvas.ctx.save();
   try {
     foodCanvas.ctx.setFillColorRgb(255, 255, 255);
     foodCanvas.ctx.fillRect(0, 0, foodCanvas.width, foodCanvas.height);
   } finally {
     foodCanvas.ctx.restore();
   }
 }

  void drawFood(FoodViewModel food) {

    if (food.isFoodDrawingEnabled())
      renderFoodCells(food);
    else
      renderEmptyFoodCanvas();

    ctx.save();
    try {
      ctx.globalAlpha = _backgroundAlpha;
      ctx.drawImage(foodCanvas.canvas, 0, 0);
    } finally {
      ctx.restore();
    }
  }

  void renderFoodCells(FoodViewModel food) {
       var renderCell = (x, y, q) {
      double v = 0.5 * q / config.FOODMAX;
      var f = (255.0 * (1.0 - v)).toInt();
      foodCanvas.ctx.setFillColorRgb(f, f, f);
      //foodCanvas.ctx.setStrokeColorRgb(0, 0, 255);
      foodCanvas.ctx.fillRect(
          x * config.CZ, y * config.CZ, config.CZ, config.CZ);
    };

    foodCanvas.ctx.save();
    try {
      _setViewportOnContex(foodCanvas.ctx);

      if (foodCanvas.redrawAll || food.allDirty) {
        foodCanvas.ctx.setFillColorRgb(255, 255, 255);
        foodCanvas.ctx.fillRect(0, 0, foodCanvas.width, foodCanvas.height);
        for (int x = 0; x < food.width; x++)
          for (int y = 0; y < food.height; y++)
            renderCell(x, y, food.get(x, y));

        food.clearAllDirty();
      } else {
        for (var cell in food.takeDirtyCells()) {
          renderCell(cell.x, cell.y, food.get(cell.x, cell.y));
        }
      }

      foodCanvas.redrawAll = false;
    } finally {
      foodCanvas.ctx.restore();
    }
  }

  void drawAgents(List<Agent> agents) {
    ctx.save();
    try {
      _setViewport();

      for (var agent in agents) {

        //draw event indicator
        if (agent.indicator > 0) {
          var radius = config.BOTRADIUS + agent.indicator.toInt();
          ctx.setFillColorRgb(
              (agent.ir * 200.0).toInt(), (agent.ig * 200.0).toInt(),
              (agent.ib * 200.0).toInt(), 0.5);
          ctx.beginPath();
          ctx.arc(agent.pos.x, agent.pos.y, config.BOTRADIUS + agent.indicator, 0.0, 2 * PI);
          ctx.fill();
        }

        // draw body
        ctx.setFillColorRgb(
            (agent.red * 200.0).toInt(), (agent.gre * 200.0).toInt(),
            (agent.blu * 200.0).toInt());
        ctx.beginPath();
        ctx.arc(agent.pos.x, agent.pos.y, config.BOTRADIUS, 0.0, 2 * PI);
        ctx.fill();

        //draw food share
        if (agent.dfood != 0) {
          double mag=cap(agent.dfood.abs()/config.FOODTRANSFER/3);

          if(agent.dfood>0)
            ctx.setStrokeColorRgb(0,(255*mag).toInt(),0); //draw boost as green outline
          else
            ctx.setStrokeColorRgb((255*mag).toInt(), 0, 0);

          ctx.beginPath();
          ctx.lineWidth = 4;
          ctx.arc(agent.pos.x, agent.pos.y, config.BOTRADIUS+2, 0.0, 2 * PI);
          ctx.stroke();
        }

        if (agent.boost) {
          ctx.lineWidth = 1;
          ctx.setStrokeColorRgb(0, 0, 255);
          ctx.arc(agent.pos.x, agent.pos.y, config.BOTRADIUS+1, 0.0, 2 * PI);
          ctx.stroke();
        }

        if (agent.herbivore < 0.5) {
          ctx.beginPath();
          ctx.lineWidth = 1;
          ctx.setStrokeColorRgb(255, 0, 0);
          double endAngle = (0.5 + agent.herbivore) * 1.8 * PI;
          ctx.arc(agent.pos.x, agent.pos.y, config.BOTRADIUS+5, -agent.angle+0.3, -agent.angle+0.3 + endAngle);
          ctx.stroke();
        }


        //draw eyes
        ctx.lineWidth = 1;
        ctx.setStrokeColorRgb(0, 0, 255, 0.5);
        ctx.beginPath();
        for(int q=0;q<config.NUMEYES;q++) {
          ctx.moveTo(agent.pos.x,agent.pos.y);
          double aa= agent.angle+agent.eyedir[q];
          //PORT: must use -sin (lefthanded, righthanded coord system thing?)
          ctx.lineTo(agent.pos.x+(config.BOTRADIUS*4)*cos(aa),
              agent.pos.y+(config.BOTRADIUS*4)*-sin(aa));
        }
        ctx.stroke();

        //draw spike
        double r = config.BOTRADIUS;
        ctx.lineWidth = 2;
        ctx.setStrokeColorRgb(200,0,0);
        ctx.beginPath();
        ctx.moveTo(agent.pos.x,agent.pos.y);
        //PORT: must use -sin (lefhenaded, rightanded coord system thing?)
        ctx.lineTo(agent.pos.x+(3*r*agent.spikeLength)*cos(agent.angle),agent.pos.y+(3*r*agent.spikeLength)*-sin(agent.angle));
        ctx.stroke();
      }
    } finally {
      ctx.restore();
    }
  }

  void drawMisc() {
    ctx.save();
    try {
      _setViewport();
    } finally {
      ctx.restore();
    }
  }

  void clearScreen() {
    ctx.save();
    try {
      ctx.setTransform(1, 0, 0, 1, 0, 0);
      ctx.setFillColorRgb(255, 255, 255);
      ctx.fillRect(0, 0, _width, _height);
    } finally {
      ctx.restore();
    }
  }


}


