import procontroll.*;
import java.io.*;
import processing.serial.*;

// The serial port
Serial myPort;       

ControllIO controll;
ControllDevice device;
PFont fontA;
DAController ps3;

void setup(){
  size(640,640);

  controll = ControllIO.getInstance(this);
  controll.printDevices();
  
  // List all the available serial ports
  println(Serial.list());

  device = controll.getDevice("PLAYSTATION(R)3 Controller");

  ps3 = new DAController(device);

  fill(0);
  frameRate(20);

  rectMode(CENTER);

  fontA = loadFont("Ziggurat-HTF-Black-32.vlw");

  // Set the font and its size (in units of pixels)
  textFont(fontA, 32);
   
}

void draw(){
 background(255);
 fill(0);

  float x =  width/2 + ((width/2) *  ps3.leftX());
  float y =  height/2 + ((height/2) * ps3.leftY());

   rect(x,y,20,20);

  x =  width/2 + ((width/2) *  ps3.rightX());
  y =  height/2 + ((height/2) * ps3.rightY());
  fill(255,0,0);
  rect(x,y,20,20);
  
  long time = System.nanoTime() / 1000;
  
  print("C " + time + ps3);
}




