// Maxim/Dallas 1-Wire EPROM & EEPROM library for Arduino
// Copyright (C) 2011 Eric Hokanson

// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public
// License as published by the Free Software Foundation; either
// version 2.1 of the License, or (at your option) any later version.

// This library is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
// Lesser General Public License for more details.

#include "DallasEPROM.h"

extern "C" {
#include "WConstants.h"
}

/** Supported chips. */
model_type _chip_model_list[] = {
	// EPROMs
	{ 0x09, "DS2502", 4, true },
	{ 0x0B, "DS2505", 64, true },
	// EEPROMs
	{ 0x14, "DS2430", 1, false },
	{ 0x2D, "DS2431", 4, false },
	{ 0x23,	"DS2433", 16, false },
	{ 0, 0, 0, 0 }
};

DallasEPROM::DallasEPROM(OneWire* oneWire) {
	_wire = oneWire;
	search();
	_progPin = -1;
}

DallasEPROM::DallasEPROM(OneWire* oneWire, int progPin) {
	_wire = oneWire;
	search();
	_progPin = progPin;
	pinMode(progPin, OUTPUT);
	digitalWrite(progPin, LOW);
}

// Static method
bool DallasEPROM::validAddress(uint8_t* deviceAddress) {
	return (OneWire::crc8(deviceAddress, 7) == deviceAddress[7]);
}

uint8_t* DallasEPROM::getAddress() {
	return _addr;
}

void DallasEPROM::setAddress(uint8_t* pAddress) {
	for (int i = 0; i < 8; i++)
		_addr[i] = pAddress[i];
}

bool DallasEPROM::isConnected() {
	uint8_t tmpAddress[8];
	
	_wire->reset();
	_wire->reset_search();
	while (_wire->search(tmpAddress)) {
		for (int i = 0; i < 8; i++) {
			if (_addr[i] != tmpAddress[i])
				break;
			if (i == 7)
				return true;
		}
	}
	return false;
}

int DallasEPROM::readPage(uint8_t* data, int page) {
	unsigned int address = page * 32;
	byte command[] = { READMEMORY, (byte) address, (byte)(address >> 8) };

	if (!isPageValid(page))
		return INVALID_PAGE;

	// TODO: check for page redirection

	// send the command and starting address
	_wire->reset();
	_wire->select(_addr);
	_wire->write(command[0]);
	_wire->write(command[1]);
	_wire->write(command[2]);

	// Check CRC on EPROM devices
	if (isEPROMDevice() && OneWire::crc8(command, 3) != _wire->read())
		return CRC_MISMATCH;

	// Read the entire page
	for (int i = 0; i < 32; i++) {
		data[i] = _wire->read();
	}

	_wire->reset();

	return 0;
}

int DallasEPROM::writePage(uint8_t* data, int page) {
	unsigned int address = page * 32;

	if (!isPageValid(page))
		return INVALID_PAGE;

	if (!isEPROMDevice()) {
		int status;

		// a page is 4 8-byte scratch writes
		for (int i = 0; i < 32; i += 8) {
			if ((status = scratchWrite(&data[i], 8, address + i)))
				return status;
		}
		return 0;
	}

	byte command[] = { WRITEMEMORY, (byte) address, (byte)(address >> 8),
			data[0] };

	// send the command, address, and the first byte
	_wire->reset();
	_wire->select(_addr);
	_wire->write(command[0]);
	_wire->write(command[1]);
	_wire->write(command[2]);
	_wire->write(command[3]);

	// Check CRC
	if (OneWire::crc8(command, 4) != _wire->read())
		return CRC_MISMATCH;

	// write out the rest of the page
	for (int i = 1; i < 32; i++) {
		// Write byte
		_wire->write(data[i]);
		// Check CRC
		//if (OneWire::crc8(command[2], 2) != _wire->read())
		//	return CRC_MISMATCH;
		// Issue programming pulse
		if (_progPin >= 0) {
			digitalWrite(_progPin, HIGH);
			delayMicroseconds(500);
			digitalWrite(_progPin, LOW);
		}
		// TODO: Check data
		_wire->read();
	}

	_wire->reset();

	return 0;
}

int DallasEPROM::lockPage(int page) {
	if (!isPageValid(page))
		return INVALID_PAGE;

	_wire->reset();
	_wire->select(_addr);

	if (isEPROMDevice()) {
		byte command[] = { WRITESTATUS, 0x00, 0x00, (1 << page) };

		_wire->write(command[0]);
		_wire->write(command[1]);
		_wire->write(command[2]);
		_wire->write(command[3]);

		// Check CRC
		if (OneWire::crc8(command, 4) != _wire->read())
			return CRC_MISMATCH;

		// Issue programming pulse
		if (_progPin >= 0) {
			digitalWrite(_progPin, HIGH);
			delayMicroseconds(500);
			digitalWrite(_progPin, LOW);
		}

		// TODO: Verify data
	} else {
		int start, i = 0;
		byte data[] = { 0x55 };  // write protect
		
		while (_chip_model_list[i].id) {
			if (_addr[0] == _chip_model_list[i].id)
				start = _chip_model_list[i].pages * 32 + page;
			++i;
		}
		scratchWrite(data, 1, start);
	}

	_wire->reset();

	return 0;
}

bool DallasEPROM::isPageLocked(int page) {
	byte status;

	if (!isPageValid(page))
		return INVALID_PAGE;

	_wire->reset();
	_wire->select(_addr);

	if (isEPROMDevice()) {
		byte command[] = { READSTATUS, 0x00, 0x00 };
		_wire->write(command[0]);
		_wire->write(command[1]);
		_wire->write(command[2]);

		// Check CRC on EPROM devices
		if (OneWire::crc8(command, 3) != _wire->read())
			return CRC_MISMATCH;

		status = _wire->read();

		_wire->reset();

		return 1 & (status >> page);
	} else {
		unsigned int start, i = 0;
		
		while (_chip_model_list[i].id) {
			if (_addr[0] == _chip_model_list[i].id)
				start = _chip_model_list[i].pages * 32 + page;
			++i;
		}
		
		_wire->write(READMEMORY);
		_wire->write((byte)start);
		_wire->write((byte)(start >> 8));
		
		if (_wire->read() == 0x55)
			return true;
		else
			return false;
	}
}

/*******************
 * Private methods
 *******************/

bool DallasEPROM::search() {
	int i;
	_wire->reset_search();
	while (_wire->search(_addr)) {
		i = 0;
		while (_chip_model_list[i].id) {
			if (_addr[0] == _chip_model_list[i].id)
				return true;
			++i;
		}
	}
	return false;
}

int DallasEPROM::scratchWrite(uint8_t* data, int length, unsigned int address) {
	byte auth[3];

	// send the command and address
	_wire->reset();
	_wire->select(_addr);
	_wire->write(WRITEMEMORY);
	_wire->write((byte) address);
	_wire->write((byte)(address >> 8));

	// write "length" bytes to the scratchpad
	for (int i = 0; i < length; i++)
		_wire->write(data[i]);

	// Read the auth code from the scratchpad
	// TODO: verify data
	_wire->reset();
	_wire->select(_addr);
	_wire->write(READSTATUS);
	auth[0] = _wire->read();
	auth[1] = _wire->read();
	auth[2] = _wire->read();

	// Issue copy scratchpad with auth bytes
	_wire->reset();
	_wire->select(_addr);
	_wire->write(WRITESTATUS);
	_wire->write(auth[0]);
	_wire->write(auth[1]);
	_wire->write(auth[2], 1);

	// Need 10ms prog delay
	delay(10);

	_wire->reset();

	return 0;
}

bool DallasEPROM::isPageValid(int page) {
	int i = 0;
	while (_chip_model_list[i].id) {
		if (_addr[0] == _chip_model_list[i].id && page < _chip_model_list[i].pages)
			return true;
		++i;
	}
	return false;
}

bool DallasEPROM::isEPROMDevice() {
	int i = 0;
	while (_chip_model_list[i].id) {
		if (_addr[0] == _chip_model_list[i].id && _chip_model_list[i].isEPROM == true)
			return true;
		++i;
	}
	return false;
}

/** @file */