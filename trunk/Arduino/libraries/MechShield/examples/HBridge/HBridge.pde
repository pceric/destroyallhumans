// Simple example on how to use the MechShield to
// trigger the H Bridge.

#include <MechShield.h>
#include <Wire.h>

Mech mymech;  // Create a new MechShield object

void setup() 
{ 
  mymech.begin();    // initialize the MechShield
} 
 
void loop() 
{ 
  // Set all 4 outputs to maximum
  mymech.analogWrite(HOUT1, 4095);
  mymech.analogWrite(HOUT2, 4095);
  mymech.analogWrite(HOUT3, 4095);
  mymech.analogWrite(HOUT4, 4095);
  delay(250);
  // Set all 4 outputs to off
  mymech.analogWrite(HOUT1, 0);
  mymech.analogWrite(HOUT2, 0);
  mymech.analogWrite(HOUT3, 0);
  mymech.analogWrite(HOUT4, 0);
  delay(250);
} 
