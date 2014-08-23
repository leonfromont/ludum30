library ludum30;

import 'dart:html';
import 'dart:math';
import 'package:ad/ad.dart';

part 'data.dart';


class Wave {
  num dt;
  List<Entity> entities;
  bool spawned = false;

  Wave(this.dt, this.entities);
}

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

class Timed extends Component {
  num dt;
  Timed(this.dt);
}

class SpriteSheet {
  static Rect player = new Rect(0, 32, 64, 32);
  static Rect bullet = new Rect(0, 0, 32, 32);
  static Rect monster = new Rect(64, 0, 64, 64);
  static Rect Explosion = new Rect(0, 64, 64, 64);
  static Rect HeartEmpty = new Rect(64, 64, 32, 32);
  static Rect HeartFull = new Rect(96, 64, 32, 32);

  static render(CanvasRenderingContext2D ctx, Rect r, int x, int y) {
          ctx.drawImageScaledFromSource(el, 
              r.left, 
              r.top, 
              r.width, 
              r.height, 
              x,
              y,
              r.width, 
              r.height);
  }
}



ImageElement el = new ImageElement();


class MyState extends State { 
  static int WIDTH = 512;
  static int HEIGHT = 512;


  static int STATE_GAMEPLAY = 0;
  static int STATE_GAMEOVER = 1;
  static int STATE_CURRENT = STATE_GAMEPLAY;

  num totalTime = 0.0;

  static int PLAY = 0;
  static int GAMEOVER = 1;

  List<Wave> waves = [];

  List<Entity> entities = [];
  var player = null;
  
  MyState() {
    el.src = './spritesheet.png';
    loadWorld();
  }

  void loadWorld() {
    entities = [];
    Entity e = Player();
    entities.add(e);
    player = e;
    waves = [wave1(), wave2(10000), wave2(30000)];
  }
  
  void update(num dt) {

    if(STATE_CURRENT == STATE_GAMEOVER) {
      if(parent.currentlyPressedKeys.length > 0) {
        loadWorld();
        STATE_CURRENT = STATE_GAMEPLAY;
      }
    }

    totalTime += dt;
    for(Wave wave in waves) {
      if(!wave.spawned && wave.dt < totalTime) {
        entities.addAll(wave.entities);
        wave.spawned = true;
      }
    }


    List<Entity> removed = [];
    for(var e in entities) {
      if(e[Types.TIMED] != null) {
        Timed t = e[Types.TIMED];
        t.dt -= dt;
        if(t.dt < 0.0) {
          removed.add(e);
        }
      }
    }
    
    for(var e in removed) {
      entities.remove(e);
    }

    
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
      var e = Explosion(p.a[Types.AABB].topleft);
      entities.add(e);
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
    
    if(player[Types.PLAYERHEALTH].current <= 0) {
      STATE_CURRENT = STATE_GAMEOVER;
    }
    
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
    if(STATE_CURRENT == STATE_GAMEPLAY) {
      
      Aspect render = new Aspect([Types.AABB, Types.RENDER]);
      ctx.clearRect(0, 0, WIDTH, HEIGHT);
      ctx.fillStyle = '#452555';
      ctx.fillRect(0, 0, WIDTH, HEIGHT);
      
      
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
      
      
      // HUD 
      ctx.fillStyle = '#000000';
      ctx.fillRect(0, 0, 512, 64);
      int hudtop = 300;
      int hudwidth = 36;
      int hudpad = 16;


      for(int i = 0; i < 3; i++) {
        Rect s;
        if(player[Types.PLAYERHEALTH].current > i) {
          s = SpriteSheet.HeartFull;
        } else {
          s = SpriteSheet.HeartEmpty;
        }

        SpriteSheet.render(ctx, s, hudtop + (i * hudwidth), hudpad);
      }

      int top = 16;
      int height = 32;
      int padding = 4;
      int horizontalpad = 16;
      //ctx.fillRect(500, top, 4, height);


      
      ctx.fillStyle = '#438c43';
      ctx.fillRect(horizontalpad, top, 256, height + 2 * padding);

      ctx.fillStyle = '#ff0000';
      for(var wave in waves) {
        ctx.fillRect(horizontalpad + (wave.dt / 1000).toInt(), top + padding, 4, height);
      }

      ctx.fillStyle = '#00ff00';
      ctx.fillRect(horizontalpad + (totalTime / 1000).toInt(), top + padding, 4, height);

    } else if (STATE_CURRENT == STATE_GAMEOVER) {
      ctx.font="20px Georgia";
      ctx.fillStyle = '#00ff00';
      String text = 'GAME OVER';
      ctx.fillText(text, 32, 32);
    }
  }
}

void main() {
  Ad ad = new Ad('screen', new MyState());
}
