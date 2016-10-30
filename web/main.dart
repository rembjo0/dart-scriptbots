
import 'dart:async';
import 'dart:html';

import 'package:scriptbots/view.dart';
import 'package:scriptbots/world.dart';

void main() {


  CanvasElement mainCanvas = querySelector('#mainCanvas');
  CanvasRenderingContext2D ctx = mainCanvas.getContext('2d');

  View view = new View(ctx);

  var resizeToWindow = () {
    mainCanvas.width = window.innerWidth;
    mainCanvas.height = window.innerHeight;
    view.canvasResize(mainCanvas.width, mainCanvas.height);
  };

  window.onResize.listen((e) {
    resizeToWindow();
  });

  resizeToWindow();

  World world = new World.create();


  void gameLoop(time) {
    bool drawFood = true;

    if (!drawFood) {
      view.clearScreen();
    }

    world.update();
    world.draw(view, drawFood);
    window.requestAnimationFrame(gameLoop);
    //new Future.delayed(new Duration(milliseconds: 100), () => window.requestAnimationFrame(gameLoop));
  }



  window.requestAnimationFrame(gameLoop);
}


