import 'dart:html';
import 'package:ad/ad.dart';

class MyState extends State {
  Rect a = new Rect(0, 0, 32, 32);
  Rect b = new Rect(64, 0, 32, 32);
  
  void update (num dt) {
    
    print(parent.FPS);
    
    if(parent.currentlyPressedKeys.contains(KeyCode.A)) {
      b.left -= 1;
    }
    if(parent.currentlyPressedKeys.contains(KeyCode.D)) {
      b.left += 1;
    }
    if(parent.currentlyPressedKeys.contains(KeyCode.W)) {
      b.top -= 1;
    }
    if(parent.currentlyPressedKeys.contains(KeyCode.S)) {
      b.top += 1;
    }
  }
  
  void render(CanvasRenderingContext2D ctx) {
    ctx.clearRect(0, 0, 512, 256);
    
    ctx.fillStyle = '#ff0000';
    ctx.fillRect(a.left, a.top, a.right, a.bottom);

    ctx.fillStyle = '#ff0000';
    ctx.fillRect(b.left, b.top, b.width, b.height);
    
    
    ctx.font="20px Georgia";
    ctx.fillStyle = '#00ff00';
    //ctx.fillText("ASD", 32, 32);
    if(a.collide(b)) {
      ctx.fillText("YES", 32, 32);
    } else {
      ctx.fillText("NO", 32, 32);
    }
  }
}

void main() {
  Ad ad = new Ad('screen', new MyState());
}
