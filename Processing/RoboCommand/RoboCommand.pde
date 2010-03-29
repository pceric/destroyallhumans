import procontroll.*;
Client myClient; 


// Net client
Server vidServer;

ControllIO controll;
ControllDevice device;
PFont fontA;
DAController ps3;

String phoneIpAddress = "192.168.2.254";
String joystickName = "PLAYSTATION(R)3 Controller";

int controlPort = 5555;
int videoPort = 4444;

int size = 0;
PImage android = createImage(20, 20, RGB);
byte[] imageBuffer;
String inputBuffer = "Connecting To Robot";

float segLength = 50;

int azimuth, pitch, roll;


void setup(){
  size(640,640);
  
  //size(800,600,P3D);

  controll = ControllIO.getInstance(this);
  controll.printDevices();
 

  device = controll.getDevice(joystickName);
  ps3 = new DAController(device, this);

  frameRate(20);

  fill(0);
  frameRate(20);

  rectMode(CENTER);

  fontA = loadFont("Ziggurat-HTF-Black-32.vlw");

  vidServer = new Server(this, videoPort);
  
  
  println("Connecting to phone at " + phoneIpAddress);
  myClient = new Client(this, phoneIpAddress, controlPort); 


  smooth(); 
  strokeWeight(20.0);
  stroke(0, 100);
}

void draw(){
 // background(255);
  
  // Get the next available client
  Client thisClient = vidServer.available();
  // If the client is not null, try and get data
  if (thisClient != null) {
    // Get our image size
    if (size == 0 && thisClient.available() >= 4) {
      size = thisClient.read() << 24 | thisClient.read() << 16 | thisClient.read() << 8 | thisClient.read();
      println(hex(size) + "  " + size);
      imageBuffer = new byte[size];
    }
    // Draw image
    if (size > 0 && thisClient.available() >= size) {
      thisClient.readBytes(imageBuffer);
      android = loadPImageFromBytes(imageBuffer, this);
      //println("Image Done");
      size = 0;
    }
  }
  
  float x;
  float y;


/*
  x = width/2 + ((width/2) *  ps3.leftX());
  y = height/2 + ((height/2) * ps3.leftY());

  rect(x,y,20,20);

   rect(x,y,20,20);

  x =  width/2 + ((width/2) *  ps3.rightX());
  y =  height/2 + ((height/2) * ps3.rightY());
  fill(255,0,0);
  rect(x,y,20,20);
  
  */
  
  
  x = 0;
  y = 0;
  beginShape();
  texture(android);
  vertex(x, y, x, y);
  vertex(x + android.width, y, x + android.width, y);
  vertex(x + android.width, y + android.height, x + android.width, y + android.height);
  vertex(x, y + android.height, x, y + android.height);
  translate(width, 0);
  rotate(HALF_PI);
  scale(1.0);
  endShape();
  

 
 
  x = width/2;
  y = width/2;
  fill(255,0,0); 
  pushMatrix();
  segment(x, y, radians(azimuth)); 
  popMatrix();

 long time = System.nanoTime() / 1000;
 print("C " + time + ps3);
 try{
   myClient.write("C " + time + ps3);
 }
 catch(NullPointerException ex)
 {
   myClient = new Client(this, phoneIpAddress, controlPort); 
 }
 
 
}



// This function is called when a client disconnects.
void disconnectEvent(Client someClient) {
  println("Client disconnected.");
}


void clientEvent(Client someClient) {
   
    if(someClient.available() > 0){
    inputBuffer = someClient.readString(); 
     print("Server Says:  " + inputBuffer);
    String[] values = split(inputBuffer, ' ');
    if(values.length > 1)
    {
      azimuth = int(float(values[1]));
    }
}
}


void segment(float x, float y, float a) {
  translate(x, y);
  rotate(a);
  line(0, 0, segLength, 0);
}


