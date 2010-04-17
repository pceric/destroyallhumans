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

final int SCREEN_WIDTH = 800;
final int SCREEN_HEIGHT = 640;
final String PHONE_IP = "192.168.1.109";
final String JOYSTICK_NAME = "PLAYSTATION(R)3 Controller";
//final String JOYSTICK_NAME = "Microsoft SideWinder Precision Pro (USB)";
final int CONTROL_PORT = 5555;
final int VIDEO_PORT = 4444;
final int MAX_LIFE = 15;

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
Textlabel speedLabel, offsetLabel;
Crosshair crosshair;

// Communication thread
DataThread thread;

TargetSettings ts = new TargetSettings();

PFont fontA;

int size = 0;
PImage android;
byte[] imageBuffer;

//byte[] packetBuffer = new ByteBuffer(64000);
byte[] packetBuffer = new byte[64000];

int packetBuffPos = 0;

float segLength = 50;

void setup(){
  size(SCREEN_WIDTH,SCREEN_HEIGHT,OPENGL);
  
  //fill(0);
  //frameRate(20);
  rectMode(CENTER);
  //fontA = loadFont("Ziggurat-HTF-Black-32.vlw");
  //textFont(fontA);

  controlP5 = new ControlP5(this);
  //controlP5.load("controlP5.xml");

  speedLabel = new Textlabel(this,"Speed: 150",100,height-80,200,40);
  offsetLabel = new Textlabel(this,"Offset: 0",275,height-80,100,40);
  crosshair = new Crosshair(controlP5,"L",width/2,height/2,30,30);
  controlP5.addSlider("cb",0,255,ts.targetChromaBlue,100,height-125,100,20).setLabel("Blue");
  controlP5.addSlider("cr",0,255,ts.targetChromaRed,225,height-125,100,20).setLabel("Red");
  controlP5.addSlider("tolerance",0,32,ts.tolerance,350,height-125,100,20).setLabel("Tolerance");
  controlP5.addTextfield("speech",100,height-40,300,20).setFocus(true);
  controlP5.addSlider("lifeBar",0,MAX_LIFE,MAX_LIFE,20,height-115,20,100).setNumberOfTickMarks(15);
  controlP5.controller("lifeBar").setLabel("Life");
  controlP5.addKnob("azimuth",0,360,0,width-180,height-100,50).setLabel("Azimuth");
  controlP5.addSlider("robotPowerBar",0,100,100,width-100,height-115,20,100).setLabel("Robot");
  controlP5.addSlider("androidPowerBar",0,100,100,width-50,height-115,20,100).setLabel("Phone");

  controll = ControllIO.getInstance(this);
  controll.printDevices();
 
  device = controll.getDevice(JOYSTICK_NAME);
  ps3 = new DAController(device, this);

  myClient = new com.esotericsoftware.kryonet.Client();
  
  thread = new DataThread(myClient, ps3);
  thread.start();

  Kryo kryo = myClient.getKryo();
  kryo.register(ControllerState.class);
  kryo.register(RobotState.class);
  kryo.register(TargetBlob.class);
  kryo.register(TargetSettings.class);
  
  Arrays.fill(packetBuffer,0,packetBuffer.length, (byte)2);

  try {
    println("Connecting to phone at " + PHONE_IP);
    myClient.connect(15000, PHONE_IP, CONTROL_PORT, CONTROL_PORT + 1);
  } catch (IOException e) {
    println(e + ".  Bye Bye.");
    System.exit(0);
  }

  vidServer = new UDP(this, VIDEO_PORT);
  vidServer.setReceiveHandler("videoPacketHandler"); 
}


void draw(){
  float x = 0;
  float y = 0;
  float z = 1;

  vidServer.listen();

  background(0);
  
  if(android != null)
  {
    float ratio = (float)width/(float)android.width;
    
    pushMatrix();
    //translate(width, 0);
    //rotate(HALF_PI);
    //println("ratio = "+ratio);
    scale(ratio);
    beginShape();
    texture(android);
    vertex(x, y, x, y);
    vertex(x + android.width, y, x + android.width, y);
    vertex(x + android.width, y + android.height, x + android.width, y + android.height);
    vertex(x, y + android.height, x, y + android.height);
    endShape(CLOSE);
    popMatrix();      
  }
  
  // Framerate
  fill(0, 255, 0);
  text("FPS: " + thread.get_processFrameRate(), width-75, 20);
  text("Light: " + thread.get_lightLevel(), width-75, 40);

  TargetBlob tb = thread.getTargetBlob();
  
  if(tb != null)
  {
     float ratio = (float)width/(float)android.width;
     noFill();
     stroke(255,0,251);

     x = tb.x * ratio;
     y = tb.y * ratio;
     
    rect(x, y, tb.width * ratio, tb.height * ratio);
  }
  
  // GUI components
  speedLabel.setValue("Speed: " + Integer.toString(thread.get_speed()));
  speedLabel.draw(this);
  offsetLabel.setValue("Offset: " + Integer.toString(thread.get_strideOffset()));
  offsetLabel.draw(this);
  controlP5.controller("lifeBar").setValue(MAX_LIFE - thread.get_damage());
  if ((controlP5.controller("lifeBar").value() / controlP5.controller("lifeBar").max()) <= 0.25)
    controlP5.controller("lifeBar").setColorForeground(color(255,0,0));
  else
    controlP5.controller("lifeBar").setColorForeground(color(0,255,0));
  controlP5.controller("androidPowerBar").setLabel("Phone (" + thread.get_batteryTemp() + " C)");
  controlP5.controller("androidPowerBar").setValue(thread.get_battery());
  if ((controlP5.controller("androidPowerBar").value() / controlP5.controller("androidPowerBar").max()) <= 0.25)
    controlP5.controller("androidPowerBar").setColorForeground(color(255,0,0));
  else
    controlP5.controller("androidPowerBar").setColorForeground(color(0,255,0));
  controlP5.controller("robotPowerBar").setValue((thread.get_robotBattery() - 500) / 2);
  if ((controlP5.controller("robotPowerBar").value() / controlP5.controller("robotPowerBar").max()) <= 0.25)
    controlP5.controller("robotPowerBar").setColorForeground(color(255,0,0));
  else
    controlP5.controller("robotPowerBar").setColorForeground(color(0,255,0));
  controlP5.controller("azimuth").setValue(thread.get_azimuth());

  fill(128,0,128);
  stroke(128);
  pushMatrix();
  translate(500, 575);
  rotateX(radians(thread.get_roll()) + HALF_PI);
  rotateY(radians(thread.get_pitch()));
  box(100, 50, 5);
  popMatrix();
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


// callback for speech text box
public void speech(String theText) {
  println("Speaking: " + theText);
  ps3.getState().extraData = theText;
}

// callback for Blue slider
public void cb(float theValue) {
  if (ts.targetChromaBlue != (int)theValue) {
    ts.targetChromaBlue = (int)theValue;
    myClient.sendTCP(ts);
  }
}

// callback for Red slider
public void cr(float theValue) {
  if (ts.targetChromaRed != (int)theValue) {
    ts.targetChromaRed = (int)theValue;
    myClient.sendTCP(ts);
  }
}

// callback for Tolerance slider
public void tolerance(float theValue) {
  if (ts.tolerance != (int)theValue) {
    ts.tolerance = (int)theValue;
    myClient.sendTCP(ts);
  }
}

void videoPacketHandler(byte[] message, String ip, int port) {
  //println("Server send me video packet of length: "+message.length);

  int msgPos = 0;
  while( msgPos < message.length)
  {
    packetBuffer[packetBuffPos] = message[msgPos];             
    packetBuffPos++;
    msgPos++;
  }
  imageBuffer = new byte[packetBuffPos];
  System.arraycopy(packetBuffer,0,imageBuffer,0,packetBuffPos - 32);
  android = loadPImageFromBytes(imageBuffer, this);
  packetBuffPos = 0;
}

class Crosshair extends Controller {

  // 4 fields for the 2D controller-handle
  int cWidth=2, cHeight=2; 

  Crosshair (ControlP5 theControlP5, String theName, int theX, int theY, int theWidth, int theHeight) {
    // the super class Controller needs to be initialized with the below parameters
    super(theControlP5,  (Tab)(theControlP5.getTab("default")), theName, theX, theY, theWidth, theWidth);
  }


  // overwrite the draw method for the controller's visual representation.
  public void draw(PApplet theApplet) {
    // use pushMatrix and popMatrix when drawing
    // the controller.
    theApplet.pushMatrix();
    theApplet.translate(position().x(), position().y());
    // draw the background of the controller.
    // draw the controller-handle
    
    fill(0,255,0);
    rect(0,-14,cWidth,30);
    rect(-14,0,30,cHeight);

    theApplet.popMatrix();
  } 

 
  public void setValue(float theValue) {
    
  }

  // needs to be implemented since it is an abstract method in controlP5.Controller
  // nothing needs to be set since this method is only relevant for saving 
  // controller settings and only applies to (most) default Controllers.
  public void addToXMLElement(ControlP5XMLElement theElement) {
  }
}

