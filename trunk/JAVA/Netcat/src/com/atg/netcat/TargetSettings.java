package com.atg.netcat;

/*
 * This is a Singlton class to store the state of the robot. 
 * 
 */
public class TargetSettings
{
    
    public long timestamp;  
  
    public int targetLuma = 0;
    
    public int targetChromaBlue = 122;
    
    public int targetChromaRed = 24;
     
    //public int redBalance = -64;
     
    ///public int blueBalance = -64;
    
    public int tollerance = 32;
        
    
}