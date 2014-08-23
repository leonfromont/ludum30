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

dynamic _PlayerBullet(Rect v) {
  var e = new Entity({
           Types.PLAYERBULLET :  new PlayerBullet(1.0),
           Types.RENDER : new Render(new Rect(0, 0, 32, 32)),
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
           Types.RENDER : new Render(SpriteSheet.bullet),
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
           Types.RENDER : new Render(SpriteSheet.bullet),
           Types.AABB : new Rect(v.left, v.top, 32, 32),
           Types.VELOCITY : line * 0.2,
           Types.COLLISION : new CollisionMask('enemybullet', ["player"])
  });

  return e;
}

dynamic StraightEnemy(Vector origin) {
  var b = origin.clone();
  b.y -= 100;
  
  var e = new Entity({
          Types.RENDER : new Render(SpriteSheet.monster),
          Types.AABB : new Rect(origin.x, origin.y, 68, 68),
          Types.COLLISION : new CollisionMask('enemy', ['playerbullet']),
          Types.PATH : new Path([origin.clone(),  b], 1.5),
          Types.ENEMYBULLET : new EnemyBullet(3000.0)
  });

  return e;
}

dynamic AimEnemy(Vector origin) {
  var b = origin.clone();
  b.y -= 100;
  
  var e = new Entity({
          Types.RENDER : new Render(SpriteSheet.monsterpurple),
          Types.AABB : new Rect(origin.x, origin.y, 68, 68),
          Types.COLLISION : new CollisionMask('enemy', ['playerbullet']),
          Types.PATH : new Path([origin.clone(),  b], 1.5),
          Types.ENEMYBULLET : new EnemyBullet(3000.0, aim : true)
  });



  return e;
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

List<Wave> makewaves() {
    var waves = [wave1(), wave3(10000), wave2(20000)];
    return waves;
}
