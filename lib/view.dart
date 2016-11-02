import 'dart:html';
import 'dart:math';
import 'agent.dart';
import 'foodmatrix.dart';

import 'config.dart' as config;

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

  double _zoomFactor = 1.0;
  int    _translateX = 0;
  int    _translateY = 0;

  _FoodCanvas foodCanvas;

  View(this.ctx) {
    foodCanvas = new _FoodCanvas();
  }


  void translate(Point start, Point end) {
    _translateX += (end.x - start.x);
    _translateY += (end.y - start.y);
    _clearAndRedrawAll();
  }


  double get zoomFactor => _zoomFactor;

  void set zoomFactor(double f) {
    if (f == _zoomFactor) return;

    //how much does this affect translate? Want to keep center.
    num cw = (_width)/_zoomFactor;
    num ch = (_height)/_zoomFactor;

    num cw2 = (_width)/f;
    num ch2 = (_height)/f;

    _translateX -= (cw-cw2).toInt();
    _translateY -= (ch-ch2).toInt();

    _zoomFactor = f;

    _clearAndRedrawAll();
  }

  void _clearAndRedrawAll () {
    foodCanvas.redrawAll = true;
    foodCanvas.clear();
    clearScreen();
  }

  void canvasResize(int width, int height) {
    _width = width;
    _height = height;
    foodCanvas.canvasResize(_width, _height);
  }


  void _setViewportOnContex(CanvasRenderingContext2D ctx) {
    var viewportScale = min(_width / config.WIDTH, _height / config.HEIGHT);
    ctx.scale(_zoomFactor * viewportScale, _zoomFactor * viewportScale);
    ctx.translate(_translateX, _translateY);
  }

  void _setViewport() {
    _setViewportOnContex(ctx);
  }

  void drawFood(FoodMatrix food) {
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
        for (int c = 0; c < food.numColumns; c++)
          for (int r = 0; r < food.numRows; r++)
            renderCell(c, r, food.get(c, r));

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

    ctx.save();
    try {
      ctx.globalAlpha = 0.2;
      ctx.drawImage(foodCanvas.canvas, 0, 0);
    } finally {
      ctx.restore();
    }
  }

  void drawAgents(List<Agent> agents) {
    ctx.save();
    try {
      _setViewport();
      ctx.setFillColorRgb(0, 0, 255);
      //ctx.setStrokeColorRgb(0, 255, 255);
      for (var agent in agents) {
        ctx.beginPath();
        ctx.arc(agent.pos.x, agent.pos.y, config.BOTRADIUS, 0.0, 2 * PI);
        ctx.fill();
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


