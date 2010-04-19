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
      ratioAz = (((float)x - targetSettings.rightCrossHairX) / Receiver.PREVIEW_WIDTH);
      ratioElv = -1*(((float)y - targetSettings.rightCrossHairY) / Receiver.PREVIEW_HEIGHT);
      
      
    }
    
    
    /*
     * I/FRAMEBUFFET( 1110): Found Target       Cb=254 Cr=112   x=23 y=19 score=408
D/TARGET BLOB( 1110): found blob with error : 408 Y:0 U:254 V:112

 X:550 Y:270 W:300 H:180
D/Camera-JNI( 1110): dataCallback(16, 0x3ed628)
I/SENDING AIMPOINT( 1110): AZ += 0.3675ELV += 0.029166667A 22 1
D/BtCommThread( 1110): Writing bytes :3

     */
    
    
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