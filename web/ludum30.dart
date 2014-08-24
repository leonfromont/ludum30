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

  void operator[]=(int index, dynamic value) {
    comps[index] = value;
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

class Flicker extends Component {
  num freq;
  num totalTicks;
  num leftTicks;

  Flicker(num freq, num totalTime) {
    this.freq = freq;
    this.totalTicks = totalTime;
    leftTicks = totalTime;
  }

  bool get done => leftTicks <= 0;
  bool get off {
    num wrap = leftTicks % (2 * freq);
    return wrap / freq >= 1.0;
  }
  // 0 = True
  // 1 = True
  // 2 = True
  // 3 = False
  // 4 = False
  // 5 = False
  // 6 = True

}

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
  int ignore = 0;

  CollisionMask(this.name, this.mask);
}

class EnemyBullet extends Component {
  num cooldown;
  num dt;
  bool aim;

  bool get canFire => cooldown <= 0.0;

  EnemyBullet(num dt, {aim : false}) {
    this.cooldown = dt * new Random().nextDouble();
    this.dt = dt;
    this.aim = aim;
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
  static Rect bulletenemy = new Rect(0, 0, 32, 32);
  static Rect bulletplayer = new Rect(32, 0, 32, 32);
  static Rect monster = new Rect(64, 0, 64, 64);
  static Rect monsterpurple = new Rect(128, 0, 64, 64);
  static Rect shell = new Rect(192, 0, 64, 32);
  static Rect Explosion = new Rect(0, 64, 64, 64);
  static Rect HeartEmpty = new Rect(64, 64, 32, 32);
  static Rect HeartFull = new Rect(96, 64, 32, 32);
  static Rect Background1 = new Rect(0, 480, 512, 32);
  static Rect Background2 = new Rect(0, 448, 512, 32);
  static Rect Earth = new Rect(128, 64, 128, 128);

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

  int a = 0;
  int b = -WIDTH;


  // once you have lasted longer than this
  // you win
  static int TOTALTIME = 10000 + 10 * 10000;

  Rect SCREEN = new Rect(0, 64, WIDTH, HEIGHT);

  // clip ship
  Rect SCREEN2 = new Rect(0, 64, WIDTH, HEIGHT - 64);

  static int STATE_GAMEPLAY = 0;
  static int STATE_GAMEOVER = 1;
  static int STATE_TITLE = 2;
  static int STATE_WON = 3;
  static int STATE_CURRENT = STATE_TITLE;

  static int maxkeycooldown = 120;
  int keycooldown = maxkeycooldown;

  num totalTime = 0.0;

  static int PLAY = 0;
  static int GAMEOVER = 1;

  List<Wave> waves = [];

  List<Entity> entities = [];
  var player = null;
  MyState() {
    el.src = './spritesheet2.png';
    
    querySelector('#load').remove();
    loadWorld();
  }

  void loadWorld() {
    totalTime = 0.0;
    entities = [];
    entities.add(Earth()); Entity e = Player();
    entities.add(e);
    player = e;
    waves = makewaves();
  }
  
  void update(num dt) {
    if(STATE_CURRENT == STATE_GAMEOVER || STATE_CURRENT == STATE_WON) {
      keycooldown -= 1;
      if(keycooldown > 0) {
        return;
      }

      if(parent.currentlyPressedKeys.length > 0) {
        keycooldown = maxkeycooldown;
        loadWorld();
        STATE_CURRENT = STATE_GAMEPLAY;
      }
    } else if(STATE_CURRENT == STATE_TITLE) {
      if(parent.currentlyPressedKeys.length > 0) {
        loadWorld();
        STATE_CURRENT = STATE_GAMEPLAY;
      }
    } if(STATE_CURRENT == STATE_WON || STATE_CURRENT == STATE_TITLE) {
      return;
    }

    // see whether there any ents we can dispose of
    List<Entity> removed = [];
    for(var e in entities) {
      CollisionMask mask = e[Types.COLLISION];
      if(mask != null && (mask.name == 'enemybullet' || mask.name == 'playerbullet')) {
        // check if its offscreen
        if(!SCREEN.contains(e[Types.AABB])) {
          removed.add(e);
        }
      }
    }

    for (var e in entities) {
      var collide = e[Types.COLLISION];
      if(collide != null && collide.ignore > 0) {
        collide.ignore -= 1;
      }
    }

    for (var e in entities) {
      var flicker = e[Types.FLICKER];
      if(flicker != null) {
        flicker.leftTicks -= 1;
        if(flicker.leftTicks <= 0) {
          e[Types.FLICKER] = null;
        }
      }
    }

    // TODO: check if there are any entitites left
    if(totalTime > TOTALTIME) {
      STATE_CURRENT = STATE_WON;
    }

    totalTime += dt;
    for(Wave wave in waves) {
      if(!wave.spawned && wave.dt < totalTime) {
        entities.addAll(wave.entities);
        wave.spawned = true;
      }
    }


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
      var e = Explosion(p.a[Types.AABB].topleft);
      entities.add(e);

      if(p.a[Types.PLAYERHEALTH] != null && p.a[Types.COLLISION].ignore <= 0) {
        p.a[Types.PLAYERHEALTH].current -= 1;
        p.a[Types.FLICKER] = new Flicker(Constants.FLICKER_FREQ, Constants.FLICKER_DURATION);
        p.a[Types.COLLISION].ignore = Constants.FLICKER_DURATION;
        entities.remove(p.b);
        continue;
      }

      if(p.b[Types.PLAYERHEALTH] != null && p.b[Types.COLLISION].ignore <= 0) {
        p.b[Types.PLAYERHEALTH].current -= 1;
        p.b[Types.FLICKER] = new Flicker(Constants.FLICKER_FREQ, Constants.FLICKER_DURATION);
        p.b[Types.COLLISION].ignore = Constants.FLICKER_DURATION;
        entities.remove(p.a);
        continue;
      }
      
      if(p.a != player) {
        entities.remove(p.a);
      }
      
      if(p.b != player) {
        entities.remove(p.b);
      }
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
        EnemyBullet eb = e[Types.ENEMYBULLET];
        eb.cooldown -= dt;
        
        if(eb.canFire) {
          eb.cooldown = eb.dt;
          
          Entity e1;

          if(!eb.aim) {
            e1 = _EnemyBullet(e[Types.AABB]); 
          } else {
            e1 = _EnemyBulletTargeted(e[Types.AABB], player[Types.AABB]); 
          }

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

    var keys = parent.currentlyPressedKeys;
    
    if(keys.contains(KeyCode.A) || keys.contains(KeyCode.LEFT)) {
      speed = speed + new Vector(-1, 0);
    }
    if(keys.contains(KeyCode.D) || keys.contains(KeyCode.RIGHT)) {
      speed = speed + new Vector(1, 0);
    }
    if(keys.contains(KeyCode.W) || keys.contains(KeyCode.UP)) {
      speed = speed + new Vector(0, -1);
    }
    if(keys.contains(KeyCode.S) || keys.contains(KeyCode.DOWN)) {
      speed = speed + new Vector(0, 1);
    }
    
    speed.normalize();

    Rect aabb = player[Types.AABB];
    var old = aabb.clone();
    aabb.topleft = aabb.topleft + speed * p;

    if(!SCREEN2.contains(aabb)) {
      player.comps[Types.AABB] = old;
    }

    
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
      ctx.fillStyle = Colors.bg;
      ctx.fillRect(0, 0, WIDTH, HEIGHT);


      a -= 1;
      //ctx.drawImage(bg, a, 0);
      SpriteSheet.render(ctx, SpriteSheet.Background1, a, 480);

      if(a < -WIDTH) {
        a = WIDTH;
      }

      b -= 1;
      if(b < -WIDTH) {
        b = WIDTH;
      }

      
      //ctx.drawImage(bg, b, 0);
      SpriteSheet.render(ctx, SpriteSheet.Background2, b, 480);
      
      for (var e in entities) {
        var flicker = e[Types.FLICKER];
        if(flicker != null && flicker.off) {
          continue;
        }

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

          if(false) {
            ctx.fillStyle = "rgba(255, 0, 0, 0.3)";
            ctx.fillRect(e[Types.AABB].left,
                          e[Types.AABB].top,
                          e[Types.AABB].width,
                          e[Types.AABB].height);
          }
        }
      }

      // HUD 
      ctx.fillStyle = Colors.HUD_bg;
      ctx.fillRect(0, 0, 512, 72);
      int hudtop = 364;
      int hudwidth = 36;
      int hudpad = 20;


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


      
      ctx.fillStyle = Colors.progress_bg;
      ctx.fillRect(horizontalpad, top, (horizontalpad - 16) + (TOTALTIME / 1000), height + 2 * padding);

      ctx.fillStyle = Colors.progress_markers;
      for(var wave in waves) {
        ctx.fillRect(horizontalpad + (wave.dt / 1000).toInt(), top + padding, 4, height);
      }

      ctx.fillStyle = Colors.progress_current;
      ctx.fillRect(horizontalpad + (totalTime / 1000).toInt(), top + padding, 4, height);


      // need to debounce both of these states
    } else if (STATE_CURRENT == STATE_GAMEOVER) {

      ctx.fillStyle = Colors.light_bg;
      ctx.fillRect(128, 128, 256, 256);

      ctx.font="20px Georgia";
      ctx.fillStyle = Colors.text;
      ctx.fillText('GAME OVER', 128 + 32, 128 + 32);
      ctx.fillText('Press any key to restart', 128 + 32, 256);

    } else if(STATE_CURRENT == STATE_TITLE) {


      ctx.fillStyle = Colors.bg;
      ctx.fillRect(0, 0, WIDTH, HEIGHT);
      
      ctx.drawImageScaledFromSource(el, 
          SpriteSheet.Earth.left, 
          SpriteSheet.Earth.top, 
          SpriteSheet.Earth.width, 
          SpriteSheet.Earth.height, 
          256, 
          256, 
          SpriteSheet.Earth.width, 
          SpriteSheet.Earth.height);

      ctx.font="32px Georgia";
      ctx.fillStyle = Colors.text;
      String text = 'IUNIUS';
      ctx.fillText(text, 128, 64);
      
      ctx.font="20px Georgia";
      ctx.fillText('Press any key to start', 128, 128);


      ctx.fillText('Arrow keys to move. Space to fire.', 128, 128 + 32);

    } else if(STATE_CURRENT == STATE_WON) {
      ctx.fillStyle = Colors.bg;
      ctx.fillRect(0, 0, WIDTH, HEIGHT);

      ctx.drawImageScaledFromSource(el, 
          SpriteSheet.Earth.left, 
          SpriteSheet.Earth.top, 
          SpriteSheet.Earth.width, 
          SpriteSheet.Earth.height, 
          256, 
          256, 
          SpriteSheet.Earth.width, 
          SpriteSheet.Earth.height);

      ctx.drawImageScaledFromSource(el, 
          SpriteSheet.player.left, 
          SpriteSheet.player.top, 
          SpriteSheet.player.width, 
          SpriteSheet.player.height, 
          128, 
          128, 
          SpriteSheet.player.width, 
          SpriteSheet.player.height);

      ctx.font="20px Georgia";
      ctx.fillStyle = Colors.text;
      String text = 'YOU HAVE MADE IT TO IUNIUS';
      ctx.fillText(text, 32, 32);
    }
  }
}

void main() {
  Ad ad = new Ad('screen', new MyState());
}
