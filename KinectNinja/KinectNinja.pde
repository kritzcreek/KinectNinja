import SimpleOpenNI.*;


SimpleOpenNI context;
float        zoomF =0.5f;
float        rotX = radians(180);  // by default rotate the hole scene 180deg around the x-axis, 
                                   // the data from openni comes upside down
float        rotY = radians(0);
boolean      autoCalib=true;

PVector[]    rightSlice = new PVector[10];
PVector[]    leftSlice = new PVector[10];

PVector      bodyCenter = new PVector();
PVector      bodyDir = new PVector();
PVector      bodyHead = new PVector();

PVector      com = new PVector();                                   
PVector      com2d = new PVector();                                   
color[]       userClr = new color[]{ color(255,0,0),
                                     color(0,255,0),
                                     color(0,0,255),
                                     color(255,255,0),
                                     color(255,0,255),
                                     color(0,255,255)
                                   };
                                   
                                   
      
ArrayList <Ball> balls = new ArrayList <Ball>();
Boolean newUser = false;

int life = 3;
double score = 0;
boolean lost = false;

int minColorValue = 800;
int maxColorValue = 1300;


void setup()
{
  if(balls.size() == 0)
    balls.add(new Bomb(new PVector(500,500,1000), new PVector(0,0,5), 50));
  size(1024,768,P3D);
  context = new SimpleOpenNI(this);
  if(context.isInit() == false)
  {
     println("Can't init SimpleOpenNI, maybe the camera is not connected!"); 
     exit();
     return;  
  }
  lights();

  // disable mirror
  context.setMirror(false);

  // enable depthMap generation 
  context.enableDepth();

  // enable skeleton generation for all joints
  context.enableUser();

  stroke(255,255,255);
  smooth();  
  perspective(radians(45),
              float(width)/float(height),
              10,150000);
 }

void draw(){
  if(life < 1){
    return;
  }
  
  rotY = radians(bodyCenter.x/20.0);
  
  
  // update the cam
  context.update();


  background(0,0,0);  
  // set the scene pos
  translate(width/2, height/2, 0);
  rotateX(rotX);
  rotateY(rotY);
  scale(zoomF);
  int[]   depthMap = context.depthMap();
  int[]   userMap = context.userMap();
  int     steps   = 4;  // to speed up the drawing, draw every third point
  int     index;
  PVector realWorldPoint;
  
  translate(0,0,-1000);  // set the rotation center of the scene 1000 infront of the camera



//-----------------Balllogik--------------

    for(int i = 0; i < balls.size(); i++){
    if(balls.get(i)==null) continue;
    if(balls.get(i).dead()){ balls.remove(i); continue;}
    if(newUser){
      balls.get(i).updateBall();
      if(balls.get(i).collision3D()){     
        score += 1;
        balls.get(i).onHit();
        continue;
      }
      if(balls.get(i).isLost()){
        balls.get(i).lost();
        continue;
      }
      balls.get(i).drawBall();
    }
   }
   if(balls.size() == 0)  newBalls();
//-----------------------------------------
   if(context.isTrackingSkeleton(1))
     drawSlice(1);
     
     drawLife();
     drawScore();
  
  
  
  // draw the pointcloud
  beginShape(POINTS);
  for(int y=0;y < context.depthHeight();y+=steps)
  {
    for(int x=0;x < context.depthWidth();x+=steps)
    {
      index = x + y * context.depthWidth();
      if(depthMap[index] > 0)
      { 
        // draw the projected point
        realWorldPoint = context.depthMapRealWorld()[index];
        if(userMap[index] == 0)
          stroke(150);
        else
          stroke(userClr[ (userMap[index] - 1) % userClr.length ]);        
        
        point(realWorldPoint.x,realWorldPoint.y,realWorldPoint.z);
      }
    } 
  } 
  endShape();
  
  
  
  // draw the skeleton if it's available
  int[] userList = context.getUsers();
  for(int i=0;i<userList.length;i++)
  {
    if(context.isTrackingSkeleton(userList[i]))
      drawSkeleton(userList[i]);
    
    // draw the center of mass
    if(context.getCoM(userList[i],com))
    {
      stroke(100,255,0);
      strokeWeight(1);
      beginShape(LINES);
        vertex(com.x - 15,com.y,com.z);
        vertex(com.x + 15,com.y,com.z);
        
        vertex(com.x,com.y - 15,com.z);
        vertex(com.x,com.y + 15,com.z);

        vertex(com.x,com.y,com.z - 15);
        vertex(com.x,com.y,com.z + 15);
      endShape();
      
      fill(0,255,100);
      text(Integer.toString(userList[i]),com.x,com.y,com.z);
    }      
  }    
 
}
void newBalls(){
  for (int i = 0; i < score/10 + 1; i++){ 
    float isBomb = random(0,100);
    boolean isLeft = random(0,1) < 0.5f;
    if (isBomb <10){
      balls.add(i,new Bomb(new PVector(random(-500,500),random(-800,-1000), 1000),new PVector(random(-6,6), random(33,38), random(2,4)), 50));
      continue;
    }
    if(isLeft){
      balls.add(i,new Ball(new PVector(random(-500,0),random(-800,-1000), 1000),new PVector(random(0,8), random(33,38), random(2,4)), 50));
      continue;
    }
    balls.add(i,new Ball(new PVector(random(0,500),random(-800,-1000), 1000),new PVector(random(-8,0), random(33,38), random(2,4)), 50));
    
  }
}




// draw the skeleton with the selected joints
void drawSkeleton(int userId)
{
  strokeWeight(3);

  // to get the 3d joint data
  drawLimb(userId, SimpleOpenNI.SKEL_HEAD, SimpleOpenNI.SKEL_NECK);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_LEFT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_LEFT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_ELBOW, SimpleOpenNI.SKEL_LEFT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_NECK, SimpleOpenNI.SKEL_RIGHT_SHOULDER);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_RIGHT_ELBOW);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_ELBOW, SimpleOpenNI.SKEL_RIGHT_HAND);

  drawLimb(userId, SimpleOpenNI.SKEL_LEFT_SHOULDER, SimpleOpenNI.SKEL_TORSO);
  drawLimb(userId, SimpleOpenNI.SKEL_RIGHT_SHOULDER, SimpleOpenNI.SKEL_TORSO);

  context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_HEAD,bodyHead);

  // draw body direction
  getBodyDirection(userId,bodyCenter,bodyDir);
  
  bodyDir.mult(200);  // 200mm length
  bodyDir.add(bodyCenter);
  
  stroke(255,200,200);
  line(bodyCenter.x,bodyCenter.y,bodyCenter.z,
       bodyDir.x ,bodyDir.y,bodyDir.z);

  strokeWeight(1);
 
}

void drawLimb(int userId,int jointType1,int jointType2)
{
  PVector jointPos1 = new PVector();
  PVector jointPos2 = new PVector();
  float  confidence;
  
  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId,jointType1,jointPos1);
  confidence = context.getJointPositionSkeleton(userId,jointType2,jointPos2);

  stroke(255,0,0,confidence * 200 + 55);
  line(jointPos1.x,jointPos1.y,jointPos1.z,
       jointPos2.x,jointPos2.y,jointPos2.z);
  
  drawJointOrientation(userId,jointType1,jointPos1,50);
}

void drawJointOrientation(int userId,int jointType,PVector pos,float length)
{
  // draw the joint orientation  
  PMatrix3D  orientation = new PMatrix3D();
  float confidence = context.getJointOrientationSkeleton(userId,jointType,orientation);
  if(confidence < 0.001f) 
    // nothing to draw, orientation data is useless
    return;
    
  pushMatrix();
    translate(pos.x,pos.y,pos.z);
    
    // set the local coordsys
    applyMatrix(orientation);
    
    // coordsys lines are 100mm long
    // x - r
    stroke(255,0,0,confidence * 200 + 55);
    line(0,0,0,
         length,0,0);
    // y - g
    stroke(0,255,0,confidence * 200 + 55);
    line(0,0,0,
         0,length,0);
    // z - b    
    stroke(0,0,255,confidence * 200 + 55);
    line(0,0,0,
         0,0,length);
  popMatrix();
}

void drawSlice(int userId){
  PVector jointPosLeft = new PVector();
  PVector jointPosRight = new PVector();
  context.getJointPositionSkeleton(userId,6,jointPosLeft);
  context.getJointPositionSkeleton(userId,7,jointPosRight);
  for(int j = 8; j >= 0; j--){
     leftSlice[j+1] = leftSlice[j]; 
     rightSlice[j+1] = rightSlice[j]; 
  }
  leftSlice[0] = jointPosLeft;
  rightSlice[0] = jointPosRight;
  //left: 6
  //right: 7
  for(int i = 0; i < 9; i++){
      if(leftSlice[i+1] != null&&rightSlice[i+1] != null){
        strokeWeight(5/(i+1));
        
            float green = map(leftSlice[i].z, 900, 1300, 0, 255);
            float blue = map(leftSlice[i].z, 900, 1300, 255, 0);
            stroke(0,green,blue,255);
        
        line(leftSlice[i].x, leftSlice[i].y, leftSlice[i].z, leftSlice[i+1].x, leftSlice[i+1].y, leftSlice[i+1].z);
          
             green = map(rightSlice[i].z, 900, 1300, 0, 255);
             blue = map(rightSlice[i].z, 900, 1300, 255, 0);
            stroke(0,green,blue,255);
            
        line(rightSlice[i].x, rightSlice[i].y, rightSlice[i].z, rightSlice[i+1].x, rightSlice[i+1].y, rightSlice[i+1].z);
      }
    }
  strokeWeight(1);
}

boolean drawLife(){
  pushMatrix();
  translate(550,500,1000);
  stroke(255,255,255);
  fill(255,255,255);
  sphere(20);
  if(life < 3){
  strokeWeight(4);
  stroke(255,0,0);
  line(20,20,-20,-30,-30,-20);
  line(-30,15,-20, 15,-30,-20);
  strokeWeight(1);
  stroke(255,255,255);
  }
  
  translate(60,0,0);
  fill(255,255,255);
  sphere(20);
  if (life < 2){
  strokeWeight(4);
  stroke(255,0,0);
  line(20,20,-20,-30,-30,-20);
  line(-30,15,-20, 15,-30,-20);
  strokeWeight(1);
  stroke(255,255,255);
  }
  
  translate(60,0,0);
  fill(255,255,255);
  sphere(20);
  if (life < 1){
  strokeWeight(4);
  stroke(255,0,0);
  line(15,15,-20,-30,-30,-20);
  line(-30,15,-20, 15,-30,-20);
  strokeWeight(1);
  
  }
  stroke(255,255,255);
  popMatrix();
  return life!=0;
}

void drawScore(){
  stroke(255);
  scale(1,-1);
  text((new Double(score)).toString(),-150,-120);
  
  
  scale(1,-1);
}

// -----------------------------------------------------------------
// SimpleOpenNI user events

void onNewUser(SimpleOpenNI curContext,int userId)
{
  println("onNewUser - userId: " + userId);
  println("\tstart tracking skeleton");
  
  context.startTrackingSkeleton(userId);
  newUser = true;
}

void onLostUser(SimpleOpenNI curContext,int userId)
{
  println("onLostUser - userId: " + userId);
}

void onVisibleUser(SimpleOpenNI curContext,int userId)
{
  //println("onVisibleUser - userId: " + userId);
}


// -----------------------------------------------------------------
// Keyboard events

void keyPressed()
{
  switch(key)
  {
  case ' ':
    context.setMirror(!context.mirror());
    break;
  }
    
  switch(keyCode)
  {
    case LEFT:
      rotY += 0.1f;
      break;
    case RIGHT:
      // zoom out
      rotY -= 0.1f;
      break;
    case UP:
      if(keyEvent.isShiftDown())
        zoomF += 0.01f;
      else
        rotX += 0.1f;
      break;
    case DOWN:
      if(keyEvent.isShiftDown())
      {
        zoomF -= 0.01f;
        if(zoomF < 0.01)
          zoomF = 0.01;
      }
      else
        rotX -= 0.1f;
      break;
  }
}

void getBodyDirection(int userId,PVector centerPoint,PVector dir)
{
  PVector jointL = new PVector();
  PVector jointH = new PVector();
  PVector jointR = new PVector();
  float  confidence;
  
  // draw the joint position
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_LEFT_SHOULDER,jointL);
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_HEAD,jointH);
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_RIGHT_SHOULDER,jointR);
  
  // take the neck as the center point
  confidence = context.getJointPositionSkeleton(userId,SimpleOpenNI.SKEL_NECK,centerPoint);
  
  /*  // manually calc the centerPoint
  PVector shoulderDist = PVector.sub(jointL,jointR);
  centerPoint.set(PVector.mult(shoulderDist,.5));
  centerPoint.add(jointR);
  */
  
  PVector up = PVector.sub(jointH,centerPoint);
  PVector left = PVector.sub(jointR,centerPoint);
    
  dir.set(up.cross(left));
  dir.normalize();
}
