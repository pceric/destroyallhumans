package com.atg.netcat;

import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.SocketException;
import java.util.Enumeration;

import com.atg.netcat.R;
import com.atg.netcat.R.id;
import com.atg.netcat.R.layout;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.serialport.SerialPort;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;

public class Receiver extends Activity implements Runnable
{
  private TextView          tv;

  private SerialPort        sp            = null;

  private Integer           listenPort    = 5555;

  public static Integer     videoPort     = 4444;

  public static InetAddress clientAddress;

  private int               sleepTime     = 200;

  // private SendThread mSendThread;

  // private ReadThread mReadThread;

  Thread                    thread        = null;

  private EditText          edittext;

  private ToggleButton      listenbutton;

  private ToggleButton      broadcastbutton;
  
  private ToggleButton      qualityButton;

  protected String          tostText      = "";

  protected String          logText       = "";

  byte[]                    buffer        = new byte[256];

  ServerSocket              ss            = null;

  InputStream               is            = null;

  OutputStream              os            = null;

  Socket                    s             = null;

  public static Boolean     highQuality   = false;

  public static Context     mContext;

  public static VideoCamera listener_video;

  boolean                   stopListening = false;

  /** Called when the activity is first created. */
  @Override
  public void onCreate(Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);

    mContext = Receiver.this;

    setContentView(R.layout.receiver);
    tv = (TextView) findViewById(R.id.status);

    tv.setText("Current IP:" + getLocalIpAddress());

    edittext = (EditText) findViewById(R.id.ipaddress);

    listenbutton = (ToggleButton) findViewById(R.id.listen);
    broadcastbutton = (ToggleButton) findViewById(R.id.broadcast);
    qualityButton = (ToggleButton) findViewById(R.id.videoQuality);

    
  }

  public void qualityButtonHandler(View v)
  {
    highQuality = qualityButton.isChecked();
  }

  public void listenButtonHandler(View v)
  {
    // Perform action on clicks
    if (listenbutton.isChecked())
    {
      startListening();
    }
    else
    {
      stopListening();
    }

  }

  private void startListening()
  {

    thread = new Thread(this);
    thread.start();

  }

  public void startBroadcasting(View v)
  {

    try
    {
      Intent intent = new Intent(mContext, VideoCamera.class);
      startActivity(intent);
    }
    catch (ActivityNotFoundException e)
    {
    }

  }

  private void stopListening()
  {
    Toast.makeText(Receiver.this, "Stopping Listener", Toast.LENGTH_SHORT).show();

    stopListening = true;

    if (sp != null)
    {
      sp.close();
      sp = null;
    }

    // thread.stop();

    tv.setText("");
  }

  private SensorEventListener sensorEventListener = new SensorEventListener() {

    public void onAccuracyChanged(Sensor sensor, int accuracy) {
    }

    public void onSensorChanged(SensorEvent e) {
            switch( e.sensor.getType() ) {
            case Sensor.TYPE_ACCELEROMETER:
                    synchronized (this) {
                           // Log.i(TAG, "Accelerometer Sensor event: " + e.values.toString() );
                    }
            case Sensor.TYPE_ORIENTATION:
                    synchronized (this) {
                           // Log.i(TAG, "Orientation Sensor event: " + e.values.toString() );
                    }
            }
    }

};

  
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

  /*
   * (non-Javadoc)
   * 
   * @see android.app.Activity#onDestroy()
   */
  @Override
  protected void onDestroy()
  {
    // TODO Auto-generated method stub
    super.onDestroy();
    stopListening();
  }

  /*
   * (non-Javadoc)
   * 
   * @see android.app.Activity#onPause()
   */
  @Override
  protected void onPause()
  {
    // TODO Auto-generated method stub

    super.onPause();
    stopListening();
  }

  private Handler handler = new Handler()
                          {

                            @Override
                            public void handleMessage(Message msg)
                            {

                              if (logText.length() > 0)
                              {
                                tv.append(logText);
                                logText = "";
                              }

                              if (tostText.length() > 0)
                              {
                                Toast.makeText(Receiver.this, tostText, Toast.LENGTH_SHORT).show();
                                tostText = "";
                              }

                            }
                          };

  public void run()
  {
    int readlen = 0;

    while (!stopListening)
    {

      if (ss == null)
      {
        try
        {
          ss = new ServerSocket(listenPort);
          logText += "Listening on port " + listenPort + " for Connections from " + edittext.getText() + "\n";
        }
        catch (IOException e)
        {
          // TODO Auto-generated catch block
          e.printStackTrace();
        }
      }
      else if (s == null)
      {
        try
        {
          tostText = "Connecting";
          logText += "Connecting...\n";
          handler.sendEmptyMessage(0);
          s = ss.accept();
        }
        catch (IOException e)
        {
          // tv.appendi"Socket: " + e.getMessage());
          // e.printStackTrace();
        }

      }
      else if (is == null)
      {
        try
        {

          is = new DataInputStream(s.getInputStream());
          clientAddress = s.getInetAddress();
          tostText = "Connected";
          logText += "Connected!\n";
        }
        catch (IOException e)
        {
          // tv.appendi"Socket: " + e.getMessage());
          // e.printStackTrace();
        }

      }
      else
      {
        try
        {
          if (ss.isClosed())
          {
            is = null;
            s = null;
            tostText = "Disconnected";
            logText += "Disconnected!\n";
          }
          else
          {
            readlen = is.read(buffer, 0, 100);
            if (readlen > 0)
            {
              // spos.write(buffer);
              logText += new String(buffer, 0, readlen - 1);
              ;
            }
          }

        }
        catch (IOException e)
        {
          // tv.append(e.getMessage());
          return;
        }
      }
      try
      {
        handler.sendEmptyMessage(0);
        Thread.sleep(sleepTime);
      }
      catch (InterruptedException e)
      {

        // tv.append(e.getMessage());
        // e.printStackTrace();
      }
    }

    try
    {
      ss.close();
    }
    catch (IOException e1)
    {
    }
    s = null;
    is = null;
    os = null;
    ss = null;
    stopListening = false;
  }

}