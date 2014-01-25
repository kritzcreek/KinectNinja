class Bomb extends Ball{
  
  PImage img = loadImage("bomb.jpg");
  Bomb(PVector pos, PVector vel, int rad){
    super(pos, vel, rad);
    this.isBomb = true;
  }
  
  
  void onHit(){
    dead = true;
    beginShape();
      tint(255,0,0);
      texture(img);
      vertex(position.x - 200, position.y - 200, position.z, 0,   0);
      vertex( position.x+200, position.y-200, position.z, 600, 0);
      vertex( position.x+200,  position.y+200, position.z , 600, 600);
      vertex(position.x-200,  position.y+200, position.z , 0,   600);
    endShape();
    life = 0;
  }
  void lost(){
    dead = true;
  }
}
