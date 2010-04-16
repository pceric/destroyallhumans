package com.atg.netcat;
import android.util.Log;

/*
 * This is a Singlton class to store the state of the robot. 
 * 
 */
public class TargetBlob
{
    
    public long timestamp;  
  
    public int luma = 0;
    
    public int chromaRed = 0;

    public int chromaBlue = 0;
     
    public int x = 0;
    
    public int y = 0;
    
    //public int z = 0;
    
    public int width = 0;
    
    public int height = 0;
    
    private int degAz = 0;
    
    private int degElv = 0;
    
    
    public String toString()
    {
      return "Y:" + luma + " U:" + chromaBlue + " V:" + chromaRed + " X:" + x + " Y:" + y + " W:" + width + " H:" + height;   
    }
    
    
    public void calculateAimpoints(TargetSettings targetSettings)
    {
      degAz = (Receiver.FIELD_OF_VIEW / 2) * ((x - targetSettings.rightCrossHairX) / Receiver.PREVIEW_WIDTH);
      degElv = (Receiver.FIELD_OF_VIEW / 4) * ((y - targetSettings.rightCrossHairY) / Receiver.PREVIEW_HEIGHT);
      Log.i("TARGET BLOB" ,"AZ += "+ degAz + "ELV += " + degElv);
    }
    
    
    public byte[] toBytes() {
      // AutoAim messages start with a 'A'
      byte[] data = new byte[3];
      data[0] = 'A';
      data[1] = (byte) degAz;
      data[2] = (byte) degElv;
 
      return data;
    } 
    
}