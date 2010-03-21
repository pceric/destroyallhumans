package com.atg.netcat;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;

import com.atg.netcat.R;
import com.atg.netcat.R.id;
import com.atg.netcat.R.layout;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.util.Log;
import android.view.View;
import android.view.View.OnClickListener;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;
import android.widget.ToggleButton;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothAdapter;

public class Receiver extends Activity implements OrientationListener
{
  private TextView          tv;

  public static Integer     controlPort   = 5555;

  public static Integer     videoPort     = 4444;

  public static InetAddress clientAddress;

  private int               sleepTime     = 200;

  // private SendThread mSendThread;

  // private ReadThread mReadThread;

  private IPCommThread      ipComThread   = null;

  private EditText          edittext;

  private ToggleButton      listenbutton;

  private ToggleButton      broadcastbutton;

  private ToggleButton      qualityButton;

  protected String          tostText      = "";

  protected String          logText       = "";

  public static Boolean     highQuality   = false;

  public static VideoCamera listener_video;

  boolean                   stopListening = false;

  private static Context    CONTEXT;

  // private Handler handler;
  private BTCommThread      bTcomThread;

  private ProgressDialog    dialog;

  /** Called when the activity is first created. */
  @Override
  public void onCreate(Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);

    CONTEXT = Receiver.this;

    setContentView(R.layout.receiver);
    tv = (TextView) findViewById(R.id.status);

    tv.setText("Current IP:" + getLocalIpAddress());

    edittext = (EditText) findViewById(R.id.ipaddress);

    listenbutton = (ToggleButton) findViewById(R.id.listen);
    broadcastbutton = (ToggleButton) findViewById(R.id.broadcast);
    qualityButton = (ToggleButton) findViewById(R.id.videoQuality);

  }

  @Override
  public void onStart()
  {
    super.onStart();
    startListening();
  }
  

  @Override
  public void onStop()
  {
    super.onStart();
    stopListening();
  }


  
  @Override
  protected void onPause()
  {
    // TODO Auto-generated method stub

    super.onPause();
    //stopListening();

  }


  private void startListening()
  {
    
    String msg = "Listening on port " + controlPort + " for control server";

    dialog = ProgressDialog.show(this, "Connecting", msg);

    ipComThread = new IPCommThread(controlPort, dialog, handler);
    ipComThread.start();

    // dialog = ProgressDialog.show(this, "Connecting",
    // "Searching for a Bluetooth serial port...");
    // bTcomThread = new BTCommThread(BluetoothAdapter.getDefaultAdapter(),
    // dialog, handler);
    // bTcomThread.start();

    if (OrientationManager.isSupported())
    {
      OrientationManager.startListening(this);
    }

  }

  private void stopListening()
  {
    
    if (OrientationManager.isListening())
    {
      OrientationManager.stopListening();
    }
    

    if (dialog != null && dialog.isShowing())
      dialog.dismiss();

    if (ipComThread != null)
      ipComThread.cancel();
    ipComThread = null;

    if (bTcomThread != null)
      bTcomThread.cancel();
    bTcomThread = null;
  }


  public void onOrientationChanged(float azimuth, float pitch, float roll)
  {
    
    String msg = "Or " + String.valueOf(azimuth) + " " + String.valueOf(pitch) + " " + String.valueOf(roll) + " \n";

    if (ipComThread != null  && ipComThread.isConnected())
    {
      ipComThread.write(msg.getBytes());
    }

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

                              // if (bTcomThread != null)
                              // bTcomThread.write(msg.toString());

                            }
                          };

  public static Context getContext()
  {
    return CONTEXT;
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
  
  public void onBottomUp()
  {
   // Toast.makeText(this, "Bottom UP", 1000).show();
  }

  public void onLeftUp()
  {
  //  Toast.makeText(this, "Left UP", 1000).show();
  }

  public void onRightUp()
  {
///    Toast.makeText(this, "Right UP", 1000).show();
  }

  public void onTopUp()
  {
   /// Toast.makeText(this, "Top UP", 1000).show();
  }

  
  public void qualityButtonHandler(View v)
  {
    highQuality = qualityButton.isChecked();
  }

  public void listenButtonHandler(View v)
  {
    // Perform action on clicks
    /*
    if (listenbutton.isChecked())
    {
      startListening();
    }
    else
    {
      stopListening();
    }
    */

  }

  public void startBroadcasting(View v)
  {

    /*
    
    try
    {
      // Intent intent = new Intent(CONTEXT, VideoCamera.class);
      // startActivity(intent);
    }
    catch (ActivityNotFoundException e)
    {
    }
    */
  }
  
}