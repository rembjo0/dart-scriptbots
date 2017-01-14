
import 'dart:html';

import 'package:scriptbots/view.dart';
import 'package:scriptbots/world.dart';

void main() {

  HtmlElement fpsOuput = querySelector("#fpsOut");
  HtmlElement simSpeedOutput = querySelector("#simSpeedOutput");

  CanvasElement mainCanvas = querySelector('#mainCanvas');
  CanvasRenderingContext2D ctx = mainCanvas.getContext('2d');

  int simSpeed = 1;
  View view = new View(ctx);
  World world = new World.create();

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
    var f = view.zoomFactor * 0.2;
    view.zoomFactor += f * direction;
  });


  Point dragStart = null;
  DateTime dragStartTime = new DateTime.now();
  window.onMouseDown.listen((MouseEvent e) {
    if (e.button == 0) dragStart = e.client;
  });

  window.onMouseUp.listen((MouseEvent e) {
    if (e.button == 0 && dragStart != null) {
      view.translateScreen(dragStart, e.client);
      dragStart = null;
    }
  });

  window.onMouseMove.listen((MouseEvent e) {
    if (dragStart != null) {
      var now = new DateTime.now();
      if (now.difference(dragStartTime).inMilliseconds > 100) {
        dragStartTime = now;
        view.translateScreen(dragStart, e.client);
        dragStart = e.client;
      }
    }
  });

  const KEY_PAGE_UP = 33;
  const KEY_PAGE_DOWN = 34;
  const KEY_HOME = 36;
  const KEY_A = 65;
  const KEY_C = 67;
  const KEY_F = 70;
  const KEY_H = 72;
  const KEY_Q = 81;
  const KEY_1 = 49;
  const KEY_2 = 50;

  window.onKeyUp.listen((KeyboardEvent e) {
    switch (e.which) {
      case KEY_1:
        view.reduceBackgroundAlpha();
        break;
      case KEY_2:
        view.increaseBackgroundAlpha();
        break;
      case KEY_PAGE_UP:
        if (simSpeed < 16) simSpeed *= 2;
        break;
      case KEY_PAGE_DOWN:
        if (simSpeed > 1) simSpeed ~/= 2;
        break;
      case KEY_HOME:
        simSpeed = 1;
        break;
      case KEY_F:
        world.toggleFoodDrawing();
        break;
      case KEY_C:
        world.setClosed(!world.isClosed());
        print("-- world closed = ${world.isClosed()}");
        break;
      case KEY_A:
        for (int i=0; i<10; i++) world.addNewByCrossover();
        print(" -- added new bots by crossover");
        break;
      case KEY_Q:
        for (int i=0; i<10; i++) world.addCarnivore();
        print(" -- added new carnivores");
        break;
      case KEY_H:
        for (int i=0; i<10; i++) world.addHerbivore();
        print("-- added new herbivores");
        break;
      default:
        print("-- no action for key: ${e.which}");
    }

    simSpeedOutput.text = "x${simSpeed}";
  });


  resizeToWindow();

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

    if (frameCount > 10) {
      frameCount = 0;
      elapsedTotal = 0;
    }
  }

  void gameLoop(time) {

    for (int i=0; i<simSpeed; i++) {
      world.update();
    }

    world.draw(view);

    updateFPS();

    window.requestAnimationFrame(gameLoop);
    //new Future.delayed(new Duration(milliseconds: 100), () => window.requestAnimationFrame(gameLoop));
  }

  window.requestAnimationFrame(gameLoop);
}


