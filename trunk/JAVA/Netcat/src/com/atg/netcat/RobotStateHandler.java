package com.atg.netcat;

import java.io.IOException;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;

import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryonet.Connection;
import com.esotericsoftware.kryonet.Listener;
import com.esotericsoftware.kryonet.Server;

import android.app.ProgressDialog;
import android.bluetooth.BluetoothAdapter;
import android.os.Handler;
import android.os.Message;
import android.util.Log;

/*
 * This is a class to store the state of the robot.
 */
public class RobotStateHandler extends Thread implements OrientationListener
{
  private Server                   server;

  private StringBuffer             btInBuffer;

  private StringBuffer             btOutBuffer;

  private BTCommThread             bTcomThread;

  private ProgressDialog           btDialog;

  private ProgressDialog           ipDialog;

  private Handler                  uiHandler;

  private ControllerState          controllerState  = null;

  private Connection               clientConnection = null;

  RobotState                       state;

  private static RobotStateHandler instance         = null;

  public boolean                   listening        = false;

  int                              listenPort       = 5555;

  public static RobotStateHandler getInstance(Handler h) throws IOException
  {
    if (instance == null)
    {
      instance = new RobotStateHandler(h);
    }

    return instance;

  }

  private RobotStateHandler(Handler h) throws IOException
  {

    btInBuffer = new StringBuffer();

    btOutBuffer = new StringBuffer();

    uiHandler = h;

    state = new RobotState();

    state.localIpAddress = getLocalIpAddress();

    server = new Server();

    server.start();

    setName("Robot State Handler");

    server.bind(listenPort);

    Kryo kryo = server.getKryo();
    kryo.register(ControllerState.class);
    kryo.register(RobotState.class);

    server.addListener(new Listener()
    {
      public void received(Connection connection, Object object)
      {
        if (object instanceof ControllerState)
        {
          controllerState = (ControllerState) object;
          clientConnection = connection;
        }
      }

    });

  }

  public void onBtDataRecive(String data)
  {
    btInBuffer.append(data);
    state.blueToothConnected = true;
    handler.sendEmptyMessage(0);

  }

  private Handler handler = new Handler()
                          {

                            @Override
                            public void handleMessage(Message msg)
                            {
                              // state.flush(ipComThread, bTcomThread);
                            }

                          };

  /*
   * sb.append(new String(buffer, 0, bytes)); while ((idx =
   * sb.indexOf("\r\n\r\n")) > -1) { message = sb.substring(0, idx);
   * sb.replace(0, idx+4, ""); hm = new HashMap<String, String>(); for (String
   * line : message.split("\n")) { chunks = line.trim().split("=", 2); if
   * (chunks.length != 2) continue; hm.put(chunks[0], chunks[1]); }
   * handler.obtainMessage(0x2a, hm).sendToTarget();
   */

  public String readBtInBuffer()
  {
    String data = new String(btInBuffer);
    btInBuffer.delete(0, btInBuffer.length());
    return data;
  }

  public void flush(IPCommThread ip, BTCommThread bt)
  {

  }

  public void onOrientationChanged(float azimuth, float pitch, float roll)
  {
    state.azimuth = azimuth;
    state.pitch = pitch;
    state.roll = roll;

    // ipOutBuffer.append(msg);

  }

  public void onBottomUp()
  {
    // Toast.makeText(this, "Bottom UP", 1000).show();
  }

  public void onLeftUp()
  {
    // Toast.makeText(this, "Left UP", 1000).show();
  }

  public void onRightUp()
  {
    // / Toast.makeText(this, "Right UP", 1000).show();
  }

  public void onTopUp()
  {
    // / Toast.makeText(this, "Top UP", 1000).show();
  }

  public Handler getHandler()
  {
    return handler;
  }

  public String getLocalIpAddress()
  {
    try
    {
      for (Enumeration<NetworkInterface> en = NetworkInterface.getNetworkInterfaces(); en.hasMoreElements();)
      {
        NetworkInterface intf = en.nextElement();
        for (Enumeration<InetAddress> enumIpAddr = intf.getInetAddresses(); enumIpAddr.hasMoreElements();)
        {
          InetAddress inetAddress = enumIpAddr.nextElement();
          if (!inetAddress.isLoopbackAddress())
          {
            return inetAddress.getHostAddress().toString();
          }
        }
      }
    }
    catch (SocketException ex)
    {
      // Log.e(LOG_TAG, ex.toString());
    }
    return null;
  }

  public synchronized void  startListening(ProgressDialog ipDialog, ProgressDialog btDialog)
  {
    Log.d("RobotStateHandler","startListening");
    
    if(! listening)
    {
      
      bTcomThread = new BTCommThread(BluetoothAdapter.getDefaultAdapter(), btDialog, this);
      bTcomThread.start();
  
      if (OrientationManager.isSupported())
      {
        OrientationManager.startListening(this);
      }
  
      listening = true;
      try {
      super.start();
      }
      catch (java.lang.IllegalThreadStateException e) {
        // TODO: handle exception
      }
    
    }
    // server.run();

    // if (ipDialog != null && ipDialog.isShowing())
    // ipDialog.dismiss();

  }

  public synchronized void stopListening()
  {

    listening = false;

    // super.stop();

    if (OrientationManager.isListening())
    {
      OrientationManager.stopListening();
    }

    if (ipDialog != null && ipDialog.isShowing())
      ipDialog.dismiss();

    if (btDialog != null && btDialog.isShowing())
      btDialog.dismiss();

    if (bTcomThread != null)
      bTcomThread.cancel();
    bTcomThread = null;
  }

  public void run()
  {
    while (listening)
    {
      try
      {
        try
        {
          server.update(10);
          if (clientConnection != null)
          {

            state.ipConnected = true;

            if (ipDialog != null && ipDialog.isShowing())
            {
              ipDialog.dismiss();
              ipDialog = null;
            }

            if (bTcomThread != null && controllerState != null)
            {
              // btOutBuffer.append(controllerState.toString());
              // bTcomThread.write(btOutBuffer.toString().getBytes());
              // btOutBuffer.delete(0, btInBuffer.length());
            }

            clientConnection.sendTCP(state);

          }

        }
        catch (IOException e)
        {
          break;
        }
        Thread.sleep(50);
      }

      catch (InterruptedException e)
      {
        // TODO Auto-generated catch block
        // listening = false;
      }
    }
  }

}
