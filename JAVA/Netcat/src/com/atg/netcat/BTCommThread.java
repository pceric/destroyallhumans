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

package com.atg.netcat;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Set;
import java.util.UUID;

import android.app.ProgressDialog;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothSocket;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

class BTCommThread extends Thread
{
  private BluetoothSocket  socket;

  private InputStream      istream;

  private OutputStream     ostream;

  private ProgressDialog   dialog;

  private BluetoothAdapter adapter;

  StringBuffer             sb;

  byte[]                   prevBuffer;              // buffer store for the stream
  byte[]                   sendBuffer;              // buffer store for the stream

  int                      bytes;               // bytes returned from read()

  RobotStateHandler        state;

  public Handler           handler;

  public StringBuffer      readBuffer;

  public static String     TAG = "BtCommThread";

  public BTCommThread(BluetoothAdapter adapter, ProgressDialog dialog, RobotStateHandler rState)
  {
    this.dialog = dialog;
    this.adapter = adapter;
    this.state = rState;
    setName("BlueTooth Com");

    sb = new StringBuffer();

    readBuffer = new StringBuffer();

  }

  private synchronized void connect()
  {
    if (adapter == null)
      return;

    Set<BluetoothDevice> devices = adapter.getBondedDevices();
    BluetoothDevice device = null;
    for (BluetoothDevice curDevice : devices)
    {
      if (curDevice.getName().matches(".*BlueRobot.*"))
      {
        device = curDevice;
        break;
      }
    }
    if (device == null)
      device = adapter.getRemoteDevice("00:06:66:03:A9:A2");

    try
    {
      socket = device.createRfcommSocketToServiceRecord(UUID.fromString("00001101-0000-1000-8000-00805F9B34FB"));
      socket.connect();
    }
    catch (IOException e)
    {
      socket = null;
    }
    if (socket == null)
      return;

    InputStream tmpIn = null;
    OutputStream tmpOut = null;

    try
    {
      tmpIn = socket.getInputStream();
      tmpOut = socket.getOutputStream();
    }
    catch (IOException e)
    {
    }

    istream = tmpIn;
    ostream = tmpOut;

    //if (dialog != null && dialog.isShowing())
     // dialog.dismiss();

  }

  public void run()
  {

    connect();

    Looper.prepare();

    handler = new Handler()
    {

      @Override
      public void handleMessage(Message msg)
      {

        Log.d(TAG, "Handeling Message" + msg.obj);
         write(((ControllerState)msg.obj).toBytes());

         read();

      }
    };

    Looper.loop();

  }
  
  private void write(byte[] msg)
  {
    if (ostream != null)
    {
      try
      { 
        sendBuffer = msg;
        
        //this is to avoid sending the same thing twice
        if(sendBuffer.equals(prevBuffer))
        {
          ostream.write(sendBuffer);
          prevBuffer = sendBuffer;
        }
      }
      catch (IOException e)
      {
        Log.e(TAG, "exception during write", e);
      }
    }
  
  }
  
  private void read()
  {
    /*
     * 
     * 
     * THIS IS CAUSING A DEADLOCK
     */
    try
    {
      int inChar;
      while (istream.available() > 0)
      {

        inChar = istream.read();

        
        if(inChar != 13 && inChar!= 10)//do not write carriage returns or newlines to the buffer
        {
          readBuffer.append((char)inChar);
        }

        if (inChar == 10)//look for newlines
        {
          String tmp = readBuffer.toString();
          readBuffer.delete(0, readBuffer.length());
          Log.i(TAG, "Data From Bot:" + tmp);
          if(!tmp.contains("L"))
          {  
            state.onBtDataRecive(tmp);
          }
        }
      }
    }

    catch (Exception e)
    {
      Log.e(TAG, "exception during read", e);
    }
  }


  public void quit()
  {
    Log.i(TAG, "quit callled");

    /*
     * if(handler != null) { handler.getLooper().quit(); }
     * 
     * 
     * 
     * try {
     * 
     * socket.close(); } catch (Exception e) { Log.e(TAG,
     * "exception closing socket", e); }
     */
  }

}
