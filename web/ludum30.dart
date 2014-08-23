library ludum30;

import 'dart:html';
import 'dart:math';
import 'package:ad/ad.dart';

part 'data.dart';



class Entity {
  static int nextId = 0;
  int ID;

  List comps = [];

  Entity(Map<int, dynamic> args) {
    nextId += 1;
    ID = nextId;
    comps = new List(64);

    for(int s in args.keys) {
      comps[s] = args[s];
    }
  }
  
  int get hashCode {
    return ID;
  }
  
  bool operator==(other) {
    if (other is! Entity) return false;
    Entity e = other;
    return (ID == e.ID);
  }
  
  dynamic operator[](int index) {
    return comps[index];
  }
}

class Pair {
  Entity a;
  Entity b;

  Pair(this.a, this.b);

  int get hashCode {
    return a.ID ^ b.ID;
  }
  
  bool operator==(other) {
    if (other is! Pair) return false;
    Pair p = other;

    if(a == p.a && b == p.b) {
      return true;
    }

    if(a == p.b && b == p.a) {
      return true;
    }

    return false; 
  }
}

class Aspect {
  List<int> types;

  Aspect(this.types);

  bool match(var e) {
    for(var t in types) {
      if(e.comps[t] == null) {
        return false;
      }
    }

    return true;
  }
}


abstract class Component {}

class PlayerHealth extends Component {
  int max;
  int current;

  PlayerHealth(int max) {
    this.max = max;
    this.current = max;
  }
}

class CollisionMask extends Component {
  String name;
  List<String> mask;

  CollisionMask(this.name, this.mask);
}

class EnemyBullet extends Component {
  num cooldown;
  num dt;

  bool get canFire => cooldown <= 0.0;

  EnemyBullet(num dt) {
    this.cooldown = dt;
    this.dt = dt;
  }
}

class PlayerBullet extends Component {
  
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
  static Rect player = new Rect(0, 34, 68, 34);
  static Rect bullet = new Rect(0, 0, 34, 34);
  static Rect monster = new Rect(68, 0, 68, 68);
}



ImageElement el = new ImageElement();


class MyState extends State { 
  List<Entity> entities = [];
  var player = null;
  
  Rect a = new Rect(0, 0, 32, 32);
  Rect b = new Rect(64, 0, 32, 32);
  
  Path path = new Path.once(
            [new Vector(0, 44),  new Vector(0, 128)],
            3.0);
  
  MyState() {
    el.src = './spritesheet.png';
    Entity e = Player();

    entities.add(e);
    player = e;

    entities.add(StraightEnemy());
  }
  
  void update (num dt) {
    var collidables = [];
    for(var e in entities) {
      if(e.comps[Types.COLLISION] != null) {
        collidables.add(e); 
      }
    }

    Set<Pair> pairs = new Set<Pair>();
    Rect t0, t1;

    for(var e0 in collidables) {
      for(var e1 in collidables) {
        CollisionMask c0 = e0.comps[Types.COLLISION];
        CollisionMask c1 = e1.comps[Types.COLLISION];
        
        if(c0.mask.contains(c1.name) &&
            c1.mask.contains(c0.name)) {
          if(e0[Types.AABB].collide(e1[Types.AABB])) {
            Pair p = new Pair(e0, e1);
            if(!pairs.contains(p)) {
              pairs.add(new Pair(e0, e1));
            }
          }
        }
      }
    }

    for(Pair p in pairs) {
      if(p.a[Types.PLAYERHEALTH] != null) {
        p.a[Types.PLAYERHEALTH].current -= 1;
        entities.remove(p.b);
        continue;
      }

      if(p.b[Types.PLAYERHEALTH] != null) {
        p.b[Types.PLAYERHEALTH].current -= 1;
        entities.remove(p.a);
        continue;
      }

      entities.remove(p.a);
      entities.remove(p.b);
    }


    Aspect physics = new Aspect([Types.AABB, Types.VELOCITY]);
    
    for(var e in entities) {
    if(physics.match(e)) {
        Rect aabb = e[Types.AABB];
        aabb.topleft = aabb.topleft + e[Types.VELOCITY] * dt;
      }
    }

    for(var e in entities) {
      if(e[Types.PATH] != null) {
        e[Types.PATH].update(dt / 1000.0);
        
        e[Types.AABB].topleft = e[Types.PATH].currentPoint();
      }
    }
    
    List<Entity> newones = [];

    for(var e in entities) {
      if(e[Types.ENEMYBULLET] != null) {
        e[Types.ENEMYBULLET].cooldown -= dt;
        
        if(e[Types.ENEMYBULLET].canFire) {
          e[Types.ENEMYBULLET].cooldown = e[Types.ENEMYBULLET].dt;
          var e1 = _EnemyBullet(e[Types.AABB]); 
          newones.add(e1);
        }
      }
    }
    
    entities.addAll(newones);
    
    player.comps[Types.PLAYERBULLET].cooldown -= dt;
    
    
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
    
    player[Types.AABB].topleft = player[Types.AABB].topleft + speed * p;
    
    if(parent.currentlyPressedKeys.contains(KeyCode.SPACE)) {
      var comp = player.comps[Types.PLAYERBULLET];
      if(comp.cooldown <= 0.0) {
        comp.cooldown = comp.dt;
        Rect v = player[Types.AABB].clone();
        
        var e = _PlayerBullet(v);
        entities.add(e);
      }
    }
  }
  
  void render(CanvasRenderingContext2D ctx) {
    Aspect render = new Aspect([Types.AABB, Types.RENDER]);
    ctx.clearRect(0, 0, 512, 512);
    
    for (var e in entities) {
      if (render.match(e)) {
        Render r = e.comps[Types.RENDER];
        ctx.drawImageScaledFromSource(el, 
            r.spritesheet.left, 
            r.spritesheet.top, 
            r.spritesheet.width, 
            r.spritesheet.height, 
            e.comps[Types.AABB].left, 
            e.comps[Types.AABB].top, 
            r.spritesheet.width, 
            r.spritesheet.height);
      }
    }
    
    
    
    ctx.font="20px Georgia";
    ctx.fillStyle = '#00ff00';
    String text = player[Types.PLAYERHEALTH].current.toString();
    ctx.fillText(text, 32, 32);
  }
}

void main() {
  Ad ad = new Ad('screen', new MyState());
}
