import 'dart:html';
import 'package:ad/ad.dart';

class Aspect {
  List<int> types;

  Aspect(this.types);

  bool match(var e) {
    for(var t in types) {
      if(e[t] == null) {
        return false;
      }
    }

    return true;
  }
}

class Types {
  static int PLAYERBULLET = 0;
  static int RENDER = 1;
  static int POSITION = 2;
  static int PATH = 3;
  static int VELOCITY = 4;
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
            Types.POSITION : new Vector(128, 128),
            Types.PLAYERBULLET : new PlayerBullet(1000)
    };

    entities.add(e);
    player = e;
  }
  
  void update (num dt) {
    Aspect physics = new Aspect([Types.POSITION, Types.VELOCITY]);
    
    for(var e in entities) {
    if(physics.match(e)) {
        e[Types.POSITION] = e[Types.POSITION] + e[Types.VELOCITY] * dt;
      }
    }
    
    player[Types.PLAYERBULLET].cooldown -= dt;
    
    
    path.update(dt / 1000.0);
    
    Vector speed = new Vector(0, 0);
    num p = 7.0;
    
    if(parent.currentlyPressedKeys.contains(KeyCode.A)) {
      speed = speed + new Vector(-1, 0);
    }
    if(parent.currentlyPressedKeys.contains(KeyCode.D)) {
      speed = speed + new Vector(1, 0);
    }
    if(parent.currentlyPressedKeys.contains(KeyCode.W)) {
      speed = speed + new Vector(0, -1);
    }
    if(parent.currentlyPressedKeys.contains(KeyCode.S)) {
      speed = speed + new Vector(0, 1);
    }
    
    speed.normalize();
    
    
    player[Types.POSITION] = player[Types.POSITION] + speed * p;
    print(player[Types.POSITION]);
    
    if(parent.currentlyPressedKeys.contains(KeyCode.SPACE)) {
      var comp = player[Types.PLAYERBULLET];
      if(comp.cooldown <= 0.0) {
        comp.cooldown = comp.dt;
        Vector v = player[Types.POSITION].clone();
        
        var e = {
                 Types.PLAYERBULLET :  new PlayerBullet(1.0),
                 Types.RENDER : new Render(new Rect(0, 0, 32, 32)),
                 Types.POSITION : v,
                 Types.VELOCITY : new Vector(2, 0)

        };
        
        entities.add(e);
      }
    }
  }
  
  void render(CanvasRenderingContext2D ctx) {
    Aspect render = new Aspect([Types.POSITION, Types.RENDER]);
    ctx.clearRect(0, 0, 512, 512);
    
    for (var e in entities) {
      if (render.match(e)) {
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
