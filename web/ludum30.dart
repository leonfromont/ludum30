import 'dart:html';
import 'package:ad/ad.dart';

class Types {
  static int PLAYERBULLET = 0;
  static int RENDER = 1;
  static int POSITION = 2;
}

abstract class Component {
  int TAG;
}

class PlayerBullet extends Component {
  int TAG = Types.PLAYERBULLET;
  
  num cooldown;
  num dt;

  bool get canFire => cooldown <= 0.0;

  PlayerBullet(num dt) {
    this.cooldown = dt;
    this.dt = dt;
  }
}

class Render extends Component {
  Rect spritesheet;
  Render(this.spritesheet);
}

class SpriteSheet {
  static Rect player = new Rect(0, 34, 34, 68);
  static Rect bullet = new Rect(0, 0, 34, 34);
}

ImageElement el = new ImageElement();


class MyState extends State { 
  List entities = [];
  var player = null;
  
  Rect a = new Rect(0, 0, 32, 32);
  Rect b = new Rect(64, 0, 32, 32);
  
  Path path = new Path.once(
            [new Vector(0, 44),  new Vector(0, 128)],
            3.0);
  
  MyState() {
    el.src = './spritesheet.png';
    var e = {
            Types.RENDER : new Render(SpriteSheet.player),
            Types.POSITION : new Vector(0, 0)
    };

    entities.add(e);
    player = e;
  }
  
  void update (num dt) {
    
    path.update(dt / 1000.0);
    
    if(parent.currentlyPressedKeys.contains(KeyCode.A)) {
      player[Types.POSITION].x -= 1;
    }
    if(parent.currentlyPressedKeys.contains(KeyCode.D)) {
      player[Types.POSITION].x += 1;
    }
    if(parent.currentlyPressedKeys.contains(KeyCode.W)) {
      player[Types.POSITION].y -= 1;
    }
    if(parent.currentlyPressedKeys.contains(KeyCode.S)) {
      player[Types.POSITION].y += 1;
    }
    
    if(parent.currentlyPressedKeys.contains(KeyCode.SPACE)) {
      var e = {
               Types.PLAYERBULLET :  new PlayerBullet(1.0),
               Types.RENDER : new Render(new Rect(0, 0, 32, 32)),
               Types.POSITION : new Vector(128, 128)
      };
      
      entities.add(e);
    }
  }
  
  void render(CanvasRenderingContext2D ctx) {
    ctx.clearRect(0, 0, 512, 256);
    
    for (var e in entities) {
      if (e[Types.RENDER] != null && e[Types.POSITION] != null) {
        Render r = e[Types.RENDER];
        ctx.drawImageScaledFromSource(el, 
            r.spritesheet.left, 
            r.spritesheet.top, 
            r.spritesheet.width, 
            r.spritesheet.height, 
            e[Types.POSITION].x, 
            e[Types.POSITION].y, 
            r.spritesheet.width, 
            r.spritesheet.height);
      }
    }
    
    
    
    ctx.fillStyle = '#ff0000';
    ctx.fillRect(a.left, a.top, a.right, a.bottom);

    ctx.fillStyle = '#ff0000';
    ctx.fillRect(b.left, b.top, b.width, b.height);
    
    var pos = path.currentPoint();
    ctx.fillStyle = '#00ff00';
    ctx.fillRect(pos.x.toInt(), pos.y.toInt(), 8, 8);
    
    ctx.fillRect(path.a.x, path.a.y, 4, 4);
    ctx.fillRect(path.b.x, path.b.y, 4, 4);
    
    //ctx.drawImage(el, 0, 0);
    
    
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
