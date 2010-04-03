/*
    Robot control console.
    Copyright (C) 2010 Darrell Taylor & Eric Hokanson

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import java.awt.Toolkit;
import java.awt.MediaTracker;

import processing.opengl.*;
import processing.net.*;
import procontroll.*;

import controlP5.*;

final String PHONE_IP = "192.168.1.109";
//final String JOYSTICK_NAME = "PLAYSTATION(R)3 Controller";
final String JOYSTICK_NAME = "Microsoft SideWinder Precision Pro (USB)";
final int CONTROL_PORT = 5555;
final int VIDEO_PORT = 4444;

// Kryonet client for control
com.esotericsoftware.kryonet.Client myClient; 

// Processing server for video
processing.net.Server vidServer;

// Joystick devices
ControllIO controll;
ControllDevice device;
DAController ps3;

// GUI
ControlP5 controlP5;

// Communication thread
DataThread thread;

PFont fontA;

int size = 0;
PImage android = createImage(20, 20, RGB);
byte[] imageBuffer;

float segLength = 50;

void setup(){
  size(640,640,OPENGL);
  //size(800,600,P3D);
  
  //fill(0);
  //frameRate(20);
  //rectMode(CENTER);
  fontA = loadFont("Ziggurat-HTF-Black-32.vlw");

  controlP5 = new ControlP5(this);
  controlP5.addTextfield("speech",100,600,300,20).setFocus(true);
  controlP5.addSlider("lifeBar",0,15,1,20,height-115,20,100).setNumberOfTickMarks(15);
  controlP5.addSlider("powerBar",0,100,100,width-40,height-115,20,100);

  controll = ControllIO.getInstance(this);
  controll.printDevices();
 
  device = controll.getDevice(JOYSTICK_NAME);
  ps3 = new DAController(device, this);

  vidServer = new processing.net.Server(this, VIDEO_PORT);
  
  myClient = new com.esotericsoftware.kryonet.Client();
  
  thread = new DataThread(myClient, ps3);
  thread.start();

  Kryo kryo = myClient.getKryo();
  kryo.register(ControllerState.class);
  kryo.register(RobotState.class);

  try {
    println("Connecting to phone at " + PHONE_IP);
    myClient.connect(15000, PHONE_IP, CONTROL_PORT);
  } catch (IOException e) {
    println(e + ".  Bye Bye.");
    System.exit(0);
  }
}

void draw(){
  float x;
  float y;

  background(0);

  // Get the next available client
  processing.net.Client thisClient = vidServer.available();
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
  
/*
  fill(0,0,255);
  x = width/2 + ((width/2) *  ps3.leftX());
  y = height/2 + ((height/2) * ps3.leftY());
  rect(x,y,20,20);
  x =  width/2 + ((width/2) *  ps3.rightX());
  y =  height/2 + ((height/2) * ps3.rightY());
  fill(255,0,0);
  rect(x,y,20,20);
  */

  x = 0;
  y = 0;
  pushMatrix();
  translate(width, 0);
  rotate(HALF_PI);
  scale(1.0);
  beginShape();
  texture(android);
  vertex(x, y, x, y);
  vertex(x + android.width, y, x + android.width, y);
  vertex(x + android.width, y + android.height, x + android.width, y + android.height);
  vertex(x, y + android.height, x, y + android.height);
  endShape(CLOSE);
  popMatrix();  
  
  // GUI components
  controlP5.controller("powerBar").setValue(thread.get_battery());
  if ((controlP5.controller("powerBar").value() / controlP5.controller("powerBar").max()) <= 0.25)
    controlP5.controller("powerBar").setColorForeground(color(255,0,0));
  else
    controlP5.controller("powerBar").setColorForeground(color(0,255,0));
  controlP5.controller("lifeBar").setValue(thread.get_hitPoints());
  if ((controlP5.controller("lifeBar").value() / controlP5.controller("lifeBar").max()) <= 0.25)
    controlP5.controller("lifeBar").setColorForeground(color(255,0,0));
  else
    controlP5.controller("lifeBar").setColorForeground(color(0,255,0));

  fill(128,0,128); 
  pushMatrix();
  translate(500, 575);
  rotate(radians(thread.get_azimuth()));
  box(100, 50, 5);
  popMatrix();
}


// function based on the processing library's new PImage function
// from http://processing.org/discourse/yabb2/YaBB.pl?num=1192330628
PImage loadPImageFromBytes(byte[] b,PApplet p) {
  Image img = Toolkit.getDefaultToolkit().createImage(b);
  MediaTracker t=new MediaTracker(p);
  t.addImage(img,0);
  try{
    t.waitForAll();
  }
  catch(Exception e){
    println(e);
  }
  return new PImage(img);
}


// ServerEvent message is generated when a new client connects 
// to an existing server.
void serverEvent(processing.net.Server someServer, processing.net.Client someClient) {
  println("We have a new video client: " + someClient.ip());
}


// This function is called when a client disconnects.
void disconnectEvent(processing.net.Client someClient) {
  println("Video client disconnected.");
}


void segment(float x, float y, float a) {
  translate(x, y);
  rotate(a);
  line(0, 0, segLength, 0);
}

public void speech(String theText) {
  // receiving text from controller texting
  println("a textfield event for controller 'speech': "+theText);
}

