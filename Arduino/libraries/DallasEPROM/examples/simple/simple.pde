#include <OneWire.h>
#include <DallasEPROM.h>

OneWire onew(4);  // on pin 4
DallasEPROM de(&onew);

void setup() {
  Serial.begin(9600);
  if (de.validAddress(de.getAddress()))
    Serial.println("Address CRC is correct.");
  else
    Serial.println("Address CRC is wrong.");
}

void loop() {
  byte buffer[32];
  
  // Uncomment to write to the first page of memory
  //strcpy((char*)buffer, "allthingsgeek.com");
  //if (de.writePage(buffer, 0) != 0)
  //  Serial.println("Error writing page!");
  
  // Read the first page of memory into buffer
  if (de.readPage(buffer, 0) == 0)
    Serial.println((char*)buffer);
  else
    Serial.println("Error reading page!");
  
  delay(10000);
}
