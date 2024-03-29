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
final String PHONE_IP = "192.168.2.254";
final String JOYSTICK_NAME = "PLAYSTATION(R)3 Controller";
//final String JOYSTICK_NAME = "Microsoft SideWinder Precision Pro (USB)";
final int CONTROL_PORT = 5555;
final int VIDEO_PORT = 4444;
final int MAX_LIFE = 20;

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
Crosshair crosshairL, crosshairR;
ControlPad turret;
CheckBox checkbox;

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
  crosshairL = new Crosshair(controlP5,"L",ts.leftCrossHairX,ts.leftCrossHairY,30,30);
  crosshairR = new Crosshair(controlP5,"R",ts.rightCrossHairX,ts.rightCrossHairY,30,30);
  turret = new ControlPad(controlP5,"Turret",1,430,100,50);
  checkbox = controlP5.addCheckBox("LightGroup",width-115,height-140);
  checkbox.setItemsPerRow(0);
  checkbox.setSpacingColumn(50);
  checkbox.addItem("Laser",0);
  checkbox.addItem("Lamp",1);
  controlP5.addSlider("cb",0,255,ts.targetChromaBlue,100,height-125,100,20).setLabel("Blue");
  controlP5.addSlider("cr",0,255,ts.targetChromaRed,225,height-125,100,20).setLabel("Red");
  controlP5.addSlider("tolerance",0,32,ts.tolerance,350,height-125,100,20).setLabel("Tolerance");
  controlP5.addTextfield("speech",100,height-40,300,20).setFocus(true);
  controlP5.addSlider("lifeBar",0,MAX_LIFE,MAX_LIFE,20,height-115,20,100).setLabel("Life");
  Slider s1 = (Slider)controlP5.controller("lifeBar");
  s1.setNumberOfTickMarks(15);
  s1.snapToTickMarks(true);
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
    myClient.connect(15000, PHONE_IP, CONTROL_PORT);
  } catch (IOException e) {
    println(e + ".  Bye Bye.");
    exit();
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
  
  // Draw video image
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
  
  // Top right stats
  fill(0, 255, 0);
  text("Front: " + (int)(23.897 * pow((thread.get_irDistance() * .0049),-1.1907)) + " inches", width-100, 20);  // from http://www.arduino.cc/cgi-bin/yabb2/YaBB.pl?num=1230387822/6#6
  text("Back: " + (thread.get_sonarDistance() / 74 / 2) + " inches", width-100, 40);
  
  // Draw targeting blob
  TargetBlob tb = thread.getTargetBlob();
  if(tb != null)
  {
     float ratio = (float)width/(float)android.width;
     noFill();
     stroke(255,0,251);

     x = tb.x * ratio;
     y = tb.y * ratio;
     
    rect(x, y, tb.width * ratio, tb.height * ratio);
    fill(255, 0, 251);
    text(tb.chromaBlue + "," + tb.chromaRed, x - 10, y - (tb.height * ratio / 2 + 10));
  }
  
  // GUI components
  if (!thread.isAutoAim()) {
    controlP5.controller("cb").setColorForeground(100);
    controlP5.controller("cr").setColorForeground(100);
    controlP5.controller("tolerance").setColorForeground(100);
  } else {
    controlP5.controller("cb").setColorForeground(0xff00698c);
    controlP5.controller("cr").setColorForeground(0xff00698c);
    controlP5.controller("tolerance").setColorForeground(0xff00698c);
  }
  speedLabel.setValue("Speed: " + Integer.toString(thread.get_speed()));
  speedLabel.draw(this);
  offsetLabel.setValue("Offset: " + Integer.toString(thread.get_strideOffset()));
  offsetLabel.draw(this);
  if (thread.isLaserOn())
    checkbox.activate(0);
  else
    checkbox.deactivate(0);
  if (thread.isLampOn())
    checkbox.activate(1);
  else
    checkbox.deactivate(1);
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
  turret.setX((((float)thread.get_turretX() - 1167) / 666) * 100);
  turret.setY(50 - (((float)thread.get_turretY() + 166) / 333) * 50);

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
    super(theControlP5, (Tab)(theControlP5.getTab("default")), theName, theX, theY, theWidth, theHeight);
  }

  // overwrite the updateInternalEvents method to handle mouse and key inputs.
  public void updateInternalEvents(PApplet theApplet) {
    if(getIsInside()) {
      if(isMousePressed) {
        // My eyes!  The goggles do nothing!
        if (_myName.equals("R")) {
          ts.rightCrossHairX = (int)position.x();
          ts.rightCrossHairY = (int)position.y();
        } else { 
          ts.leftCrossHairX = (int)position.x();
          ts.leftCrossHairY = (int)position.y();
        }
        myClient.sendTCP(ts);
      }
    }
  }

  // overwrite the draw method for the controller's visual representation.
  public void draw(PApplet theApplet) {
    // use pushMatrix and popMatrix when drawing
    // the controller.
    theApplet.pushMatrix();
    theApplet.translate(position().x(), position().y());
    // draw the background of the controller.
    // draw the controller-handle
    
    // My eyes!  The goggles do nothing!
    if (_myName.equals("R")) {
      if (thread.isRGunOn())
        theApplet.fill(255, 0, 0);
      else
        theApplet.fill(0, 255, 0);
    } else { 
      if (thread.isLGunOn())
        theApplet.fill(255, 0, 0);
      else
        theApplet.fill(0, 255, 0);
    }

    theApplet.rect(0,-14,cWidth,30);
    theApplet.rect(-14,0,30,cHeight);

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

// create your own ControlP5 controller.
// your own controller needs to extend controlP5.Controller
// for reference and documentation see the javadoc for controlP5
// and the source code as indicated on the controlP5 website.
class ControlPad extends Controller {

  // 4 fields for the 2D controller-handle
  int cWidth=10, cHeight=10; 
  float cX, cY;

  ControlPad(ControlP5 theControlP5, String theName, int theX, int theY, int theWidth, int theHeight) {
    // the super class Controller needs to be initialized with the below parameters
    super(theControlP5, (Tab)(theControlP5.getTab("default")), theName, theX, theY, theWidth, theHeight);
    // the Controller class provides a field to store values in an 
    // float array format. for this controller, 2 floats are required.
    _myArrayValue = new float[2];
  }

  // overwrite the draw method for the controller's visual representation.
  public void draw(PApplet theApplet) {
    // use pushMatrix and popMatrix when drawing
    // the controller.
    theApplet.pushMatrix();
    theApplet.translate(position().x(), position().y());
    // draw the background of the controller.
    noFill();
    stroke(255);
    rect(0,0,width,height);

    // draw the controller-handle
    fill(255);
    rect(cX - (cWidth/2),cY - (cHeight/2),cWidth,cHeight);
    // draw the caption- and value-label of the controller
    // they are generated automatically by the super class
    captionLabel().draw(theApplet, 0, height + 4);
    valueLabel().draw(theApplet, 40, height + 4);

    theApplet.popMatrix();
  } 

  public void setValue(float theValue) {
  }

  public void setX(float x) {
    cX = x;
    _myArrayValue[0] = cX / ((float)(width-cWidth)/(float)width);
    _myArrayValue[1] = cY / ((float)(height-cHeight)/(float)height);
    valueLabel().set(adjustValue(_myArrayValue[0],0)+" / "+adjustValue(_myArrayValue[1],0));
  }

  public void setY(float y) {
    cY = y;
    _myArrayValue[0] = cX / ((float)(width-cWidth)/(float)width);
    _myArrayValue[1] = cY / ((float)(height-cHeight)/(float)height);
    valueLabel().set(adjustValue(_myArrayValue[0],0)+" / "+adjustValue(_myArrayValue[1],0));
  }

  // needs to be implemented since it is an abstract method in controlP5.Controller
  // nothing needs to be set since this method is only relevant for saving 
  // controller settings and only applies to (most) default Controllers.
  public void addToXMLElement(ControlP5XMLElement theElement) {
  }
}
