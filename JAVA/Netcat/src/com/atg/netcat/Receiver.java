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

public class Receiver extends Activity
{
  private TextView          tv;

  public static Integer     controlPort   = 5555;

  public static Integer     videoPort     = 4444;

  public static InetAddress clientAddress;

  private int               sleepTime     = 200;

  private IPCommThread      ipComThread   = null;

  private EditText          edittext;

  private ToggleButton      qualityButton;

  protected String          tostText      = "";

  protected String          logText       = "";

  public static Boolean     highQuality   = false;

  boolean                   stopListening = false;

  RobotState                state;

  private static Context    CONTEXT;

  // private Handler handler;
  private BTCommThread      bTcomThread;

  private ProgressDialog    btDialog;

  private ProgressDialog    ipDialog;

  /** Called when the activity is first created. */
  @Override
  public void onCreate(Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);

    CONTEXT = Receiver.this;

    setContentView(R.layout.receiver);
    tv = (TextView) findViewById(R.id.status);

    state = new RobotState(handler);

    tv.setText("Current IP:" + state.getLocalIpAddress());

    edittext = (EditText) findViewById(R.id.ipaddress);

    // listenbutton = (ToggleButton) findViewById(R.id.listen);
    // broadcastbutton = (ToggleButton) findViewById(R.id.broadcast);
    qualityButton = (ToggleButton) findViewById(R.id.videoQuality);

  }
  
  private Handler handler = new Handler()
  {

    @Override
    public void handleMessage(Message msg)
    {
      state.flush(ipComThread, bTcomThread);
    }

  };

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
    // stopListening();

  }

  private void startListening()
  {

    String msg = "Listening on port " + controlPort + " for control server";

    ipDialog = ProgressDialog.show(this, "Connecting", msg);

    ipComThread = new IPCommThread(controlPort, ipDialog, state);
    ipComThread.start();

    btDialog = ProgressDialog.show(this, "Connecting", "Searching for a Bluetooth serial port...");
    bTcomThread = new BTCommThread(BluetoothAdapter.getDefaultAdapter(), btDialog, state);
    bTcomThread.start();

    if (OrientationManager.isSupported())
    {
      OrientationManager.startListening(state);
    }

  }

  private void stopListening()
  {

    if (OrientationManager.isListening())
    {
      OrientationManager.stopListening();
    }

    if (ipDialog != null && ipDialog.isShowing())
      ipDialog.dismiss();

    if (ipComThread != null)
      ipComThread.cancel();
    ipComThread = null;

    if (btDialog != null && btDialog.isShowing())
      btDialog.dismiss();

    if (bTcomThread != null)
      bTcomThread.cancel();
    bTcomThread = null;
  }



  public static Context getContext()
  {
    return CONTEXT;
  }

  public void qualityButtonHandler(View v)
  {
    // highQuality = qualityButton.isChecked();
  }

  public void listenButtonHandler(View v)
  {
    // Perform action on clicks
    /*
     * if (listenbutton.isChecked()) { startListening(); } else {
     * stopListening(); }
     */

  }

  public void startBroadcasting(View v)
  {

    /*
     * 
     * try { // Intent intent = new Intent(CONTEXT, VideoCamera.class); //
     * startActivity(intent); } catch (ActivityNotFoundException e) { }
     */
  }

}