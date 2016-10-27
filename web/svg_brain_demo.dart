// Copyright (c) 2016, Bjørn Vidar Remme. All rights reserved. Use of this source code

// is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:html';
import 'dart:math' as Math;
import 'dart:svg';
import 'package:scriptbots/dwraon_brain.dart';

final int width = window.innerWidth;
final int height = window.innerHeight;


class BrainVisualLayout {

  final DwraonBrain brain;
  final List<Math.Point> positions;

  int nodeDiameter = 20;
  int nodeSpacing = 10;
  int sectionSpacing = 50;

  BrainVisualLayout(DwraonBrain brain)
      :
        this.brain= brain,
        positions = new List(brain.boxes.length);

  int get brainsize => brain.brainsize;

  int get numberOfInputs => brain.numberOfInputs;

  int get numberOfOutputs => brain.numberOfOutputs;

  int get numberOfHidden =>
      brain.brainsize - (numberOfInputs + numberOfOutputs);

  int get nodeRadius => nodeDiameter ~/ 2;

  void recalc() {
    int inputHeight = (numberOfInputs * nodeDiameter)
        + (nodeSpacing * (numberOfInputs - 1));

    int outputHeight = (numberOfOutputs * nodeDiameter)
        + (nodeSpacing * (numberOfOutputs - 1));


    double hiddenRadius = 0.0;
    List<Math.Point> hiddenPoints = new List(0);

    if (numberOfHidden > 0) {
      double hx = 0.0;
      double hy = -nodeRadius.toDouble();

      hiddenPoints = new List(brainsize - numberOfOutputs - numberOfInputs);

      //CALC HIDDEN LAYER
      double hiddenSpacing = nodeSpacing / 2.0;
      for (int i = 0; i < hiddenPoints.length; i++) {
        hiddenPoints[i] = new Math.Point(hx.toInt(), hy.toInt());
        hiddenRadius = Math.sqrt(Math.pow(hx, 2) + Math.pow(hy, 2));
        double c = 2 * hiddenRadius * Math.PI;
        double steps = c / (nodeDiameter + hiddenSpacing);
        double rAdjust = (nodeDiameter + hiddenSpacing) / steps;
        double scale = (hiddenRadius + rAdjust) / hiddenRadius;
        hx *= scale;
        hy *= scale;
        double a = (2 * Math.PI) / steps;
        double x2 = hx * Math.cos(a) - hy * Math.sin(a);
        double y2 = hx * Math.sin(a) + hy * Math.cos(a);
        hx = x2;
        hy = y2;
      }
    }

    int height = Math.max(
        Math.max(inputHeight, outputHeight), (hiddenRadius*2).toInt());
    int inputStartY = inputHeight >= height ? 0 : (height~/2 - inputHeight~/2);
    int outputStartY = outputHeight >= height ? 0 : (height~/2 - outputHeight~/2);
    int hiddenCenterY = height ~/ 2;

    int nx = nodeRadius;
    int ny = nodeRadius + inputStartY;

    //CALC INPUTS
    for (int i = 0; i < numberOfInputs; i++) {
      positions[i] = new Math.Point(nx, ny);
      ny += nodeDiameter + nodeSpacing;
    }

    int hiddenStartX = nodeDiameter + sectionSpacing;
    int hiddenEndX = hiddenStartX;

    if (numberOfHidden > 0) {
      int cx = hiddenStartX + hiddenRadius.toInt();
      int cy = hiddenCenterY;
      hiddenEndX = cx + hiddenRadius.toInt();

      int j = 0;
      for (int i = numberOfInputs; i < brainsize - numberOfOutputs; i++) {
        positions[i] =
        new Math.Point(cx + hiddenPoints[j].x, cy + hiddenPoints[j].y);
        j++;
      }
    }

    nx = hiddenEndX + sectionSpacing;
    ny = nodeRadius + outputStartY;

    for (int i = brainsize - numberOfOutputs; i < brainsize; i++) {
      //print(i);
      positions[i] = new Math.Point(nx, ny);
      ny += nodeDiameter + nodeSpacing;
    }
  }

}


void main() {

  DivElement output = document.getElementById("output");


  var brain = new DwraonBrain.random(
      new DateTime.now().millisecondsSinceEpoch, 50, 4, 5, 3);

  new Animation(output, brain).run(0);

  //var svg2 = new SvgSvgElement();
  //svg2.style.width = "100%";
  //svg2.style.height = "50%";

  //document.body.append(svg2);
  //var brain2 = new DwraonBrain.random(new DateTime.now().millisecondsSinceEpoch+5000, 20, 4, 5, 3);
  //new Animation(svg2, brain2).run(0);
}

class Animation {
  Element output;
  DwraonBrain brain;
  double prev = 0.0;
  int f = 0;
  List<double> inputs;
  List<double> outputs;


  Animation(this.output, this.brain) {
    inputs = new List.filled(brain.numberOfInputs, 0.0);
    outputs = new List.filled(brain.numberOfOutputs, 0.0);
  }

  void run(num t) {
    if (t - prev > 100) {

      while(output.hasChildNodes()) output.lastChild.remove();

      SvgElement svg = new SvgSvgElement();
      svg.style.width = "100%";
      svg.style.height = "100%";
      output.append(svg);

      prev = t;

      if (f % 10 == 0) {
        brain.mutate(0.1, 0.01);
      }

      for (int i=0; i<inputs.length; i++) {
        inputs[i] = this.brain.rand(0.0, 1.0);
      }

      brain.tick(inputs, outputs);
      renderBrain(svg, brain);
    }

    f++;
    window.requestAnimationFrame(run);
  }
}


void renderBrain(SvgElement svg, DwraonBrain brain) {

  var svgContent = new SvgElement.svg('''
<g id="demoSvg" transform="rotate(0 50 50)" >
<line id="line1" x1="0" y1="0" x2="200" y2="200" style="stroke:rgb(255,0,0);stroke-width:2" />
<circle cx="50" cy="50" r="40" style="stroke:green;stroke-width:4;fill:yellow"/>
<text x="15" y="54" font-size="20" style="stroke:black">Hello!</text>
</g>
 ''');
  //svg.append(svgContent);

  var brainSvg = new SvgElement.svg('''
  <g id="brainSvg" transform="translate(25,10) scale(1, 1)"/>
  ''');

  var v = new BrainVisualLayout(brain);

  v.recalc();

  for (int i = 0; i < v.brainsize; i++) {
    Box box = brain.boxes[i];

    int color = Math.min(255, (box.out*255.0).abs().toInt());
    String fill = "rgb(${color},${color},0)";

    if (i >= v.numberOfInputs) {
      if (i < v.brainsize - v.numberOfOutputs) {
        fill = "rgb(0, ${color}, 0)";
      } else {
        fill = "rgb(${color}, 0, 0)";
      }
    }

    brainSvg.append(new SvgElement.svg('''
  <circle cx="${v.positions[i].x}" cy="${v.positions[i].y}" r="${v.nodeRadius}"
  style="stroke:gray;stroke-width:1;fill:${fill}"/>
  '''));

    bool drawLines = true;
    if (drawLines && i >= brain.numberOfInputs) {
      Math.Point pos = v.positions[i];
      for (int j = 0; j < box.id.length; j++) {
        if (i != j) { // need to visualize connections to self in some other way
          Math.Point other = v.positions[box.id[j]];
          double w = box.w[j].abs();
          String stroke = box.notted[j] ? "rgb(255,0,0)" : "rgb(0, 0, 255)";
          brainSvg.append(new SvgElement.svg('''
<line x1="${pos.x}" y1="${pos.y}" x2="${other.x}" y2="${other.y}"
style="stroke:${stroke};stroke-width:${w};stroke-opacity: 0.2" />
          '''));
        }
      }
    }
  }

  svg.append(brainSvg);
}

