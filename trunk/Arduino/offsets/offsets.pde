/*
    Servo offset tuning program.
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

#include <EEPROM.h>
#include <ServoShield.h>
#include "ServoShieldPins.h"

#define NUM_SERVOS 9

const int ssmap[16] = {SSP1,SSP2,SSP3,SSP4,SSP5,SSP6,SSP7,SSP8,SSP9,SSP10,SSP11,SSP12,SSP13,SSP14,SSP15,SSP16};

ServoShield servos;
int offsets[NUM_SERVOS], cservo = 0;

void setup() {
  Serial.begin(9600);
  for (int servo = 0; servo < NUM_SERVOS; servo++) {
    servos.setbounds(servo, 1000, 2000);  //Set the minimum and maximum pulse duration of the servo
    servos.setposition(servo, 1500);      //Set the initial position of the servo
    offsets[servo] = 0;
  }
  servos.start();                         //Start the servo shield
  Serial.println("Ready");
  Serial.println("Enter servo number to adjust, 'r' to read values from EEPROM, or 's' to store.");
}

void loop() {
  int in;
  if (Serial.available() > 0) {
    // read the incoming byte:
    in = Serial.read();
    if (in > 48 && in < 57) {
      cservo = ssmap[in - 48 - 1];
      Serial.print("Adjusting servo ");
      Serial.print(in - 48, DEC);
      Serial.println(". +/- to increment or decrement offset.");
    }
    else if (in == '+') {
      offsets[cservo] += 1;
      servos.setposition(cservo, 1500 + offsets[cservo]);
      Serial.println(offsets[cservo], DEC);
    }
    else if (in == '-') {
      offsets[cservo] -= 1;
      servos.setposition(cservo, 1500 + offsets[cservo]);
      Serial.println(offsets[cservo], DEC);
    }
    else if (in == 'p') {
      for (int i = 0; i < NUM_SERVOS; i++) {
        Serial.print(i + 1, DEC);
        Serial.print(": ");
        Serial.println(offsets[ssmap[i]], DEC);
      }
    }
    else if (in == 'r') {
      read();
      Serial.println("Retrieved");
    }
    else if (in == 's') {
      save();
      Serial.println("Saved");
    }
    else
      Serial.println("Unknown Command");
  }
}

void read() {
  for (int i = 0; i < NUM_SERVOS; i++) {
    offsets[ssmap[i]] = readInt(ssmap[i]);
    servos.setposition(ssmap[i], 1500 + offsets[ssmap[i]]);
  }
}

void save() {
  for (int i = 0; i < NUM_SERVOS; i++)
    storeInt(ssmap[i], offsets[ssmap[i]]);
}

// Writes a signed int to EEPROM.  127 addresses
void storeInt(int address, int val) {
  EEPROM.write(address * 2, val >> 8);
  EEPROM.write((address * 2) + 1, val);
}

// Reads a signed int from EEPROM.  127 addresses
int readInt(int address) {
  int tmp = EEPROM.read(address * 2) << 8;
  tmp += EEPROM.read((address * 2) + 1);
  return tmp;
}
