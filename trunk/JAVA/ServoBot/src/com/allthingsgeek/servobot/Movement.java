package com.allthingsgeek.servobot;


import android.view.KeyEvent;

public class Movement {
	private PulseGenerator noise;
	private static Movement instance;
	private int speed = 10;

	private Movement() {
		noise = PulseGenerator.getInstance();
	}

	public static Movement getInstance() {
		if (instance == null) {
			instance = new Movement();
		}

		return instance;

	}

	public void driveFoward() {
		driveFoward(50);
	}

	public void driveBackward() {
		driveBackward(50);
	}

	public void driveFoward(int ms) {
		noise.setServo(0, speed, ms);
		noise.setServo(2, -speed, ms);
	}

	public void driveBackward(int ms) {
		noise.setServo(0, -speed, ms);
		noise.setServo(2, speed, ms);
	}

	public void stop() {
		noise.setServo(1, 50, 1);
		noise.setServo(3, 50, 1);
	}

	public void turnLeft() {
		noise.setServo(0, speed, 25);
		noise.setServo(2, speed, 25);
	}

	public void turnRight() {
		noise.setServo(0, -speed, 25);
		noise.setServo(2, -speed, 25);
	}
	
	public void setSpeed(int s) {
		speed = s;
	}

	public void processTextCommand(String string) {
		if (string.startsWith("w")) {
			driveFoward();
		}
		if (string.startsWith("s")) {
			driveBackward();
		}
		if (string.startsWith("a")) {
			turnLeft();
		}
		if (string.startsWith("d")) {
			turnRight();
		}
		if (string.startsWith("-")) {
			speed--;
		}
		if (string.startsWith("+")) {
			speed++;
		}
		if (string.startsWith(" ")) {
			stop();
		}
	}

	public boolean processKeyEvent(int keyCode) {
		switch (keyCode) {
		case KeyEvent.KEYCODE_DPAD_UP:
			driveFoward();
			return true;
		case KeyEvent.KEYCODE_DPAD_DOWN:
			driveBackward();
			return true;
		case KeyEvent.KEYCODE_DPAD_LEFT:
			turnLeft();
			return true;
		case KeyEvent.KEYCODE_DPAD_RIGHT:
			turnRight();
			return true;
		case KeyEvent.KEYCODE_P:
			if (speed < 100)
				speed++;
			return true;
		case KeyEvent.KEYCODE_M:
			if (speed > 0)
				speed--;
			return true;
		case KeyEvent.KEYCODE_DPAD_CENTER:
			stop();
			return true;
		}
		return false;
	}
}
