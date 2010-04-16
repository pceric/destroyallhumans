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
     
    //public int redBalance = -128;
     
    ///public int blueBalance = -128;
    
    public int tolerance = 24;
    
    public int leftCrossHairX = 256;
    
    public int leftCrossHairY = 256;   
    
    public int rightCrossHairX = 256;
    
    public int rightCrossHairY = 256;
    
}