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
#define DEBUG 1

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
const int ssmap[16] = {SSP1,SSP2,SSP3,SSP4,SSP5,SSP6,SSP7,SSP8,SSP9,SSP10,SSP11,SSP12,SSP13,SSP14,SSP15,SSP16};
// SN754410 pins on Duem
const int lampPin = 11;  // Don't use pins 5 or 6 if possible
const int laserPin = 12;
const int rgunPin = 14;
const int lgunPin = 15;
// Other devices on Duem
const int pingPin = 4;
// Misc constants
const float STRIDE = 35;
const float LEAN = 15;
const int OFFSET[] = {getOffset(ssmap[0]), getOffset(ssmap[1]), getOffset(ssmap[2]), getOffset(ssmap[3]), getOffset(ssmap[4]), getOffset(ssmap[5]), 0};

// Some global vars
ServoShield servos;
boolean firstStep = true, LaserOn = false, LampOn = false;
int MoveSpeed = 100, StrideOffset = 0, Damage = 0;

Controller prev_joystick1;
Controller joystick1;

void setup() {
  Serial.begin(9600);
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
  } else {
    firstStep = true;
    movement(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, MoveSpeed);
    set_sleep_mode(SLEEP_MODE_IDLE);  // Allows serial port to wake up chip
    sleep_enable();
    sleep_mode();  // Sleep here until interrupt
    sleep_disable();
  }
}

void msgReady() {
  char message = Serial.read();
  if (message == 'C') {
    LOG("Got C code");
    prev_joystick1 = joystick1;
    readJoystick();
    handleJoystick();
  }
  else if(message == 'R') {
    LOG("Got R code");
    Damage = 0;
  }
  sendStatus();
}

// Sends status back to Android
void sendStatus() {
    LOG("Replying");
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
    Serial.print("\n");
}

// Waits for enough data and gets joystick state
void readJoystick() {
    while (Serial.available() < 20)
      delay(1);
    joystick1.X = Serial.read();
    joystick1.C = Serial.read();
    joystick1.T = Serial.read();
    joystick1.S = Serial.read();
    joystick1.L1 = Serial.read();
    joystick1.L2 = Serial.read();
    joystick1.L3 = Serial.read();
    joystick1.R1 = Serial.read();
    joystick1.R2 = Serial.read();
    joystick1.R3 = Serial.read();
    joystick1.Select = Serial.read();
    joystick1.Start = Serial.read();
    joystick1.Up = Serial.read();
    joystick1.Down = Serial.read();
    joystick1.Left = Serial.read();
    joystick1.Right = Serial.read();
    joystick1.LeftX = Serial.read();
    joystick1.LeftY = Serial.read();
    joystick1.RightX = Serial.read();
    joystick1.RightY = Serial.read();
}

// Handles joystick input
void handleJoystick() {
  float StrideLengthLeft, StrideLengthRight;
  // Movement
  if (joystick1.LeftY > DEAD_ZONE || joystick1.LeftY < -DEAD_ZONE) {
    if (joystick1.LeftY > DEAD_ZONE) {
      StrideLengthLeft = -(joystick1.LeftY / 3); // -STRIDE;
      StrideLengthRight = -(joystick1.LeftY / 3); // -STRIDE;
      if (StrideOffset < 0)
        StrideLengthLeft += -StrideOffset;
      else if (StrideOffset > 0)
        StrideLengthRight += StrideOffset;
    } else {
      StrideLengthLeft = STRIDE;
      StrideLengthRight = STRIDE;
      if (StrideOffset < 0)
        StrideLengthLeft -= -StrideOffset;
      else if (StrideOffset > 0)
        StrideLengthRight -= StrideOffset;
    }
    // Normal walk - too much top weight to work correctly
    if (firstStep)
      movement(0.0, 0.0, 0.0, -LEAN, 0.0, 0.0, MoveSpeed);  // Lean right
    movement(LEAN, StrideLengthRight, StrideLengthRight, -LEAN, -StrideLengthLeft, -StrideLengthLeft, MoveSpeed);  // Step left
    movement(-LEAN, StrideLengthRight, StrideLengthRight, LEAN, -StrideLengthLeft, -StrideLengthLeft, MoveSpeed);  // Lean left
    movement(-LEAN, -StrideLengthRight, -StrideLengthRight, LEAN, StrideLengthLeft, StrideLengthLeft, MoveSpeed);  // Step right
    movement(LEAN, -StrideLengthRight, -StrideLengthRight, -LEAN, StrideLengthLeft, StrideLengthLeft, MoveSpeed);  // Lean right
    firstStep = false;
  }
  if (joystick1.LeftX > (DEAD_ZONE + 100)) {
    movement(0.0,-35.0,-40.0,  0.0, 35.0, 37.0, MoveSpeed + 100.0);
    movement(0.0, 35.0, 37.0,  0.0,-35.0,-40.0, MoveSpeed + 100.0);
    movement(-16.0, 35.0, 37.0, 20.0,-35.0,-40.0, MoveSpeed + 100.0);
    movement(-16.0, 35.0, 37.0, 20.0,  0.0,  0.0, MoveSpeed + 100.0);
    movement(20.0,  0.0,  0.0,-16.0,  0.0,  0.0, MoveSpeed + 100.0);
  }
  else if (joystick1.LeftX < (-DEAD_ZONE - 100)) {
    movement(0.0, 35.0, 37.0,  0.0,-35.0,-40.0, MoveSpeed + 100.0);
    movement(0.0,-35.0,-40.0,  0.0, 35.0, 37.0, MoveSpeed + 100.0);
    movement(20.0,-35.0,-40.0,-14.0, 35.0, 37.0, MoveSpeed + 100.0);
    movement(20.0,  0.0,  0.0,-14.0, 35.0, 37.0, MoveSpeed + 100.0);
    movement(-14.0,  0.0,  0.0, 20.0,  0.0,  0.0, MoveSpeed + 100.0);
  }
  if (joystick1.L1)
    digitalWrite(lgunPin, HIGH);
  else
    digitalWrite(lgunPin, LOW);
  if (joystick1.R1)
    digitalWrite(rgunPin, HIGH);
  else
    digitalWrite(rgunPin, LOW);
  if (joystick1.Select != prev_joystick1.Select)
    toggleLaser();
  if (joystick1.C != prev_joystick1.C)
    doPing();
  if (joystick1.S != prev_joystick1.S)
    toggleLamp();
  // Reset position
  if (joystick1.X)
    movement(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, MoveSpeed);
  // Turret control
  if (joystick1.RightX > DEAD_ZONE || joystick1.RightX < -DEAD_ZONE) {
    int ta = (joystick1.RightX * 2) + 1500;
    servos.setposition(turret, constrain(ta, 1200, 1800));
  }
  if (joystick1.RightY > DEAD_ZONE || joystick1.RightY < -DEAD_ZONE) {
    int hips = (joystick1.RightX * 2) + 1500;
    servos.setposition(righthip, hips);
    servos.setposition(lefthip, hips);
  }
  // Adjustments
  if (joystick1.Up || joystick1.Down) {
    if (joystick1.Up)
      MoveSpeed -= 10;
    else
      MoveSpeed += 10;
    //Serial.println(MoveSpeed, DEC);
  }
  if (joystick1.Left || joystick1.Right) {
    if (joystick1.Left)
      StrideOffset -= 1;
    else
      StrideOffset += 1;
    //Serial.println(StrideOffset, DEC);
  }
}

// Walk subroutine (positions in degrees from center; speed in ms)
void movement(float ra, float rk, float rh, float la, float lk, float lh, float speed) {
  // Get start position
  int rastart = servos.getposition(rightankle);
  int rkstart = servos.getposition(rightknee);
  int rhstart = servos.getposition(righthip);
  int lastart = servos.getposition(leftankle);
  int lkstart = servos.getposition(leftknee);
  int lhstart = servos.getposition(lefthip);
  // Get distance to travel
  int radist = (int(ra * STEPS_PER_DEGREE) + 1500 + OFFSET[3]) - rastart;
  int rkdist = (int(rk * STEPS_PER_DEGREE) + 1500 + OFFSET[4]) - rkstart;
  int rhdist = (int(rh * STEPS_PER_DEGREE) + 1500 + OFFSET[5]) - rhstart;
  int ladist = (int(-la * STEPS_PER_DEGREE) + 1500 + OFFSET[0]) - lastart;  // Left side must be made negative because servos are "backwards"
  int lkdist = (int(-lk * STEPS_PER_DEGREE) + 1500 + OFFSET[1]) - lkstart;
  int lhdist = (int(-lh * STEPS_PER_DEGREE) + 1500 + OFFSET[2]) - lhstart;
  // Loop till we're done
  for (int i = 1; i <= int(speed); i++) {
    servos.setposition(rightankle, rastart + int(radist * (i / speed)));
    servos.setposition(rightknee, rkstart + int(rkdist * (i / speed)));
    servos.setposition(righthip, rhstart + int(rhdist * (i / speed)));
    servos.setposition(leftankle, lastart + int(ladist * (i / speed)));
    servos.setposition(leftknee, lkstart + int(lkdist * (i / speed)));
    servos.setposition(lefthip, lhstart + int(lhdist * (i / speed)));
    delay(1);
  }
}

// Toggles LED on or off
void toggleLamp() {
  if (LampOn) {
    LampOn = false;
    analogWrite(lampPin, 0);
  } else {
    LampOn = true;
    analogWrite(lampPin, 170);
  }
}

// Toggles laser on or off
void toggleLaser() {
  if (LaserOn) {
    LaserOn = false;
    digitalWrite(laserPin, LOW);
  } else {
    LaserOn = true;
    digitalWrite(laserPin, HIGH);
  }
}

// Operate our Ping))
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
  
  Serial.print(duration);
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
