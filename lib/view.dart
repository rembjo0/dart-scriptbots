import 'dart:html';
import 'dart:math';
import 'agent.dart';
import 'foodmatrix.dart';

import 'config.dart' as config;

class _OffscreenCanvas {
  CanvasElement canvas;
  CanvasRenderingContext2D ctx;

  _OffscreenCanvas ({int width, int height}) {
    canvas = new CanvasElement(width: width, height: height);
    ctx = canvas.getContext('2d');
  }

  int get width => canvas.width;
  int get height => canvas.height;

  void canvasResize(int width, int height) {
    canvas.width = width;
    canvas.height = height;
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

  _FoodCanvas foodCanvas;

  View(this.ctx) {
    foodCanvas = new _FoodCanvas();
  }

  void canvasResize(int width, int height) {
    _width = width;
    _height = height;
    foodCanvas.canvasResize(_width, _height);
  }

  void _setViewportOnContex(var ctx) {
    ctx.scale(_width / config.WIDTH, _height / config.HEIGHT);
  }

  void _setViewport() {
    _setViewportOnContex(ctx);
  }

  void drawFood(FoodMatrix food) {

    var renderCell = (x, y, q) {
      double v = 0.5 * q / config.FOODMAX;
      var f = (255.0*(1.0-v)).toInt();
      foodCanvas.ctx.setFillColorRgb(f, f, f);
      //foodCanvas.ctx.setStrokeColorRgb(0, 0, 255);
      foodCanvas.ctx.fillRect(x*config.CZ, y*config.CZ, config.CZ, config.CZ);
    };

    foodCanvas.ctx.save();
    try {
      _setViewportOnContex(foodCanvas.ctx);

      if (foodCanvas.redrawAll || food.allDirty) {
        foodCanvas.ctx.setFillColorRgb(255, 255, 255);
        foodCanvas.ctx.fillRect(0, 0, foodCanvas.width, foodCanvas.height);
        for (int c=0; c<food.numColumns; c++)
            for (int r=0; r<food.numRows; r++)
                renderCell(c, r, food.get(c, r));

        food.clearAllDirty();
      } else {
      for (var cell in food.takeDirtyCells()) {
        renderCell(cell.x, cell.y, food.get(cell.x, cell.y));
      }}

      foodCanvas.redrawAll = false;
    } finally {
      foodCanvas.ctx.restore();
    }

    ctx.drawImage(foodCanvas.canvas, 0, 0);
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

  void clearScreen () {
    ctx.save();
    try {
      ctx.setFillColorRgb(255, 255, 255);
      ctx.fillRect(0, 0, window.innerWidth, window.innerHeight);
      //ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);
      //ctx.beginPath();
      //ctx.setStrokeColorRgb(0, 0, 255);
      //ctx.lineWidth = 5;
      //ctx.moveTo(0, 0);
      //ctx.lineTo(_width, _height);
      //ctx.stroke();
    } finally {
      ctx.restore();
    }
  }


}

