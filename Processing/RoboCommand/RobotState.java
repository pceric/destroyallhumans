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
    
    public float processFrameRate = 0;
    
    public int wifiStrength = 0;
    
    public int wifiSpeed = 0;

    public float lightLevel = 0;
     
    //these values come from the Arduino
    
    public int botBatteryLevel = 0;
    
    public int irDistance = 0;
    
    public int sonarDistance = 0;
    
    public int damage = 0;
    
    public int turretElevation = 0;
    
    public int turretAzimuth = 0;
    
    public int servoSpeed = 0;
    
    public int strideOffset = 0;
    
    public boolean moving = false;
    
    public String message = "";
    
    public boolean autoAimOn = false;
}
