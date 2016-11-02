
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

  window.onMouseWheel.listen((WheelEvent e) {
    double direction = e.deltaY < 0.0 ? 1.0 : -1.0;
    view.zoomFactor += 0.1 * direction;
  });


  Point dragStart = null;
  DateTime dragStartTime = new DateTime.now();
  window.onMouseDown.listen((MouseEvent e) {
    if (e.button == 0) dragStart = e.client;
  });

  window.onMouseUp.listen((MouseEvent e) {
    if (e.button == 0 && dragStart != null) {
      view.translate(dragStart, e.client);
      dragStart = null;
    }
  });

  window.onMouseMove.listen((MouseEvent e) {
    if (dragStart != null) {
      var now = new DateTime.now();
      if (now.difference(dragStartTime).inMilliseconds > 100) {
        dragStartTime = now;
        view.translate(dragStart, e.client);
        dragStart = e.client;
      }
    }
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


