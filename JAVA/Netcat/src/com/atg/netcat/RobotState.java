package com.atg.netcat;

import java.net.InetAddress;
import java.net.NetworkInterface;
import java.net.SocketException;
import java.util.Enumeration;

import android.os.Handler;


/*
 * This is a class to store the state of the robot. 
 * 
 */
public class RobotState implements OrientationListener
{
    public boolean blueToothConnected = false;
    
    public boolean ipConnected = false;
    
    public boolean sendingVideo = false;
    
    public float azimuth = 0,  pitch = 0, roll = 0;
    
    private StringBuffer ipOutBuffer;
    
    private StringBuffer ipInBuffer;
    
    private StringBuffer btInBuffer;
    
    private StringBuffer btOutBuffer;
    
    private Handler handler;
    
    
    
    public void onIpDataRecive(String data)
    {
      ipInBuffer.append(data);
      
      if(data.startsWith("C "))
      {
      btOutBuffer.append(data);
      }
      handler.sendEmptyMessage(0);
    }
    
    public void onBtDataRecive(String data)
    {
      btInBuffer.append(data);
      handler.sendEmptyMessage(0);
    }
    
    
    
    public RobotState(Handler handler)
    {
      ipOutBuffer = new StringBuffer();
      
      ipInBuffer = new StringBuffer();
      
      btInBuffer = new StringBuffer();
      
      btOutBuffer = new StringBuffer();
      
      this.handler = handler;
    }
    
    
    /*
     *  sb.append(new String(buffer, 0, bytes));
    while ((idx = sb.indexOf("\r\n\r\n")) > -1) {
        message = sb.substring(0, idx);
        sb.replace(0, idx+4, "");
        hm = new HashMap<String, String>();
        for (String line : message.split("\n")) {
            chunks = line.trim().split("=", 2);
            if (chunks.length != 2) continue;
            hm.put(chunks[0], chunks[1]);
        }
        handler.obtainMessage(0x2a, hm).sendToTarget();
        */

    
    
    public String readIpInBuffer()
    {
      String data = new String(ipInBuffer);
      ipInBuffer.delete(0, ipInBuffer.length());
      return data;
    }
    
    public String readBtInBuffer()
    {
      String data = new String(btInBuffer);
      btInBuffer.delete(0, btInBuffer.length());
      return data;
    }
    
    public void flush(IPCommThread ip, BTCommThread bt)
    {
      if (bt != null)
      {
        bt.write(btOutBuffer.toString().getBytes());
        btOutBuffer.delete(0, btInBuffer.length());
      }
      
      if (ip != null)
      {
        ip.write(ipOutBuffer.toString().getBytes());
        ipOutBuffer.delete(0, ipOutBuffer.length());
      }
    }
 
    

    public void onOrientationChanged(float azimuth, float pitch, float roll)
    {
      
      String msg = "Or " + String.valueOf(azimuth) + " " + String.valueOf(pitch) + " " + String.valueOf(roll) + " \n";
      
      ipOutBuffer.append(msg);

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
    
    
}
