#include <AFMotor.h>

#define BUFFERSIZE 256

// ** GENERAL SETTINGS ** - General preference settings
boolean DEBUGGING = false; // Whether debugging output over serial is on by defauly (can be flipped with 'h' command)
const int ledPin = 13; // LED turns on while running servos

AF_DCMotor lift(1, MOTOR12_1KHZ);
AF_DCMotor left(2, MOTOR12_1KHZ);
AF_DCMotor right(3, MOTOR12_1KHZ);
int motorSpeed = 200; // Default motorSpeed setting. Use a range from 100-255

// No config required for these parameters
char incomingByte; // Holds incoming serial values
char msg[8]; // For passing back serial messages
char inBytes[BUFFERSIZE]; //Buffer for serial in messages
int serialIndex = 0; 
int serialAvail = 0;

void setup() {
  Serial.begin(9600);
  lift.setSpeed(motorSpeed);
  left.setSpeed(motorSpeed);
  right.setSpeed(motorSpeed);
}

// Stop the bot
void stopBot() {
  lift.run(RELEASE);      // stopped
  left.run(RELEASE);      // stopped
  right.run(RELEASE);      // stopped
  digitalWrite(ledPin, LOW);  // Turn the LED off
  if (DEBUGGING) { Serial.println("Stopping both wheels"); }
}

// Replies out over serial and handles pausing and flushing the data to deal with Android serial comms
void speak(char* tmpmsg) {
  Serial.print("speak:");
  Serial.println(tmpmsg); // Send the message back out the serial line
  //Wait for the serial debugger to shut up
  delay(200); //this is a magic number
  Serial.flush(); //clears all incoming data
}

// Reads serial input if available and parses command when full command has been sent. 
void readSerialInput() {
  serialAvail = Serial.available();
  //Read what is available
  for (int i = 0; i < serialAvail; i++) {
    //Store into buffer.
    inBytes[i + serialIndex] = Serial.read();
    //Check for command end. 
    
    if (inBytes[i + serialIndex] == '\n' || inBytes[i + serialIndex] == ';' || inBytes[i + serialIndex] == '>') { //Use ; when using Serial Monitor
       inBytes[i + serialIndex] = '\0'; //end of string char
       parseCommand(inBytes); 
       serialIndex = 0;
    }
    else {
      //expecting more of the command to come later.
      serialIndex += serialAvail;
    }
  }  
}

// Cleans and parses the command
void parseCommand(char* com) {
  if (com[0] == '\0') { return; } //bit of error checking
  int start = 0;
  //get start of command
  while (com[start] != '<'){
    start++; 
    if (com[start] == '\0') {
      //its not there. Must be old version
      start = -1;
      break;
    }
  }
  start++;
  //Shift to beginning
  int i = 0;
  while (com[i + start - 1] != '\0') {
    com[i] = com[start + i];
    i++; 
  } 
  performCommand(com);
}

void performCommand(char* com) {  
  if (strcmp(com, "f") == 0) { // Forward
    left.run(FORWARD);
    right.run(FORWARD);
  } else if (strcmp(com, "r") == 0) { // Right
    left.run(FORWARD);
  } else if (strcmp(com, "l") == 0) { // Left
    right.run(FORWARD);
  } else if (strcmp(com, "b") == 0) { // Backward
    left.run(BACKWARD);
    right.run(BACKWARD);
  } else if (strcmp(com, "s") == 0 || strcmp(com, "hs") == 0) { // Stop
    stopBot();
  } else if (strcmp(com, "hu") == 0) { // Lift up
    lift.run(FORWARD);
  } else if (strcmp(com, "hd") == 0) { // Lift down
    lift.run(BACKWARD);
  } else if (strcmp(com, "fr") == 0 || strcmp(com, "fz") == 0 || strcmp(com, "x") == 0) { // Read and print forward facing distance sensor
    //dist = getDistanceSensor(rangePinForward);
    //itoa(dist, msg, 10); // Turn the dist int into a char
    //serialReply("x", msg); // Send the distance out the serial line
  } else if (strcmp(com, "z") == 0) { // Read and print ground facing distance sensor
    //dist = getDistanceSensor(rangePinForwardGround);
    //itoa(dist, msg, 10); // Turn the dist int into a char
    //serialReply("z", msg); // Send the distance out the serial line
  } else if (strcmp(com, "h") == 0) { // Help mode - debugging toggle
    // Print out some basic instructions
    Serial.println("Ready to listen to commands! Try ome of these:");
    Serial.println("F (forward), B (backward), L (left), R (right), S (stop), D (demo).");
    Serial.println("Also use numbers 1-9 to adjust motorSpeed (0=slow, 9=fast).");
  } else if (strncmp(com, "w ", 2) == 0 ) {
    //I know the preceeding condition is dodgy but it will change soon 
    if (DEBUGGING) { Serial.print("Changing motorSpeed to "); }
    int i = com[2];
    motorSpeed = ((i - 48) * 10) + 120; // Set the motorSpeed multiplier to a range 1-10 from ASCII inputs 0-9
    lift.setSpeed(motorSpeed);
    left.setSpeed(motorSpeed);
    right.setSpeed(motorSpeed);
    //EEPROM.write(EEPROM_motorSpeedMultiplier, motorSpeedMultiplier); 
    if (DEBUGGING) { Serial.println(motorSpeed); }
    // Blink the LED to confirm the new motorSpeed setting
    //for(int motorSpeedBlink = 1 ; motorSpeedBlink <= motorSpeedMultiplier; motorSpeedBlink ++) { 
      digitalWrite(ledPin, HIGH);   // set the LED on           
      delay(100);
      digitalWrite(ledPin, LOW);   // set the LED off
      delay(100);
    //}  
  } else { 
    speak("Forklift doesn't understand!");  // Echo unknown command back
    if (DEBUGGING) {
      Serial.print("Unknown command: ");
      Serial.println(com);
    }
  }
}

// Main loop running at all times
void loop() 
{
  readSerialInput();
}

