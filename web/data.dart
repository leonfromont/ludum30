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

dynamic Player() {
  Entity e = new Entity({
          Types.RENDER : new Render(SpriteSheet.player),
          Types.AABB : new Rect(128, 128, 34, 68),
          Types.PLAYERBULLET : new PlayerBullet(1000),
          Types.COLLISION : new CollisionMask('player', ["enemybullet"]),
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
           Types.COLLISION : new CollisionMask('playerbullet', ["enemy"])
  });
  
  return e;
}

dynamic Charger(Vector pos) {
  var e = new Entity({
           Types.RENDER : new Render(SpriteSheet.shell),
           Types.AABB : new Rect(pos.x, pos.y, 64, 32),
           Types.VELOCITY : new Vector(-0.2, 0),
           Types.COLLISION : new CollisionMask('enemybullet', ["player"])
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

class WaveGenerator {

  Rand r = new Rand();

  Wave gen(dt) {
    var types = [Charger, AimEnemy, StraightEnemy];

    List<Entity> ents = [];
    List<Vector> pos = positions();
    for(Vector v in pos) {
      var m = r.choice(types);
      ents.add(StraightEnemy(v));
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
  List<Vector> positions() {
    var results = [];
    int t = r.range(7, 9);

    // now... max we can have in back wave is 5
    // anymore we jam in the front wave
    int backwave = t;
    if(t > 5) {
      backwave = 5;
    }

    var ys = ypositions(backwave);
    for(var y in ys) {
      var e = new Vector(400, y);
      results.add(e);
    }

    // then the rest we put in front
    int frontwave = 0;
    if(t > 5) {
      frontwave = t - 5;
    }

    ys = ypositions(frontwave);
    for(var y in ys) {
      var e = new Vector(300, y);
      results.add(e);
    }

    return results;
  }
}

List<Wave> makewaves() {
    WaveGenerator gen = new WaveGenerator();
    var waves = [];
    for(int i = 0; i < 20; i++) {
      waves.add(gen.gen(i * 5000));
    }
    return waves;
}
