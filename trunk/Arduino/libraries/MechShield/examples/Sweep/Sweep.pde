// Simple example on how to use the MechShield to
// sweep a servo back and forth.

#include <MechShield.h>
#include <Wire.h>

Mech mymech;  // Create a new MechShield object

int pos;    // variable to store the servo position 
 
void setup() 
{ 
  mymech.begin();    // initialize the MechShield
} 
 
void loop() 
{ 
  for(pos = 0; pos < 180; pos++)  // goes from 0 degrees to 180 degrees 
  {                                  // in steps of 1 degree 
    mymech.setPosition(2, pos);      // tell servo number two to go to position in variable 'pos' 
    delay(15);                       // waits 15ms for the servo to reach the position 
  } 
  for(pos = 180; pos>=1; pos--)     // goes from 180 degrees to 0 degrees 
  {                                
    mymech.setPosition(2, pos);      // tell servo number two to go to position in variable 'pos' 
    delay(15);                       // waits 15ms for the servo to reach the position 
  } 
} 
