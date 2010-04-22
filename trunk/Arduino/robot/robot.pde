/*
    Robot control code using Arduino and ServoShield.
 Copyright (C) 2010 Eric Hokanson
 
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

#include <avr/sleep.h>
#include <EEPROM.h>
#include <ServoShield.h>
#include "Controller.h"
#include "ServoShieldPins.h"

// Print out debug info
#define DEBUG 0

// From ServoShield specs
#define STEPS_PER_DEGREE 5.55

// Servo pins on ServoShield
const int righthip = SSP6;
const int rightknee = SSP5;
const int rightankle = SSP4;
const int lefthip = SSP3;
const int leftknee = SSP2;
const int leftankle = SSP1;
const int turret = SSP7;
const int ssmap[16] = {
  SSP1,SSP2,SSP3,SSP4,SSP5,SSP6,SSP7,SSP8,SSP9,SSP10,SSP11,SSP12,SSP13,SSP14,SSP15,SSP16};
// SN754410 pins on Duem
const int lampPin = 11;  // Don't use pins 5 or 6 if possible
const int laserPin = 12;
const int lgunPin = 14;  // Analog 0
const int rgunPin = 15;  // Analog 1
// Other devices on Duem
const int pingPin = 3;
const int irPin = 3; // Analog
// Misc constants
const float STRIDE = 35;
const float LEAN = 15;
const int OFFSET[] = {
  getOffset(ssmap[0]), getOffset(ssmap[1]), getOffset(ssmap[2]), getOffset(ssmap[3]), getOffset(ssmap[4]), getOffset(ssmap[5]), 0};

// Some global vars
ServoShield servos;
boolean firstStep = true, leftStep = true, turretAbsolute = false, LaserOn = false, LampOn = false, RgunOn = false, LgunOn = false , moving = false;
int MoveSpeed = 150, StrideOffset = 0, turretElevation = 0, Damage = 0;
unsigned short stepNo = 0;

long lastPing = 0;

Controller prev_joystick1;
Controller joystick1;

void setup() {
  Serial.begin(19200);
  analogWrite(lampPin, 0);
  pinMode(laserPin, OUTPUT);
  pinMode(rgunPin, OUTPUT);
  pinMode(lgunPin, OUTPUT);
  for (int servo = 0; servo < 7; servo++) {
    servos.setbounds(ssmap[servo], 1000, 2000);  //Set the minimum and maximum pulse duration of the servo
    servos.setposition(ssmap[servo], 1500 + OFFSET[servo]);      //Set the initial position of the servo
  }
  servos.start();                         //Start the servo shield
  attachInterrupt(0, plateHit, RISING);  // interrupt on pin 2 to signal plate hit
  LOG("Ready");
}

void loop() {
  if (Serial.available()) {
    msgReady();
  } 
  else {
    //  firstStep = true;
    // movement(0, 0, 0, 0, 0, 0, MoveSpeed);
    //set_sleep_mode(SLEEP_MODE_IDLE);  // Allows serial port to wake up chip
    //sleep_enable();
    //sleep_mode();  // Sleep here until interrupt
    //sleep_disable();
  }
  moving = moveNow();
  if(!moving) lastPing = doPing();

}

char currentCommand = ' ';
void msgReady() {

  if (currentCommand == ' ') {
    char message = Serial.read();
    if (message == 'C') {
      LOG("Got C code");
      currentCommand = 'C';
    }
    else if(message == 'A') {
      LOG("Got A code");
      currentCommand = 'A';
    }
    else if(message == 'R') {
      LOG("Got R code");
      Damage = 0;
      currentCommand = ' ';
    }
    else if(message == 'K') {
      currentCommand = ' ';
    }
    sendStatus();
  }
  else
  {
    if (currentCommand   == 'C' && Serial.available() >= 21) {
      prev_joystick1 = joystick1;
      if (!readJoystick())
        return;
      handleJoystick();
      currentCommand = ' ';
    }
    else if(currentCommand == 'A' && Serial.available() >= 2) {
      while (Serial.available() < 2)
        delay(1);
      char x = Serial.read(), y = Serial.read();
      servos.setposition(turret, constrain(servos.getposition(turret) + x, 1167, 1833));
      turretElevation = constrain(turretElevation + y, -166, 166);
      currentCommand = ' ';
    }
  }
}
// Sends status back to Android
void sendStatus() {
  // Send some info back
  Serial.print(analogRead(2));  // Battery level
  Serial.print(" ");
  Serial.print(Damage);
  Serial.print(" ");
  Serial.print(MoveSpeed);
  Serial.print(" ");
  Serial.print(StrideOffset);
  Serial.print(" ");
  Serial.print(servos.getposition(turret));
  Serial.print(" ");
  Serial.print(turretElevation);
  Serial.print(" ");
  Serial.print(lastPing);
  Serial.print(" ");
  Serial.print(analogRead(irPin));
  Serial.print(" ");
  Serial.print(LampOn);
  Serial.print(" ");
  Serial.print(LaserOn);
  Serial.print(" ");
  Serial.print(RgunOn);
  Serial.print(" ");
  Serial.print(LgunOn);
  Serial.print(" ");
  Serial.print(moving);
  Serial.print("\n");
}

// Waits for enough data and gets joystick state
boolean readJoystick() {
  char buffer[21], checksum = 0;

  while (Serial.available() < 21)
    delay(1);

  for (int i = 0; i < 20; i++) {
    buffer[i] = Serial.read();
    checksum ^= buffer[i];
  }
  buffer[20] = Serial.read();

  if (checksum != buffer[20]) {
    char msg[64];
    sprintf(msg, "Checksum Error. Expected %d got %d.", checksum, buffer[20]);
    LOG(msg);
    return false;
  }

  joystick1.X = buffer[0];
  joystick1.C = buffer[1];
  joystick1.T = buffer[2];
  joystick1.S = buffer[3];
  joystick1.L1 = buffer[4];
  joystick1.L2 = buffer[5];
  joystick1.L3 = buffer[6];
  joystick1.R1 = buffer[7];
  joystick1.R2 = buffer[8];
  joystick1.R3 = buffer[9];
  joystick1.Select = buffer[10];
  joystick1.Start = buffer[11];
  joystick1.Up = buffer[12];
  joystick1.Down = buffer[13];
  joystick1.Left = buffer[14];
  joystick1.Right = buffer[15];
  joystick1.LeftX = buffer[16];
  joystick1.LeftY = buffer[17];
  joystick1.RightX = buffer[18];
  joystick1.RightY = buffer[19];

  return true;
}

// Handles joystick input
void handleJoystick() {
  float StrideLengthLeft, StrideLengthRight;
  int offset = StrideOffset;
  // Movement
  if ((joystick1.LeftY > DEAD_ZONE || joystick1.LeftY < -DEAD_ZONE) && !moving){
    offset += (joystick1.LeftX / 10);  // Try and gently turn direction
    if (joystick1.LeftY > 0) {
      StrideLengthLeft = -(joystick1.LeftY / 3); // -STRIDE;
      StrideLengthRight = -(joystick1.LeftY / 3); // -STRIDE;
      if (offset < 0)
        StrideLengthLeft += -offset;
      else if (offset > 0)
        StrideLengthRight += offset;
    } 
    else {
      StrideLengthLeft = -(joystick1.LeftY / 3); // STRIDE;
      StrideLengthRight = -(joystick1.LeftY / 3); // STRIDE;
      if (offset < 0)
        StrideLengthLeft -= -offset;
      else if (offset > 0)
        StrideLengthRight -= offset;
    }
    // Normal walk - too much top weight to work correctly
    if (stepNo % 5 == 0) {
      movement(0, 0, 0, -LEAN, 0, 0, MoveSpeed);  // Lean right
      //firstStep = false;
    }
    //if (leftStep) {
    if (stepNo % 5 == 1) {
      movement(int(LEAN), int(StrideLengthRight), int(StrideLengthRight), int(-LEAN), int(-StrideLengthLeft), int(-StrideLengthLeft), int(MoveSpeed));  // Step left
    }
    if (stepNo % 5 == 2) {
      movement(int(-LEAN), int(StrideLengthRight), int(StrideLengthRight), int(LEAN), int(-StrideLengthLeft), int(-StrideLengthLeft), int(MoveSpeed));  // Lean left
      //leftStep = false;
    } 
    if (stepNo % 5 == 3) {
      movement(int(-LEAN), int(-StrideLengthRight), int(-StrideLengthRight), int(LEAN), int(StrideLengthLeft), int(StrideLengthLeft), int(MoveSpeed));  // Step right
    }
    if (stepNo % 5 == 4) {
      movement(int(LEAN), int(-StrideLengthRight), int(-StrideLengthRight), int(-LEAN), int(StrideLengthLeft), int(StrideLengthLeft), int(MoveSpeed));  // Lean right
      //leftStep = true;
    }
    stepNo++;
  }
  if (joystick1.L1) {
    digitalWrite(lgunPin, HIGH);
    LgunOn = true;
  } else {
    digitalWrite(lgunPin, LOW);
    LgunOn = false;
  }
  if (joystick1.R1) {
    digitalWrite(rgunPin, HIGH);
    RgunOn = true;
  } else {
    digitalWrite(rgunPin, LOW);
    RgunOn = false;
  }
  //if (!joystick1.R3 && prev_joystick1.R3)
  //turretAbsolute = !turretAbsolute;
  if (!joystick1.Select && prev_joystick1.Select)
    toggleLaser();
  if (!joystick1.Start && prev_joystick1.Start)
    toggleLamp();
  // Left turn
  if (!joystick1.S && prev_joystick1.S) {
    movement(20,  0,  0,-14,  0,  0, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(20,-35,-35,-14, 35, 35, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(0,-35,-35,  0, 35, 35, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(0, 35, 35,  0,-35,-35, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(20, 35, 35,-14,-35,-35, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(20,  0,  0,-14,-35,-35, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(-18,  0,  0, 16,-35,-35, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(-18,  0,  0, 16,  0,  0, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(0,  0,  0,  0,  0,  0, MoveSpeed);
    while(moveNow()==true) delay(1);
  }
  // Right turn
  if (!joystick1.C && prev_joystick1.C) {
    movement(-14,  0,  0, 20,  0,  0, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(-14, 35, 35, 20,-35,-35, MoveSpeed); 
    while(moveNow()==true) delay(1);
    movement(0, 35, 35,  0,-35,-35, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(0,-35,-35,  0, 35, 35, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(-14,-35,-35, 20, 35, 35, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(-14,-35,-35, 20,  0,  0, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(16,-35,-35,-18,  0,  0, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(16,  0,  0,-18,  0,  0, MoveSpeed);
    while(moveNow()==true) delay(1);
    movement(0,  0,  0,  0,  0,  0, MoveSpeed);
    while(moveNow()==true) delay(1);
  }
  // Reset position
  if (joystick1.X) {
    turretElevation = 0;
    servos.setposition(turret, 1500);
    movement(0, 0, 0, 0, 0, 0, MoveSpeed);
    while(moveNow()) delay(1);
    stepNo=0;
  }
  // Turret control
  if (turretAbsolute == true) {
    servos.setposition(turret, constrain(1500 + (joystick1.RightX * 2), 1167, 1833));  // 60 degree constrain
    turretElevation = joystick1.RightY;  // ~30 degree range
  } 
  else {
    if (joystick1.RightX != 0)
      servos.setposition(turret, constrain(servos.getposition(turret) + (joystick1.RightX / 10), 1167, 1833));
    if (joystick1.RightY != 0)
      turretElevation = constrain(turretElevation + (joystick1.RightY / 10), -166, 166);
  }
  // Adjustments
  if (joystick1.Up || joystick1.Down) {
    if (joystick1.Up)
      MoveSpeed -= 10;
    else
      MoveSpeed += 10;
  }
  if (joystick1.Left || joystick1.Right) {
    if (joystick1.Left)
      StrideOffset -= 1;
    else
      StrideOffset += 1;
  }
}
// start position
int rastart;
int rkstart;
int rhstart;
int lastart;
int lkstart;
int lhstart;
// distance to travel
int radist ;
int rkdist ;
int rhdist ;
int ladist ;
int lkdist ;
int lhdist ;

int speed;

unsigned long startMoveTime;
unsigned long endMoveTime;
unsigned long lastMoveTime;;
// Walk subroutine (positions in degrees from center; speed in ms)
void movement(int ra, int rk, int rh, int la, int lk, int lh, int s) {
  // Get start position
  rastart = servos.getposition(rightankle);
  rkstart = servos.getposition(rightknee);
  rhstart = servos.getposition(righthip);
  lastart = servos.getposition(leftankle);
  lkstart = servos.getposition(leftknee);
  lhstart = servos.getposition(lefthip);
  // Get distance to travel
  radist = (int(ra * STEPS_PER_DEGREE) + 1500 + OFFSET[3]) - rastart;
  rkdist = (int(rk * STEPS_PER_DEGREE) + 1500 + OFFSET[4]) - rkstart;
  rhdist = (int(rh * STEPS_PER_DEGREE) + 1500 + OFFSET[5] + turretElevation) - rhstart;
  ladist = (int(-la * STEPS_PER_DEGREE) + 1500 + OFFSET[0]) - lastart;  // Left side must be made negative because servos are "backwards"
  lkdist = (int(-lk * STEPS_PER_DEGREE) + 1500 + OFFSET[1]) - lkstart;
  lhdist = (int(-lh * STEPS_PER_DEGREE) + 1500 + OFFSET[2] - turretElevation) - lhstart;
  startMoveTime = millis();
  speed = s;
  endMoveTime = startMoveTime + speed;
  //char msg[64];
  //sprintf(msg, "Start: %d \t Stop: %d.", startMoveTime, endMoveTime);
  //LOG(msg);

}

bool moveNow()
{
  unsigned long i = millis(); 
  if(i < endMoveTime && i > lastMoveTime)
  {
    lastMoveTime = i;
    i = i - startMoveTime;
    servos.setposition(rightankle, rastart + int(radist * (i / speed)));
    servos.setposition(rightknee, rkstart + int(rkdist * (i / speed)));
    servos.setposition(righthip, rhstart + int(rhdist * (i / speed)));
    servos.setposition(leftankle, lastart + int(ladist * (i / speed)));
    servos.setposition(leftknee, lkstart + int(lkdist * (i / speed)));
    servos.setposition(lefthip, lhstart + int(lhdist * (i / speed)));
    return true;
  }
  return false;
}
// Toggles LED on or off
void toggleLamp() {
  if (LampOn) {
    LampOn = false;
    analogWrite(lampPin, 0);
    LOG("Lamp Off");
  } 
  else {
    LampOn = true;
    analogWrite(lampPin, 150);
    LOG("Lamp On");
  }
}

// Toggles laser on or off
void toggleLaser() {
  if (LaserOn) {
    LaserOn = false;
    digitalWrite(laserPin, LOW);
    LOG("Laser Off");
  } 
  else {
    LaserOn = true;
    digitalWrite(laserPin, HIGH);
    LOG("Laser On");
  }
}

// Operate our Ping)))
long doPing() {
  long duration;

  // The PING))) is triggered by a HIGH pulse of 2 or more microseconds.
  // Give a short LOW pulse beforehand to ensure a clean HIGH pulse:
  pinMode(pingPin, OUTPUT);
  digitalWrite(pingPin, LOW);
  delayMicroseconds(2);
  digitalWrite(pingPin, HIGH);
  delayMicroseconds(5);
  digitalWrite(pingPin, LOW);

  // The same pin is used to read the signal from the PING))): a HIGH
  // pulse whose duration is the time (in microseconds) from the sending
  // of the ping to the reception of its echo off of an object.
  pinMode(pingPin, INPUT);
  duration = pulseIn(pingPin, HIGH, 20000);

  return duration;
}

// Reads a signed int from EEPROM.  127 addresses
int getOffset(int address) {
  int tmp = EEPROM.read(address * 2) << 8;
  tmp += EEPROM.read((address * 2) + 1);
  return tmp;
}

// Fires when a targeting plate is hit
void plateHit() {
  ++Damage;
}

// Prints text to serial port if DEBUG is set
void LOG(char* text) {
  if(DEBUG) {
    Serial.print("L ");
    Serial.print(text);
    Serial.print("\n");
  }
}

