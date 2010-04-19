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
    
    public int leftCrossHairX = 400;
    
    public int leftCrossHairY = 260;   
    
    public int rightCrossHairX = 400;
    
    public int rightCrossHairY = 240;
        
}