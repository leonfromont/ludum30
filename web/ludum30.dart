import 'dart:html';
import 'package:ad/ad.dart';

class MyState extends State {
  void update (num dt) {
    
  }
  
  void render(CanvasRenderingContext2D ctx) {
    ctx.fillStyle = 'ff0000';
    ctx.fillRect(0, 0, 32, 32);
  }
}

void main() {
  Ad ad = new Ad('screen', new MyState());
}
