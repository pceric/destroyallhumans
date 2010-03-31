package com.atg.netcat;


/*
 * This is a Singlton class to store the state of the robot. 
 * 
 */
public class RobotState
{
    public boolean blueToothConnected = false;
    
    public boolean ipConnected = false;
    
    public boolean sendingVideo = false;
    
    public float azimuth = 0,  pitch = 0, roll = 0;
    
    public String localIpAddress = "127.0.0.1";    
       
    public float phoneBatteryVoltage = (float) 0.0;
    
    
}
