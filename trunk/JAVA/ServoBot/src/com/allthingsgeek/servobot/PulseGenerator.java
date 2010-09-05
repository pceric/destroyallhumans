package com.allthingsgeek.servobot;

/*
 * Robot control console. Copyright (C) 2010 Darrell Taylor & Eric Hokanson
 * 
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import java.util.Arrays;

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.util.Log;

// TODO: Auto-generated Javadoc
/**
 * The Class PulseGenerator.
 */
public class PulseGenerator implements Runnable {

	private static PulseGenerator instance;

	//
	/** The sample rate. 44100hz is native on g1 */
	private int sampleRate;

	/** The MI n_ puls e_ width. */
	public int MIN_PULSE_WIDTH;

	/** The MA x_ puls e_ width. */
	public int MAX_PULSE_WIDTH;

	/** The pulse widths, determines speed or position of each servo */
	private int pulseWidthArray[];

	/** Number of pulses left to send for each servo */
	private int pulseCountArray[];

	/** dead zone(center) offset in percent */
	private int servoOffsetArray[];

	/** The pulse interval. Should be 20ms */
	private int pulseInterval;

	/** The buffer pulses. */
	private int bufferPulses = 2;

	/** The max volume */
	private int volume = Short.MAX_VALUE;

	/** Are we playing sound right now? */
	private boolean playing = true;

	/** Are we paused right now? */
	private boolean paused = true;

	/** Do we need to update the buffer? */
	private boolean bufferChanged = false;

	/** The noise audio track. */
	private AudioTrack noiseAudioTrack;

	/** The bufferlength. */
	private int systembufferlength; // 4800

	/** The left channel buffer. */
	private short[] leftChannelBuffer;

	/** The right channel buffer. */
	private short[] rightChannelBuffer;

	private static String TAG = "Servo Pulse Generator";

	private static int NUM_SERVOS = 4;

	/**
	 * Instantiates a new pulse generator.
	 */
	private PulseGenerator() {
		sampleRate = AudioTrack
				.getNativeOutputSampleRate(AudioManager.STREAM_MUSIC);

		MIN_PULSE_WIDTH = sampleRate / 1200;

		MAX_PULSE_WIDTH = sampleRate / 456;

		pulseCountArray = new int[NUM_SERVOS];

		Arrays.fill(pulseCountArray, 0);

		servoOffsetArray = new int[NUM_SERVOS];

		Arrays.fill(servoOffsetArray, (MIN_PULSE_WIDTH + MAX_PULSE_WIDTH) / 2);

		pulseWidthArray = new int[NUM_SERVOS];

		Arrays.fill(pulseWidthArray, (MIN_PULSE_WIDTH + MAX_PULSE_WIDTH) / 2);

		pulseInterval = sampleRate / 50;

		systembufferlength = AudioTrack.getMinBufferSize(sampleRate,
				AudioFormat.CHANNEL_CONFIGURATION_STEREO,
				AudioFormat.ENCODING_PCM_16BIT);

		noiseAudioTrack = new AudioTrack(AudioManager.STREAM_MUSIC, sampleRate,
				AudioFormat.CHANNEL_CONFIGURATION_STEREO,
				AudioFormat.ENCODING_PCM_16BIT, systembufferlength,
				AudioTrack.MODE_STREAM);

		sampleRate = noiseAudioTrack.getSampleRate();

		Log.i(TAG, "BufferLength = " + Integer.toString(systembufferlength));
		Log.i(TAG, "Sample Rate = " + Integer.toString(sampleRate));

		leftChannelBuffer = new short[systembufferlength / 2];
		rightChannelBuffer = new short[systembufferlength / 2];

		Thread noiseThread;

		noiseThread = new Thread(this);
		noiseThread.setName("noiseThread");

		generatePCM(pulseWidthArray[0], pulseWidthArray[1], pulseInterval,
				leftChannelBuffer, pulseInterval * bufferPulses, 1);
		generatePCM(pulseWidthArray[2], pulseWidthArray[3], pulseInterval,
				rightChannelBuffer, pulseInterval * bufferPulses, 3);

		noiseThread.start();

	}

	public static PulseGenerator getInstance() {
		if (instance == null) {
			instance = new PulseGenerator();
		}

		return instance;

	}

	private void generatePCM(int pulseWidth, int negPulseWidth,
			int pulseInterval, short buffer[], int bufferLength, int lastChanged) {

		int i = 0;
		int j = 0;
		while (i < bufferLength) {
			j = 0;

			if (lastChanged % 2 == 0) {
				while (j < pulseWidth) {
					buffer[i] = (short) ((volume));
					i++;
					j++;
				}

				while (j < pulseInterval) {
					buffer[i] = (short) ((-volume));
					i++;
					j++;
				}
			} else {
				while (j < negPulseWidth) {
					buffer[i] = (short) ((-volume));
					i++;
					j++;
				}
				while (j < pulseInterval) {
					buffer[i] = (short) ((volume));
					i++;
					j++;
				}

			}
		}

		bufferChanged = true;
	}

	public void run() {

		/** The stero audio buffer. */
		short[] audioBuffer = new short[systembufferlength];

		int sterobufferlength = pulseInterval * bufferPulses * 2;
		noiseAudioTrack.play();

		while (playing) {
			if (paused) {
				for (int i = 0; i < systembufferlength; i++) {
					audioBuffer[i] = (short) (0);
				}
				noiseAudioTrack.write(audioBuffer, 0, systembufferlength);
				bufferChanged = true;
				continue;
			}
			/*
			for (int i = 0; i < NUM_SERVOS; i += 1) {
				if (pulseCountArray[i] <= bufferPulses
						&& pulseCountArray[i] > 0) {
					pulseWidthArray[i] = servoOffsetArray[i];
					if (i < 2) {
						generatePCM(pulseWidthArray[0], pulseWidthArray[1],
								pulseInterval, leftChannelBuffer, pulseInterval
										* bufferPulses, i);
					} else {
						generatePCM(pulseWidthArray[2], pulseWidthArray[3],
								pulseInterval, rightChannelBuffer,
								pulseInterval * bufferPulses, i);
					}
				}
				if (pulseCountArray[i] > 0) {
					pulseCountArray[i] -= bufferPulses;
				}
			}
			*/

			if (bufferChanged) {
				for (int i = 0; i < sterobufferlength; i += 2) {
					audioBuffer[i] = leftChannelBuffer[i / 2];
					audioBuffer[i + 1] = rightChannelBuffer[i / 2];
				}
				bufferChanged = false;
			}
			noiseAudioTrack.write(audioBuffer, 0, sterobufferlength);
		}
		for (int i = 0; i < systembufferlength; i++) {
			audioBuffer[i] = (short) (0);
		}
		noiseAudioTrack.write(audioBuffer, 0, systembufferlength);
		noiseAudioTrack.stop();
		noiseAudioTrack.release();
	}

	/**
	 * Stop.
	 */
	public void stop() {
		playing = false;
	}

	/**
	 * Pause
	 */
	public synchronized void pause(boolean p) {
		paused = p;
	}
	
	public boolean isPaused() {
		return paused;
	}

	/**
	 * Sets the servo pos and runtime
	 * 
	 * @param percent
	 *            the new left pulse percent
	 */
	public void setServo(int servoNum, int percent, int counts) {

		if (servoNum < 0 || servoNum > 4) {
			Log.e(TAG, "Servo index out of bounds, should be between 0 and 3");
			return;
		}
		
		percent = percent + (servoOffsetArray[servoNum] - 50);

		if (percent < -100 || percent > 100) {
			Log.e(TAG,
					"Servo Position out of bounds, should be between 0 and 100");
			return;
		}

		this.pulseWidthArray[servoNum] = MIN_PULSE_WIDTH
				+ ((((100 + percent) / 2) * (MAX_PULSE_WIDTH - MIN_PULSE_WIDTH)) / 100);

		this.pulseCountArray[servoNum] = counts;

		if (servoNum < 2) {
			generatePCM(pulseWidthArray[0], pulseWidthArray[1], pulseInterval,
					leftChannelBuffer, pulseInterval * bufferPulses, servoNum);
		} else {
			generatePCM(pulseWidthArray[2], pulseWidthArray[3], pulseInterval,
					rightChannelBuffer, pulseInterval * bufferPulses, servoNum);
		}

	}

	/**
	 * Sets the position of a servo.
	 * 
	 * @param percent
	 *            the new left pulse percent
	 */
	public void setOffsetPulsePercent(int percent, int servoNum) {

		if (percent < 0 || percent > 100) {
			Log.e(TAG,
					"Servo Position out of bounds, should be between 0 and 100");
			return;
		}
		servoOffsetArray[servoNum] = percent;
		setServo(servoNum, 0, Integer.MAX_VALUE);
	}

	/**
	 * Gets the pulse percent.
	 * 
	 * @return the pulse percent
	 */
	public int getPulsePercent(int i) {
		return (int)(((float)(pulseWidthArray[i] - MIN_PULSE_WIDTH) / (MAX_PULSE_WIDTH - MIN_PULSE_WIDTH)) * 100);
	}

	/**
	 * Gets the pulse ms.
	 * 
	 * @return the pulse ms
	 */
	public float getPulseMs(int i) {
		return ((float) pulseWidthArray[i] / sampleRate) * 1000;
	}

	/**
	 * Gets the pulse samples.
	 * 
	 * @return the pulse samples
	 */
	public int getPulseSamples(int i) {
		return pulseWidthArray[i];
	}

}