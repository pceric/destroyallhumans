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

import processing.opengl.*;
import processing.net.*;
import procontroll.*;
//import java.io.*;
import processing.serial.*;

// The serial port
Serial myPort;
// Net client
Server myServer;

ControllIO controll;
ControllDevice device;
PFont fontA;
DAController ps3;

int size = 0;
PImage android = createImage(20, 20, RGB);
byte[] imageBuffer;

void setup(){
  size(800,600,OPENGL);

  controll = ControllIO.getInstance(this);
  controll.printDevices();
  
  // List all the available serial ports
  println(Serial.list());

  //device = controll.getDevice("PLAYSTATION(R)3 Controller");
  device = controll.getDevice("Controller (XBOX 360 For Windows)");
  ps3 = new DAController(device, this);

  //frameRate(20);

  rectMode(CENTER);

  // Set the font and its size (in units of pixels)
  fontA = loadFont("Ziggurat-HTF-Black-32.vlw");
  textFont(fontA, 32);

  myServer = new Server(this, 3333);
}

void draw(){
  background(255);
  // Get the next available client
  Client thisClient = myServer.available();
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

  float x = width/2 + ((width/2) *  ps3.leftX());
  float y = height/2 + ((height/2) * ps3.leftY());
  fill(0);
  rect(x,y,20,20);

  x = width/2 + ((width/2) *  ps3.rightX());
  y = height/2 + ((height/2) * ps3.rightY());
  fill(255,0,0); 
  rect(x,y,20,20);
  
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
  scale(1.70);
  endShape();

  long time = System.nanoTime() / 1000;
  
  //print("C " + time + ps3);
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
void serverEvent(Server someServer, Client someClient) {
  println("We have a new client: " + someClient.ip());
}

// This function is called when a client disconnects.
void disconnectEvent(Client someClient) {
  println("Client disconnected.");
}

