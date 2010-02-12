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
#include "ServoShieldPins.h"

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
int MoveSpeed = 100, StrideOffset = 0;

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
  Serial.println("Ready");
}

void loop() {
  float StrideLengthLeft, StrideLengthRight;
  int in, ta;
  if (Serial.available() > 0) {
    // read the incoming byte:
    in = Serial.read();
    if (in == 'l')
      toggleLaser();
    else if (in == 'p')
      doPing();
    else if (in == 'w' || in == 's') {
      if (in == 'w') {
        StrideLengthLeft = -STRIDE;
        StrideLengthRight = -STRIDE;
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
    else if (in == 'a') {
      movement(0.0,-35.0,-40.0,  0.0, 35.0, 37.0, MoveSpeed + 100.0);
      movement(0.0, 35.0, 37.0,  0.0,-35.0,-40.0, MoveSpeed + 100.0);
      movement(-16.0, 35.0, 37.0, 20.0,-35.0,-40.0, MoveSpeed + 100.0);
      movement(-16.0, 35.0, 37.0, 20.0,  0.0,  0.0, MoveSpeed + 100.0);
      movement(20.0,  0.0,  0.0,-16.0,  0.0,  0.0, MoveSpeed + 100.0);
    }
    else if (in == 'd') {
      movement(0.0, 35.0, 37.0,  0.0,-35.0,-40.0, MoveSpeed + 100.0);
      movement(0.0,-35.0,-40.0,  0.0, 35.0, 37.0, MoveSpeed + 100.0);
      movement(20.0,-35.0,-40.0,-14.0, 35.0, 37.0, MoveSpeed + 100.0);
      movement(20.0,  0.0,  0.0,-14.0, 35.0, 37.0, MoveSpeed + 100.0);
      movement(-14.0,  0.0,  0.0, 20.0,  0.0,  0.0, MoveSpeed + 100.0);
    }
    else if (in == 'q') {
      digitalWrite(lgunPin, HIGH);
      delay(2500);
      digitalWrite(lgunPin, LOW);
    }
    else if (in == 'e') {
      digitalWrite(rgunPin, HIGH);
      delay(2500);
      digitalWrite(rgunPin, LOW);
    }
    else if (in == 'm') {
      toggleLamp();
    }
    else if (in == 't') {
      ta = (Serial.read() - 48) * 1000;
      ta += (Serial.read() - 48) * 100;
      ta += (Serial.read() - 48) * 10;
      ta += (Serial.read() - 48);
      servos.setposition(turret, constrain(ta, 1200, 1800));
    }
    else if (in == 'z') {
      movement(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, MoveSpeed);
    }
    else if (in == '+' || in == '-') {
      if (in == '+')
        MoveSpeed -= 10;
      else
        MoveSpeed += 10;
      Serial.println(MoveSpeed, DEC);
    }
    else if (in == '[' || in == ']') {
      if (in == '[')
        StrideOffset -= 1;
      else
        StrideOffset += 1;
      Serial.println(StrideOffset, DEC);
    }
  } else {
    firstStep = true;
    movement(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, MoveSpeed);
    set_sleep_mode(SLEEP_MODE_IDLE);  // Allows serial port to wake up chip
    sleep_enable();
    sleep_mode();  // Sleep here until interrupt
    sleep_disable();
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
