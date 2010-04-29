package com.atg.netcat;

import java.io.IOException;
import java.net.InetAddress;
import java.net.InetSocketAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Date;
import java.util.Enumeration;

import com.esotericsoftware.kryo.Kryo;
import com.esotericsoftware.kryonet.Connection;
import com.esotericsoftware.kryonet.Listener;
import com.esotericsoftware.kryonet.Server;

import android.app.ProgressDialog;
import android.bluetooth.BluetoothAdapter;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Handler;
import android.os.Message;
import android.util.Log;

/*
 * This is a class to store the state of the robot.
 */
public class RobotStateHandler extends Thread implements OrientationListener, AccelerometerListener 
{
  private Server                   server;

  private BTCommThread             bTcomThread;

  private ProgressDialog           btDialog;

  private WifiManager              wifi;

  private Handler                  uiHandler;

  private ControllerState          controllerState  = null;

  private Connection               clientConnection = null;

  RobotState                       state;
  
  TargetBlob                       targetBlob;
  
  TargetSettings                   targetSettings;

  private static RobotStateHandler instance         = null;

  public boolean                   listening        = false;

  private long                     lastControllerTimeStamp = 0; 
  
  private long                     lastTargetBlobTimeStamp = 0; 
  
  private long                     startUpTimestamp = 0;
   
  public static String TAG = "RobotStateHandler";
  
  
  InetSocketAddress clientAddress = null;
  
  public RobotStateHandler(Handler h) throws IOException
  {


    uiHandler = h;

    state = new RobotState();

    server = new Server();

    server.start();

    targetSettings = new TargetSettings();
    
    setName("Robot State Handler");

    server.bind(Receiver.controlPort);

    Kryo kryo = server.getKryo();
    kryo.register(ControllerState.class);
    kryo.register(RobotState.class);
    kryo.register(TargetBlob.class);
    kryo.register(TargetSettings.class);
    

    server.addListener(new Listener()
    {
      public void received(Connection connection, Object object)
      {
        clientAddress = connection.getRemoteAddressTCP();
        
        if (object instanceof ControllerState)
        {
          controllerState = (ControllerState) object;
          clientConnection = connection;
          
          if(controllerState.extraData.length() > 0)
          {
            Message say = uiHandler.obtainMessage();
            say.obj = controllerState.extraData;
            say.sendToTarget();
          }
        }
        
        if( object instanceof TargetSettings)
        {
          Log.i(TAG,"got target setings");
          targetSettings = (TargetSettings) object;
        }
      }

    });
    

  }

  public static RobotStateHandler getInstance(Handler h) throws IOException
  {
    if (instance == null)
    {
      instance = new RobotStateHandler(h);
    }

    return instance;

  }
  
  
  public static String getClientIpAddress()
  {
    if (instance == null)
      return null;
    
    if(instance.clientAddress == null)
      return null;
    
    return instance.clientAddress.getAddress().getHostAddress();
  }
   
  
  public static void setFrameRate(float raw, float processed)
  {
    if (instance == null)
      return ;
     instance.state.camFrameRate = raw;
    // instance.state.processFrameRate = processed;
  }

  public static TargetSettings getTargetSettings()
  {

    if (instance == null)
      return null;
    
    return instance.targetSettings;
  }
  
  public static void onColorCalibrate(TargetBlob blob)
  {

    if (instance == null)
      return ;
    
     instance.state.message += "Avg Color:" + blob.chromaBlue +", " + blob.chromaRed;
  }
  
  
  public static void onTargetBlobFound(TargetBlob blob)
  {

    if (instance == null)
      return ;
    
     instance.targetBlob = blob;
  }
  
  public void onBtDataRecive(String data)
  {
    Log.i(TAG, "got bt data:" + data);
    
    state.blueToothConnected = true;
    Date date = new Date();
    state.lastBtTimestamp = date.getTime();
    
    if(data.startsWith("L"))
    {
      state.message += data; 
    }
    else
    {
    
    String[] botData = data.split(" ");
    
    try {
      state.botBatteryLevel = Integer.parseInt(botData[0]);
      state.damage = Integer.parseInt(botData[1]);
      state.servoSpeed = Integer.parseInt(botData[2]);
      state.strideOffset  = Integer.parseInt(botData[3]);
      state.turretAzimuth  = Integer.parseInt(botData[4]);
      state.turretElevation  = Integer.parseInt(botData[5]);
      state.sonarDistance  = Integer.parseInt(botData[6]);
      state.irDistance  = Integer.parseInt(botData[7]);
      state.lampOn  = Integer.parseInt(botData[8]) == 1;
      state.laserOn = Integer.parseInt(botData[9]) == 1;
      state.rGunOn  = Integer.parseInt(botData[10]) == 1;
      state.lGunOn  = Integer.parseInt(botData[11]) == 1;
      state.moving  = Integer.parseInt(botData[12]) == 1;
    }
    catch(Exception e)
    {
      Log.e(TAG, "Error parsing robot data: " + data + " e:",e);
    }
    }
    
  }
  
  public void onBtDataError()
  {
    if(state.blueToothConnected)
    {
      Message say = uiHandler.obtainMessage();
      say.obj = "Danger! Danger! Bluetooth error!";
      say.sendToTarget();
    }
    state.blueToothConnected = false;
  }
  
  public BroadcastReceiver mBatInfoReceiver = new BroadcastReceiver(){
    public void onReceive(Context arg0, Intent intent) {
      // TODO Auto-generated method stub
      state.phoneBatteryLevel = intent.getIntExtra("level", 0);
      state.phoneBatteryTemp = intent.getIntExtra("temperature", 0);
    }
  };
  
  
  public BroadcastReceiver mWifiInfoReceiver = new BroadcastReceiver(){

    @Override
    public void onReceive(Context context, Intent intent) {
            WifiInfo info = wifi.getConnectionInfo();            
            
            state.wifiStrength =  info.getRssi();
            
            state.wifiSpeed = info.getLinkSpeed();
            
    }
  
  };
  
  /**
   * onShake callback
   */
  public void onShake(float force) {
      //Toast.makeText(this, "Phone shaked : " + force, 1000).show();
  }

  /**
   * onAccelerationChanged callback
   */
  public void onAccelerationChanged(float x, float y, float z) {
     state.accelX = x;
     state.accelY = y;
     state.accelZ = z;
  }

  /**
   * onCompassChanged callback
   */
  public void onCompassChanged(float x, float y, float z) {
     state.magX = x;
     state.magY = y;
     state.accelZ = z;
  }
  
  
  /**
   * onLightLevelChanged callback
   */
  public void onLightLevelChanged(float level) {
     state.lightLevel = level;
  }

  public void onOrientationChanged(float azimuth, float pitch, float roll)
  {
    state.azimuth = azimuth;
    state.pitch = pitch;
    state.roll = roll;
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

  public synchronized void  startListening(ProgressDialog btDialog, WifiManager wifi)
  {
    //Log.d("RobotStateHandler","startListening");
    
    this.wifi = wifi;
    
    if(! listening)
    {
              
      this.listening = true;
         
      try {
        this.start();
        
        if (OrientationManager.isSupported())
        {
          OrientationManager.startListening(this);
        }
    
        if (LightSensorManager.isSupported())
        {
          LightSensorManager.startListening(this);
        }
    
        if (CompassManager.isSupported())
        {
          CompassManager.startListening(this);
        }
        
        server.start();      
        
        
        if(bTcomThread == null)
        {  
          bTcomThread = new BTCommThread(BluetoothAdapter.getDefaultAdapter(), this);
          bTcomThread.start();
        }
      }
      catch (java.lang.IllegalThreadStateException e) {
        Log.e(TAG, "Robot state handler thead start error",e);
      }
      
    }
   
  }

  public synchronized void stopListening()
  {

    Log.e(TAG, "Robot state handler STOPING ALL LISTINERS");
    
    /*
    if (OrientationManager.isListening())
    {
      OrientationManager.stopListening();
    }

    if (CompassManager.isListening())
    {
      CompassManager.stopListening();
    }
    
    if (LightSensorManager.isListening())
    {
      LightSensorManager.stopListening();
    }
     

    //watch out for double start

   if (bTcomThread != null)
   {
     try
     {
      bTcomThread.handler.getLooper().quit();
     }
     catch(Exception e)
     {}
     
     bTcomThread.disconnect();
   }
    this.listening = false;
    */
    
  }

  public void run()
  {
    while (this.listening)
    {

        if (clientConnection != null)
        {
          
          if (bTcomThread != null && controllerState != null && controllerState.timestamp != lastControllerTimeStamp)
          {
             if(controllerState.R3)
             {
               //toggle autoaim
               state.autoAimOn = ! state.autoAimOn;
             }
            
             lastControllerTimeStamp = controllerState.timestamp;
             Message btMsg = bTcomThread.handler.obtainMessage();
             btMsg.obj = controllerState;
             btMsg.sendToTarget();
          }
          //else
          //{
           // Message btMsg = bTcomThread.handler.obtainMessage();
            //btMsg.obj = "K";
            //btMsg.sendToTarget();
          //}
          clientConnection.sendTCP(state);
          state.message = "";
          
          if (targetBlob != null && targetBlob.timestamp != lastTargetBlobTimeStamp)
          {
             lastTargetBlobTimeStamp = controllerState.timestamp;
             
             targetBlob.calculateAimpoints(targetSettings);
             
             clientConnection.sendTCP(targetBlob);
             
             //autoaim the head if needed
             if(bTcomThread != null && state.autoAimOn)
             {
               Message btMsg = bTcomThread.handler.obtainMessage();
               btMsg.obj = targetBlob;
               btMsg.sendToTarget();   
             }
             
             targetBlob = null;
          }
        }
        
      try
      {
        //Log.d(TAG, "Sleeping");
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
