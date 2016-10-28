
import 'dart:html';

void main() {


  CanvasElement mainCanvas = querySelector('#mainCanvas');
  CanvasRenderingContext2D ctx = mainCanvas.getContext('2d');

  var resizeToWindow = () {
    mainCanvas.width = window.innerWidth;
    mainCanvas.height = window.innerHeight;
  };

  var clearScreen = () {
    ctx.save();
    ctx.setFillColorRgb(200, 200, 200);
    ctx.fillRect(0, 0, window.innerWidth, window.innerHeight);
    //ctx.clearRect(0, 0, window.innerWidth, window.innerHeight);
    ctx.beginPath();
    ctx.setStrokeColorRgb(0, 0, 255);
    ctx.lineWidth = 5;
    ctx.moveTo(0, 0);
    ctx.lineTo(mainCanvas.width, mainCanvas.height);
    ctx.stroke();
    ctx.restore();
  };

  window.onResize.listen((e) {
    resizeToWindow();
    clearScreen();
  });


  resizeToWindow();
  clearScreen();
}


