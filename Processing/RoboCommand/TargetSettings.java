/*
 * This is a Singlton class to store the state of the robot. 
 * 
 */
public class TargetSettings
{
    
    public long timestamp;  
  
    public int targetLuma = 0;
    
    public int targetChromaBlue = 250;
    
    public int targetChromaRed = 140;
     
    //public int redBalance = -128;
     
    ///public int blueBalance = -128;
    
    public int tolerance = 24;
    
    public int leftCrossHairX = 371;
    
    public int leftCrossHairY = 161;   
    
    public int rightCrossHairX = 440;
    
    public int rightCrossHairY = 131;
    
}
