public class DataThread extends Thread {
  private com.esotericsoftware.kryonet.Client _client;
  private DAController _controller;
  private RobotState _rs = null;
  
  public DataThread(com.esotericsoftware.kryonet.Client c, DAController d) {
    _client = c;
    _controller = d;
    _client.addListener(new Listener() {
      public void received (Connection connection, Object object) {
        if (object instanceof RobotState) {
          _rs = (RobotState)object;
          println("Server sent me RobotState.");
        }
      }
    });
  }
  
  public void run() {
    long time = System.nanoTime() / 1000;
    while (_client != null) {
      println("C " + time + _controller);
      try {
        _client.sendTCP(_controller.getState());
        _client.update(0);
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
}

