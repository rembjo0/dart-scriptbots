import 'dart:html';
import 'dart:math';
import 'agent.dart';

import 'config.dart' as config;

class View {

  int _width = 0;
  int _height = 0;

  final CanvasRenderingContext2D ctx;

  View(this.ctx);

  void canvasResize(int width, int height) {
    _width = width;
    _height = height;
  }

  void _setViewport() {
    ctx.scale(_width / config.WIDTH, _height / config.HEIGHT);
  }

  void drawFood(int column, int row, double quantity) {
    ctx.save();
    try {
      _setViewport();
      var f = (255.0*(1.0-quantity)).toInt();
      ctx.setFillColorRgb(f, f, f);
      ctx.fillRect(column*config.CZ, row*config.CZ, config.CZ, config.CZ);
      ctx.stroke();
    } finally {
      ctx.restore();
    }
  }

  drawAgent(Agent agent) {
    ctx.save();
    try {
      _setViewport();
      ctx.beginPath();
      ctx.setFillColorRgb(255, 0, 0);
      ctx.arc(agent.pos.x, agent.pos.y, 10.0, 0.0, 2 * PI);
      ctx.stroke();
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

