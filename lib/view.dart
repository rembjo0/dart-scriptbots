import 'dart:html';
import 'dart:math';
import 'agent.dart';

import 'config.dart' as config;

class View {

  final CanvasRenderingContext2D ctx;


  View(this.ctx);

  void _setViewport() {
    ctx.scale(config.WWIDTH / config.WIDTH, config.WHEIGHT / config.HEIGHT);
  }

  void drawFood(int i, int j, double f) {
    ctx.save();
    try {
      _setViewport();
      ctx.setFillColorRgb(0, 0, 0, f);
      ctx.rect(i, j, config.CZ, config.CZ);
    } finally {
      ctx.restore();
    }
  }

  drawAgent(Agent agent) {
    ctx.save();
    try {
      _setViewport();
      ctx.setFillColorRgb(255, 0, 0);
      ctx.arc(agent.pos.x, agent.pos.y, 10.0, 0.0, 2 * PI);
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
}

