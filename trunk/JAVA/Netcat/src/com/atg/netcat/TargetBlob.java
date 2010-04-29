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
    
    public float ratioAz = 0;
    
    public float ratioElv = 0;
    
    
    public String toString()
    {
      return "Y:" + luma + " U:" + chromaBlue + " V:" + chromaRed + " X:" + x + " Y:" + y + " W:" + width + " H:" + height;   
    }
    
    
    public void calculateAimpoints(TargetSettings targetSettings)
    {
      int px_off =  x - targetSettings.rightCrossHairX;
      
      ratioAz = px_off / ((float)Receiver.PREVIEW_WIDTH);
       
      px_off =  -1*(y - targetSettings.rightCrossHairY);
      
      ratioElv = px_off /((float) Receiver.PREVIEW_HEIGHT);
      
      
    }
          
    public byte[] toBytes() {
      // AutoAim messages start with a 'A'
      
      int a = (int) (ratioAz * 64 ) ;
      int e = (int) ( ratioElv * 32 );
      
     // a = (ratioAz > 0) ? 5 : -5;
     // e = (ratioElv > 0) ? 5 : -5;

      
      Log.i("SENDING AIMPOINT" ,"AZ += "+ ratioAz + "ELV += " + ratioElv + "A " + a + " "+ e);

      byte[] data = new byte[3];
      data[0] = 'A';
      data[1] = (byte) a;
      data[2] = (byte) e;
 
      return data;
    } 
    
}