/*
 * Copyright 2010 Google Inc.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not
 * use this file except in compliance with the License. You may obtain a copy of
 * the License at
 * 
 * http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
 * License for the specific language governing permissions and limitations under
 * the License
 */

package com.allthingsgeek.servobot;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;

import android.app.ProgressDialog;

import android.os.Handler;
import android.util.Log;

class IPCommThread extends Thread {
	private static String TAG = "CommThread";

	protected String tostText = "";

	protected String logText = "";

	byte[] buffer = new byte[256];

	ServerSocket serverSocket = null;

	InputStream iStream = null;

	OutputStream oStream = null;

	Socket socket = null;

	boolean stopListening = false;

	private Integer listenPort;

	private int sleepTime = 200;

	public static InetAddress clientAddress;

	private ProgressDialog dialog;

	RobotState state;

	private Movement mover;

	public IPCommThread(Integer port, ProgressDialog dialog, RobotState state) {
		this.dialog = dialog;
		this.listenPort = port;
		this.state = state;
		this.mover = Movement.getInstance();
	}

	public void run() {
		int readlen = 0;

		while (!stopListening) {

			if (serverSocket == null) {
				try {
					serverSocket = new ServerSocket(listenPort);
				} catch (IOException e) {
					Log.e(TAG, e.getMessage(), e);
				}
			} else if (socket == null) {
				try {
					socket = serverSocket.accept();
				} catch (IOException e) {
					Log.e(TAG, e.getMessage(), e);
				}
			} else if (iStream == null) {
				try {
					iStream = new DataInputStream(socket.getInputStream());
					oStream = new DataOutputStream(socket.getOutputStream());

					clientAddress = socket.getInetAddress();
					if (dialog != null && dialog.isShowing())
						dialog.dismiss();
				} catch (IOException e) {
					Log.e(TAG, e.getMessage(), e);
				}
			} else {
				try {
					if (serverSocket.isClosed()) {
						iStream = null;
						oStream = null;
						socket = null;
						// tostText = "Disconnected";
						// logText += "Disconnected!\n";
					} else {
						readlen = iStream.read(buffer, 0, 100);
						if (readlen > 0) {
							mover.processTextCommand(new String(buffer, 0, readlen - 1));
						}
					}
				} catch (IOException e) {
					Log.e(TAG, e.getMessage(), e);
					return;
				}
			}
			try {
				Thread.sleep(sleepTime);
			} catch (InterruptedException e) {
			}
		}
	}

	/* Call this from the main Activity to send data to the remote device */
	public void write(byte[] bytes) {
		try {
			if (oStream != null) {
				oStream.write(bytes);
			}
		} catch (IOException e) {
			Log.e(TAG, "exception during write", e);
		}
	}

	public boolean isConnected() {
		return oStream != null;
	}

	/* Call this from the main Activity to shutdown the connection */
	public void cancel() {
		// Close the sockets
		try {
			serverSocket.close();
		} catch (IOException e) {
		}
		stopListening = true;
	}
}
