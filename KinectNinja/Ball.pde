class Ball{
  PVector position, velocity;
  int radius;
  float gravity = -0.5;
  boolean dead = false;
  boolean isBomb = false;
  
  Ball(PVector pos, PVector vel, int rad){
    position = pos;
    velocity = vel;
    radius = rad;
  }
  void updateBall(){
    velocity.y += gravity;
    position.add(velocity);
  }
  
  
  
  void drawBall(){
    pushMatrix();
    translate(position.x, position.y, position.z);
    
    float green = map(position.z, 900, 1300, 0, 255);
    float blue = map(position.z, 900, 1300, 255, 0);
    
    color col = color(0,green,blue);
    color bombcol = color(sin(millis()/100.0)*50+200,0,0);
    
    if (isBomb == true) {fill(bombcol);} else {fill(col);};
    noStroke();
    sphere(radius);
    popMatrix();
  }
  boolean collision3D(){
    float confidence;
    PVector jointPos1 = new PVector();
    PVector jointPos2 = new PVector();
    confidence = context.getJointPositionSkeleton(1,SimpleOpenNI.SKEL_RIGHT_HAND,jointPos1);
    confidence = context.getJointPositionSkeleton(1,SimpleOpenNI.SKEL_LEFT_HAND,jointPos2);
    return jointPos1.dist(position) <= 150 || jointPos2.dist(position) <= 150;
  }

  boolean isLost(){
    return position.y < -1100;
  }
  void lost(){
    dead = true;
    life--;
  }
  void onHit(){
    dead = true;
  }
  boolean dead(){
    return dead;
  }

}
