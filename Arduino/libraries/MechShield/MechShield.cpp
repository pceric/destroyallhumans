/*
 MechShield.cpp - Driver for I2C MechShield for Arduino
 Copyright (c) 2010-2011 Eric Hokanson

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 */

#include <WProgram.h>
#include <Wire.h>
#include "MechShield.h"

static const uint8_t PORT_MAP[] = { 0x06, 0x0A, 0x0E, 0x12, 0x16, 0x1A, 0x1E, 0x22, 0x26, 0x2A, 0x2E, 0x32, 0x36, 0x3A, 0x3E, 0x42 };

static TwoWire i2c;

void Mech::begin()
{
	i2c.begin();
	// Set PRE_SCALE to 244Hz
	i2c.beginTransmission(SHIELD_I2C_ADDRESS);
	i2c.send(0xFE);
	i2c.send(0x18);
	i2c.endTransmission();
	// Set mode 1 to all zeros (enables clock)
	i2c.beginTransmission(SHIELD_I2C_ADDRESS);
	i2c.send(0x0);
	i2c.send(0x0);
	i2c.endTransmission();
	// Set all pins to default
	for (int i=1; i <= MAX_SERVOS; i++) {
	    _servos[i-1].min = MIN_PULSE_WIDTH;
		_servos[i-1].max = MAX_PULSE_WIDTH;
		this->setPosition(i, DEFAULT_PULSE_WIDTH);
	}
}

uint8_t Mech::setPosition(int pin, int position)
{
  unsigned int off;
  uint8_t status;
  
  --pin;
  
  if (pin < MAX_SERVOS) {
	if (position < 200) {  // map values < 200 as angle in degrees
	  position = constrain(position, 0, 180);
	  position = map(position, 0, 180, _servos[pin].min, _servos[pin].max);
	}
	
	position = constrain(position, _servos[pin].min, _servos[pin].max);  // ensure pulse width is valid
	_servos[pin].ticks = position;

    off = position + pin;  // length in us + offset

	// Set on register
	i2c.beginTransmission(SHIELD_I2C_ADDRESS);
	i2c.send(PORT_MAP[pin]);
	i2c.send((byte)pin);  // offset of channel
	if ((status = i2c.endTransmission()))
		return status;
	// Set off register (low)
	i2c.beginTransmission(SHIELD_I2C_ADDRESS);
	i2c.send(PORT_MAP[pin] + 2);
	i2c.send((byte)off);
	if ((status = i2c.endTransmission()))
		return status;
	// Set off register (high)
	i2c.beginTransmission(SHIELD_I2C_ADDRESS);
	i2c.send(PORT_MAP[pin] + 3);
	i2c.send((byte)(off >> 8));
	if ((status = i2c.endTransmission()))
		return status;
		
    return 0;
  }
	
  return INVALID_SERVO;
}

void Mech::setBounds(int pin, int min, int max)
{
  --pin;
  if(pin < MAX_SERVOS) {
    _servos[pin].min = abs(min);
    _servos[pin].max = abs(max);
  }
}

void Mech::stop()
{
  // Set full off register
  i2c.beginTransmission(SHIELD_I2C_ADDRESS);
  i2c.send(PORT_MAP[0] + 3);
  i2c.send(0x10);
  i2c.endTransmission();
}

int Mech::getPosition(int pin)
{
  return map(this->getPositionMicro(pin), _servos[pin-1].min, _servos[pin-1].max, 0, 180);
}

int Mech::getPositionMicro(int pin)
{
  --pin;
  if (pin < MAX_SERVOS)
    return _servos[pin].ticks;
  else
    return 0;
}

bool Mech::isRunning(int pin)
{
  // Check full off register
  i2c.beginTransmission(SHIELD_I2C_ADDRESS);
  i2c.send(PORT_MAP[pin-1] + 3);
  i2c.endTransmission();
  i2c.requestFrom(SHIELD_I2C_ADDRESS, 1);
  return (0x10 & i2c.receive());
}

uint8_t Mech::analogWrite(int pin, int value)
{
	if (pin > 16)
		return INVALID_SERVO;
	
	--pin;
	
	value = constrain(value, 0, 4095);
	
	// Set on register
	i2c.beginTransmission(SHIELD_I2C_ADDRESS);
	i2c.send(PORT_MAP[pin]);
	i2c.send(0);
	i2c.endTransmission();
	// Set off register (low)
	i2c.beginTransmission(SHIELD_I2C_ADDRESS);
	i2c.send(PORT_MAP[pin] + 2);
	i2c.send((byte)value);
	i2c.endTransmission();
	// Set off register (high)
	i2c.beginTransmission(SHIELD_I2C_ADDRESS);
	i2c.send(PORT_MAP[pin] + 3);
	i2c.send((byte)(value >> 8));
	i2c.endTransmission();
	
	return 0;
}
