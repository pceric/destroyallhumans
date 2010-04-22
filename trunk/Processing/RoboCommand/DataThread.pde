import java.util.Date;

public class DataThread extends Thread {
  private com.esotericsoftware.kryonet.Client _client;
  private DAController _controller;
  private RobotState _rs = null;
  private TargetBlob _targetBlob = null;
  
  public DataThread(com.esotericsoftware.kryonet.Client c, DAController d) {
    _client = c;
    _controller = d;
    _client.addListener(new Listener() {
      public void received (Connection connection, Object object) {
        if (object instanceof RobotState) {
          _rs = (RobotState)object;
          //println(get_turretX() + " " + get_turretY());
          if(_rs.message.length() > 0)
          {
            println(_rs.message);
          }
        }
        if (object instanceof TargetBlob) {
            _targetBlob = (TargetBlob) object;          
            //println("got target blob" + _targetBlob);
         }
      }
    });
  }
  
  public void run() {
    while (_client != null) {
      //print(_controller.getState());
      try {
        ControllerState cs = _controller.getState();
        Date sent = new Date();
        cs.timestamp= sent.getTime();
        _client.sendTCP(cs);
        _client.update(0);
        cs.extraData="";
        Thread.sleep(100);
      }
      catch(IOException ex) {
        println(ex);
        return;
      }
      catch(InterruptedException ex2) {
        println(ex2);
        return;
      }
    }
  }
  
  public float get_azimuth() {
    if (_rs != null)
      return _rs.azimuth;
    else
      return 0.0;
  }
    
  public float get_pitch() {
    if (_rs != null)
      return _rs.pitch;
    else
      return 0.0;
  }
   
  public float get_roll() {
    if (_rs != null)
      return _rs.roll;
    else
      return 0.0;
  }
  
  public int get_battery() {
    if (_rs != null)
      return _rs.phoneBatteryLevel;
    else
      return 0;
  }

  public int get_batteryTemp() {
    if (_rs != null)
      return _rs.phoneBatteryTemp;
    else
      return 0;
  }

  public float get_camFrameRate() {
    if (_rs != null)
      return _rs.camFrameRate;
    else
      return 0.0;
  }
  
  public int get_wifiStrength() {
    if (_rs != null)
      return _rs.wifiStrength;
    else
      return 0;
  }

  public float get_lightLevel() {
    if (_rs != null)
      return _rs.lightLevel;
    else
      return 0.0;
  }

  public int get_robotBattery() {
    if (_rs != null)
      return _rs.botBatteryLevel;
    else
      return 0;
  }

  public int get_irDistance() {
    if (_rs != null)
      return _rs.irDistance;
    else
      return 0;
  }

  public int get_sonarDistance() {
    if (_rs != null)
      return _rs.sonarDistance;
    else
      return 0;
  }

  public int get_damage() {
    if (_rs != null)
      return _rs.damage;
    else
      return 0;
  }
  
  public int get_turretX() {
    if (_rs != null)
      return _rs.turretAzimuth;
    else
      return 1500;
  }

  public int get_turretY() {
    if (_rs != null)
      return _rs.turretElevation;
    else
      return 0;
  }

  public int get_speed() {
    if (_rs != null)
      return _rs.servoSpeed;
    else
      return 0;
  }
  
  public int get_strideOffset() {
    if (_rs != null)
      return _rs.strideOffset;
    else
      return 0;
  }

  public TargetBlob getTargetBlob()
  {
    TargetBlob tb = _targetBlob;
    _targetBlob = null;
    return tb;
  }
  
  public boolean isLampOn() {
    if (_rs != null)
      return _rs.lampOn;
    else
      return false;
  }    

  public boolean isLaserOn() {
    if (_rs != null)
      return _rs.laserOn;
    else
      return false;
  }    

  public String get_message() {
    if (_rs != null)
      return _rs.message;
    else
      return "";
  }
  
  public boolean isAutoAim() {
    if (_rs != null)
      return _rs.autoAimOn;
    else
      return false;
  }    
}

