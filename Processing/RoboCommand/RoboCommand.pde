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

import hypermedia.net.*;

import java.awt.Toolkit;
import java.awt.MediaTracker;


import processing.opengl.*;
import processing.net.*;
import procontroll.*;

import controlP5.*;

final String PHONE_IP = "192.168.2.254";
final String JOYSTICK_NAME = "PLAYSTATION(R)3 Controller";
//final String JOYSTICK_NAME = "Microsoft SideWinder Precision Pro (USB)";
final int CONTROL_PORT = 5555;
final int VIDEO_PORT = 4444;

// Kryonet client for control
com.esotericsoftware.kryonet.Client myClient; 

// Processing server for video
//processing.net.Server vidServer;
UDP vidServer;

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
PImage android;
byte[] imageBuffer;

//byte[] packetBuffer = new ByteBuffer(64000);
byte[] packetBuffer = new byte[64000];

int packetBuffPos = 0;

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

  //vidServer = new processing.net.Server(this, VIDEO_PORT);
  
  myClient = new com.esotericsoftware.kryonet.Client();
  
  thread = new DataThread(myClient, ps3);
  thread.start();

  Kryo kryo = myClient.getKryo();
  kryo.register(ControllerState.class);
  kryo.register(RobotState.class);
  
  Arrays.fill(packetBuffer,0,packetBuffer.length, (byte)2);
  
  
  try {
    println("Connecting to phone at " + PHONE_IP);
    myClient.connect(15000, PHONE_IP, CONTROL_PORT);
  } catch (IOException e) {
    println(e + ".  Bye Bye.");
    System.exit(0);
  }
  
  vidServer = new UDP(this, VIDEO_PORT);
  vidServer.setReceiveHandler( "videoPacketHandler"); 
  
 
}


void draw(){
  float x;
  float y;
  float z;

vidServer.listen();

  background(0);   
     
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
  z = 1;
  
  if(android != null)
  {
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
  }
  
  /*
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
  
  */
}


// function based on the processing library's new PImage function
// from http://processing.org/discourse/yabb2/YaBB.pl?num=1192330628
PImage loadPImageFromBytes(byte[] b,PApplet p) {
  
 
  Image img = Toolkit.getDefaultToolkit().createImage(b);
  MediaTracker t = new MediaTracker(p);
  t.addImage(img,0);
  try{
    t.waitForAll();
  }
  catch(Exception e){
    println(e);
    return null;
  }
 // println("loaded img");
  return new PImage(img);
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

void videoPacketHandler(byte[] message, String ip, int port) {
   
 println("Server send me video packet of length: "+message.length);

 int msgPos = 0;
 while( msgPos < message.length)
   {
     packetBuffer[packetBuffPos] = message[msgPos];             
     packetBuffPos++;
     msgPos++;
   }
    //if(sumLast32() == 0) {
      println("found end");
      imageBuffer = new byte[packetBuffPos];
      System.arraycopy(packetBuffer,0,imageBuffer,0,packetBuffPos - 32);
      android = loadPImageFromBytes(imageBuffer, this);
      packetBuffPos = 0;
    //}
 }


int sumLast32()
{
  if(packetBuffPos < 32)
    return -1;
  
  int sum = 0;
  for(int i = packetBuffPos - 32; i < packetBuffPos; i++)
  {
     sum += packetBuffer[i]; 
  }
  return sum;
}

