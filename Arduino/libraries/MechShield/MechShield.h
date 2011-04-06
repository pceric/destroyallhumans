/*
 MechShield.h - Driver for I2C MechShield for Arduino
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

/** @mainpage Quick Start Guide
 * 
 * @section install_sec Installation
 * Extract the MechShield directory into the arduino/libraries directory.
 * 
 * @section usage_sec Usage
 * Click <a href="../../examples/HBridge/HBridge.pde">here</a> or
 * <a href="../../examples/Sweep/Sweep.pde">here</a> to see a
 * couple simple examples of how to use this library.
 * 
 * You can also find these examples by selecting File->Examples->MechShield
 * from the Arduino software menu.
 * 
 * @section hack_sec Hacks
 * The I2C chip used on the MechShield can support up to 1 MHz operation.
 * To lower latency you can modify the twi.h file found in the
 * [arduino base]/libraries/Wire/utility directory and change the line:
 * #define TWI_FREQ 100000L
 * to
 * #define TWI_FREQ 400000L
 */

#ifndef MechShield_h
#define MechShield_h

#include <inttypes.h>

#define MECHSHIELDVERSION "1.0.1"

#define MIN_PULSE_WIDTH     1000  // the shortest pulse sent to a servo
#define MAX_PULSE_WIDTH     2000  // the longest pulse sent to a servo
#define DEFAULT_PULSE_WIDTH 1500  // default pulse width when servo is attached
#define OFFSET_MULTIPLIER   2     // how much to offset the start of each servo to reduce spikes
#define MAX_SERVOS         12     // maximum supported servos
#define INVALID_SERVO      255    // flag indicating an invalid servo index
#define SHIELD_I2C_ADDRESS 65     // I2C address of chip
/**
 * @defgroup HBRIDGE_GROUP H Bridge Constants
 *
 * @{
 */
#define HOUT1 13
#define HOUT2 14
#define HOUT3 15
#define HOUT4 16
/** @} */

/**
 * Servo configuration
 * 
 * @param ticks Currently set pulse width
 * @param min Minimum allowed pulse width
 * @param max Maximum allowed pulse width
 */
typedef struct {
	unsigned int ticks;
	unsigned int min;
	unsigned int max;
} servo_t;

/**
 * A class that controls the Arduino MechShield board from All Things Geek.
 * 
 * @author Eric Hokanson
 */
class Mech {
public:
	/**
	 * Starts the I2C bus and enables the MechShield board.
	 */
	void begin();

	/**
	 * Sets the position of a servo in degrees or in microseconds.
	 * 
	 * @param pin MechShield pin number (1-12).
	 * @param position Servo position in degrees if <= 180 else in microseconds.
	 * @return Error code or 0 on success.
	 */
	uint8_t setPosition(int pin, int position);

	/**
	 * Configures the travel of a servo.
	 * 
	 * @param pin MechShield pin number (1-12).
	 * @param min Minimum pulse width in microseconds.
	 * @param max Maximum pulse width in microseconds.
	 */
	void setBounds(int pin, int min, int max);

	/**
	 * Puts the PWM chip on the MechShield into a low power sleep mode.
	 */
	void sleep();

	/**
	 * Gets currently configured position for the requested MechShield pin in degrees.
	 * Note: This does not mean the servo is currently at this position, it could still
	 * be moving from a previous call to setPosition().
	 * 
	 * @see #getPositionMicro(int pin)
	 * @param MechShield pin number (1-12).
	 * @return Currently set servo position in degrees.
	 */
	int getPosition(int pin);

	/**
	 * Gets currently configured position for the requested MechShield pin in microseconds.
	 * Note: This does not mean the servo is currently at this position, it could still
	 * be moving from a previous call to setPosition().
	 * 
	 * @see #getPosition(int pin)
	 * @param MechShield pin number (1-12).
	 * @return Currently set pulse width in microseconds.
	 */
	int getPositionMicro(int pin);

	/**
	 * Checks to see if a pin is turned on.
	 * 
	 * @param pin MechShield pin number (1-12).
	 * @return True if pin is on.
	 */
	bool isRunning(int pin);

	/**
	 * Allows PWM control of the four H bridge outputs on the MechShield.
	 * Will generate a steady square wave of the specified duty
	 * cycle at a frequency of ~244 Hz.
	 * 
	 * Note: This can be used to manually control any pin.  However,
	 * a steady singal on pin 1 is required for proper
	 * operation of the servo outputs.
	 * 
	 * @see #setPosition(int pin, int position)
	 * @param pin One of the @ref HBRIDGE_GROUP.
	 * @param value Value from 0 to 4095.
	 * @return Error code or 0 on success.
	 */
	uint8_t analogWrite(int pin, int value);
	
	/**
	 * Wakes the PWM chip after a call to #sleep().
	 */
	void wake();
private:
	servo_t _servos[MAX_SERVOS]; // array of servo structures
};
#endif

/** @file */