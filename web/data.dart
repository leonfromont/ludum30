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
}


dynamic Player() {
  Entity e = new Entity({
          Types.RENDER : new Render(SpriteSheet.player),
          Types.AABB : new Rect(128, 128, 34, 68),
          Types.PLAYERBULLET : new PlayerBullet(1000),
          Types.COLLISION : new CollisionMask('player', ["enemybullet"]),
          Types.PLAYERHEALTH : new PlayerHealth(10)
  });
  
  return e;
}

dynamic _PlayerBullet(Rect v) {
  var e = new Entity({
           Types.PLAYERBULLET :  new PlayerBullet(1.0),
           Types.RENDER : new Render(new Rect(0, 0, 32, 32)),
           Types.AABB : v,
           Types.VELOCITY : new Vector(2, 0),
           Types.COLLISION : new CollisionMask('playerbullet', ["enemy"])
  });
  
  return e;
}

dynamic _EnemyBullet(Rect v) {
  var e = new Entity({
           Types.RENDER : new Render(new Rect(0, 0, 32, 32)),
           Types.AABB : v.clone(),
           Types.VELOCITY : new Vector(-0.5, 0),
           Types.COLLISION : new CollisionMask('enemybullet', ["player"])
  });

  return e;
}

dynamic StraightEnemy() {
  var e = new Entity({
          Types.RENDER : new Render(SpriteSheet.monster),
          Types.AABB : new Rect(400, 128, 68, 68),
          Types.COLLISION : new CollisionMask('enemy', ['playerbullet']),
          Types.PATH : new Path([new Vector(400, 44),  new Vector(400, 128)], 1.0),
          Types.ENEMYBULLET : new EnemyBullet(1000.0)
  });


  return e;
}
