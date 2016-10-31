
import 'dart:html';

import 'package:scriptbots/view.dart';
import 'package:scriptbots/world.dart';

void main() {

  HtmlElement fpsOuput = querySelector("#fpsOut");

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

  int  now () => new DateTime.now().millisecondsSinceEpoch;
  int lastFrameTime = now();
  int frameCount = 0;
  int elapsedTotal = 0;

  void updateFPS () {
    var frameTime = now();
    var elapsed = frameTime-lastFrameTime;
    lastFrameTime = frameTime;

    frameCount++;
    elapsedTotal += elapsed;
    var avgElapsed = elapsedTotal~/frameCount;
    fpsOuput.text = (1000~/avgElapsed).toString();

    if (frameCount > 1000) {
      frameCount = 0;
      elapsedTotal = 0;
    }
  }

  void gameLoop(time) {
    bool drawFood = true;

    if (!drawFood) {
      view.clearScreen();
    }

    world.update();
    world.draw(view, drawFood);

    updateFPS();

    window.requestAnimationFrame(gameLoop);
    //new Future.delayed(new Duration(milliseconds: 100), () => window.requestAnimationFrame(gameLoop));
  }



  window.requestAnimationFrame(gameLoop);
}


