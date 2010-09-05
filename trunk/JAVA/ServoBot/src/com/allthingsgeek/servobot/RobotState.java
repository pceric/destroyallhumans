package com.allthingsgeek.servobot;

/*
 * This is a Singlton class to store the state of the robot. 
 * 
 */
public class RobotState
{  
    public boolean blueToothConnected = false;
    
    public float azimuth = 0,  pitch = 0, roll = 0;
    
    public float magX = 0,  magY = 0, magZ = 0;
    
    public float accelX = 0, accelY = 0, accelZ = 0;  
       
    public int phoneBatteryLevel =  0;
    
    public int phoneBatteryTemp =  0;
    
    public float camFrameRate = 0;
    
    public int wifiStrength = 0;
    
    public int wifiSpeed = 0;

    public float lightLevel = 0;
     
      
    public String message = "";
    
    
    private int  servoPosistionsPercent[];
    
    private int  servoTimeToRun[];
    
    public void name()
    {
      
    }

    public String getLocalIpAddress()
    {
      // TODO Auto-generated method stub
      return "arf";
    }
    
}