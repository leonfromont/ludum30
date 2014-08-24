part of ludum30;

class Types {
  static int PLAYERBULLET = 0;
  static int RENDER = 1;
  //static int POSITION = 2;
  static int PATH = 3;
  static int VELOCITY = 4;
  static int COLLISION = 5;
  static int AABB = 6;
  static int ENEMYBULLET = 7;
  static int PLAYERHEALTH = 8;
  static int TIMED = 9;
  static int FLICKER = 10;
}

class Constants {
  static int FLICKER_FREQ = 10;
  static int FLICKER_DURATION = 180;
  static int PATH_HEIGHT = 30;
}

class Colors {
  static String bg = '#452555';
  static String light_bg = '#9550b7';
  static String text = '#00ff00';
  static String progress_bg = '#805215';
  static String progress_markers = '#FFDBAA';
  static String progress_current = '#343477';
  static String HUD_bg = '#AA7939';
}

dynamic Player() {
  Entity e = new Entity({
          Types.RENDER : new Render(SpriteSheet.player),
          Types.AABB : new Rect(128, 128, 64, 32),
          Types.PLAYERBULLET : new PlayerBullet(1000),
          Types.COLLISION : new CollisionMask('player', ["enemybullet", 'charger']),
          Types.PLAYERHEALTH : new PlayerHealth(3)
  });
  
  return e;
}

dynamic Explosion(Vector v) {
  var e = new Entity({
           Types.RENDER : new Render(SpriteSheet.Explosion),
           Types.AABB : new Rect(v.x, v.y, 64, 64),
           Types.TIMED : new Timed(250)
  });
  
  return e;
}

dynamic Earth() {
  var e = new Entity({
           Types.RENDER : new Render(SpriteSheet.Earth),
           Types.AABB : new Rect(300, 32, 128, 128)
  });
  
  return e;
}

dynamic _PlayerBullet(Rect v) {
  var e = new Entity({
           Types.PLAYERBULLET :  new PlayerBullet(1.0),
           Types.RENDER : new Render(SpriteSheet.bulletplayer),
           Types.AABB : new Rect(v.left, v.top, 32, 32),
           Types.VELOCITY : new Vector(0.8, 0),
           Types.COLLISION : new CollisionMask('playerbullet', ["enemy", 'charger'])
  });
  
  return e;
}

dynamic Charger(Vector pos) {
  var e = new Entity({
           Types.RENDER : new Render(SpriteSheet.shell),
           Types.AABB : new Rect(pos.x, pos.y, 64, 32),
           Types.VELOCITY : new Vector(-0.2, 0),
           Types.COLLISION : new CollisionMask('charger', ["player", 'playerbullet'])
  });

  return e;
}

dynamic _EnemyBullet(Rect v) {
  var e = new Entity({
           Types.RENDER : new Render(SpriteSheet.bulletenemy),
           Types.AABB : new Rect(v.left, v.top, 32, 32),
           Types.VELOCITY : new Vector(-0.2, 0),
           Types.COLLISION : new CollisionMask('enemybullet', ["player"])
  });

  return e;
}

dynamic _EnemyBulletTargeted(Rect v, Rect target) {
  Vector line = target.center - v.center;
  line.normalize();
  var e = new Entity({
           Types.RENDER : new Render(SpriteSheet.bulletenemy),
           Types.AABB : new Rect(v.left, v.top, 32, 32),
           Types.VELOCITY : line * 0.2,
           Types.COLLISION : new CollisionMask('enemybullet', ["player"])
  });

  return e;
}

dynamic StraightEnemy(Vector origin) {
  var b = origin.clone();
  b.y -= Constants.PATH_HEIGHT;
  
  var e = new Entity({
          Types.RENDER : new Render(SpriteSheet.monster),
          Types.AABB : new Rect(origin.x, origin.y, 64, 64),
          Types.COLLISION : new CollisionMask('enemy', ['playerbullet']),
          Types.PATH : new Path([origin.clone(),  b], 1.5),
          Types.ENEMYBULLET : new EnemyBullet(1500.0)
  });

  return e;
}

dynamic AimEnemy(Vector origin) {
  var b = origin.clone();
  b.y -= Constants.PATH_HEIGHT;
  
  var e = new Entity({
          Types.RENDER : new Render(SpriteSheet.monsterpurple),
          Types.AABB : new Rect(origin.x, origin.y, 64, 64),
          Types.COLLISION : new CollisionMask('enemy', ['playerbullet']),
          Types.PATH : new Path([origin.clone(),  b], 1.5),
          Types.ENEMYBULLET : new EnemyBullet(1500.0, aim : true)
  });



  return e;
}

class Rand {
  Random impl;

  Rand() {
    impl = new Random();
  }

  int range(int min, int max) {
    int abs = impl.nextInt(max - min);
    return abs + min;
  }

  dynamic choice(List choices) {
    int index = range(0, choices.length);
    return choices[index];
  }
}


Wave wave3(dt) {
  var e1 = Charger(new Vector(400, 400));
  var e3 = Charger(new Vector(400, 200));

  return new Wave(dt, [e1, e3]);

}

Wave wave1() {
  var e1 = AimEnemy(new Vector(400, 400));
  var e3 = AimEnemy(new Vector(400, 200));

  return new Wave(1000, [e1, e3]);
}

Wave wave2(dt) {
  var e1 = StraightEnemy(new Vector(400, 400));
  var e2 = StraightEnemy(new Vector(400, 300));
  var e3 = StraightEnemy(new Vector(400, 200));

  return new Wave(dt, [e1, e2, e3]);
}

class WaveTemplate {
  List<Vector> front;
  List<Vector> back;

  WaveTemplate(this.back, this.front);
  
  List<Vector> all() {
    var result = [];
    result.addAll(back);
    result.addAll(back);
    return result;
  }
}


class Range {
  int min;
  int max;
  
  Range(this.min, this.max);
}

class WaveGenerator {

  Rand r = new Rand();

  Wave gen(num dt, int difficulty) {
    // how do we scale difficulty
    // variation in monsters
    // number of monsters

    // max monsters is 7.
    // range 1,7 from 20?
    var d = {
            0 : new Range(1, 2),
            1 : new Range(2, 3),
            2 : new Range(2, 3),
            3 : new Range(2, 3),
            4 : new Range(2, 4),
            5 : new Range(2, 4),
            6 : new Range(3, 5),
            7 : new Range(3, 5),
            8 : new Range(3, 5),
            9 : new Range(3, 5),
            10 : new Range(3, 6),
            11 : new Range(3, 6),
            12 : new Range(3, 6),
            13 : new Range(4, 7),
            14 : new Range(4, 7),
            15 : new Range(4, 7),
            16 : new Range(5, 7),
            17 : new Range(5, 7),
            18 : new Range(5, 7),
            19 : new Range(5, 7),
            20 : new Range(5, 7),
            21 : new Range(6, 8),
    };


    var types = [Charger, AimEnemy, StraightEnemy];

    List<Entity> ents = [];
    Range df = d[difficulty];
    WaveTemplate template = positions(df.min, df.max);
    List<Vector> pos = template.all();

    // back!!!
    var spawn = [];
    var halfsies = [];
    int half = template.back.length ~/ 2; 
    for(int i = 0; i < half; i++) {
      halfsies.add(r.choice(types));
    }
      
    spawn.addAll(halfsies);

    // if we are odd pad the center with another one
    if(template.back.length % 2 != 0) {
      spawn.add(r.choice(types));
    }

    spawn.addAll(halfsies.reversed);

    for(int f = 0; f < template.back.length; f++) {
      ents.add(spawn[f](template.back[f]));
    }

    // front
    spawn = [];
    halfsies = [];
    half = template.front.length ~/ 2; 
    for(int i = 0; i < half; i++) {
      halfsies.add(r.choice(types));
    }
      
    spawn.addAll(halfsies);

    // if we are odd pad the center with another one
    if(template.front.length % 2 != 0) {
      spawn.add(r.choice(types));
    }

    spawn.addAll(halfsies.reversed);

    for(int f = 0; f < template.front.length; f++) {
      ents.add(spawn[f](template.front[f]));
    }


    return new Wave(dt, ents);
  }

  List<int> ypositions(int n) {
    List<int> results = [];
    double height = (512.0 - 64.0) / n;
    for(int i = 0; i < n; i++) {
      double y = (height * i) + (height / 2);
      results.add(64.0 + y.toInt());
    }

    return results;
  }

  // generate positions on our wave grid
  WaveTemplate positions(int min, int max) {

    int overflow = 5;
    int t = r.range(min, max);

    // now... max we can have in back wave is 5
    // anymore we jam in the front wave
    int backwave = t;
    if(t > overflow) {
      backwave = 5;
    }

    var ys = ypositions(backwave);
    List<Vector> _backwave = [];
    for(var y in ys) {
      var e = new Vector(400, y);
      _backwave.add(e);
    }

    // then the rest we put in front
    int frontwave = 0;
    if(t > overflow) {
      frontwave = t - 5;
    }

    ys = ypositions(frontwave);
    List<Vector> _frontwave = [];
    for(var y in ys) {
      var e = new Vector(300, y);
      _frontwave.add(e);
    }

    return new WaveTemplate(_backwave, _frontwave);
  }
}

List<Wave> makewaves() {
    WaveGenerator gen = new WaveGenerator();
    var waves = [];
    for(int i = 0; i < 20; i++) {
      waves.add(gen.gen(i * 5000, i));
    }
    return waves;
}
