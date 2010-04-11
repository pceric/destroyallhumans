class DAController
{
  private ControllDevice gamepad;
  private ControllStick leftStick;
  private ControllStick rightStick;
  private ControllCoolieHat DPad;
  private ControllSlider Z1;
  private ControllSlider Z2;
  private ControllerState cs;

  private ControllButton X;
  private ControllButton C;
  private ControllButton T; 
  private ControllButton S;
  private ControllButton L1;
  private ControllButton L2;
  private ControllButton L3;
  private ControllButton R1;
  private ControllButton R2;
  private ControllButton R3;
  private ControllButton Select;
  private ControllButton Start;
  private ControllButton Up;
  private ControllButton Down;
  private ControllButton Left;
  private ControllButton Right;

  public boolean invertLeftX;
  public boolean invertLeftY;
  public boolean invertRightX;
  public boolean invertRightY;

  DAController(ControllDevice d, Object o)
  {
    cs = new ControllerState();
    gamepad = d;
    //gamepad.printSticks();
    //gamepad.printButtons();
    //gamepad.printSliders();
    invertLeftX = invertLeftY = invertRightX = invertRightY = false;
    if ( gamepad.getName().equals("USB Force Feedback Joypad (MP-8888)") )
    {
      mapJoybox();
    }
    else if ( gamepad.getName().equals("Logitech Dual Action USB") )
    {
      mapLogitech();
    }
    else if ( gamepad.getName().equals("4 axis 16 button joystick") )
    {
      mapGeneric();
    }
    else if (match(gamepad.getName(), "XBOX 360") != null)
    {
      mapXBOX360();
    }
    else if ( gamepad.getName().equals("PLAYSTATION(R)3 Controller") )
    {
      mapPlaystation3();
    }
    else if (match(gamepad.getName(), "SideWinder Precision Pro") != null)
      mapSidewinder();
    else 
    {
      println("Unrecognized device name, using Logitech mapping.");
      mapLogitech();
    }
  }

  private void mapJoybox()
  {
    leftStick = gamepad.getStick(1);
    rightStick = gamepad.getStick(0);
    T = gamepad.getButton(0);
    C = gamepad.getButton(1);
    X = gamepad.getButton(2);
    S = gamepad.getButton(3);
    R1 = gamepad.getButton(7);
    R2 = gamepad.getButton(5);
    R3 = gamepad.getButton(11);
    L1 = gamepad.getButton(6);
    L2 = gamepad.getButton(4);
    L3 = gamepad.getButton(10);
    DPad = gamepad.getCoolieHat(12);
    Select = gamepad.getButton(9);
    Start = gamepad.getButton(8);
  }    

  private void mapLogitech()
  {
    leftStick = gamepad.getStick(1);
    rightStick = gamepad.getStick(0);
    T = gamepad.getButton(4);
    C = gamepad.getButton(3);
    X = gamepad.getButton(2);
    S = gamepad.getButton(1);
    R1 = gamepad.getButton(6);
    R2 = gamepad.getButton(8);
    R3 = gamepad.getButton(12);
    L1 = gamepad.getButton(5);
    L2 = gamepad.getButton(7);
    L3 = gamepad.getButton(11);
    DPad = gamepad.getCoolieHat(0);
    Select = gamepad.getButton(9);
    Start = gamepad.getButton(10);
  }

  private void mapPlaystation3()
  {
    leftStick = gamepad.getStick(0);
    leftStick.setTolerance(0.1f);
    rightStick = gamepad.getStick(1);
    rightStick.setTolerance(0.1f);
    T = gamepad.getButton(12);
    C = gamepad.getButton(13);
    X = gamepad.getButton(14);
    S = gamepad.getButton(15);
    R1 = gamepad.getButton(11);
    R2 = gamepad.getButton(9);
    R3 = gamepad.getButton(2);
    L1 = gamepad.getButton(10);
    L2 = gamepad.getButton(8);
    L3 = gamepad.getButton(1);
    Up = gamepad.getButton(4);
    Right = gamepad.getButton(5);
    Down = gamepad.getButton(6);
    Left = gamepad.getButton(7);
    Select = gamepad.getButton(0);
    Start = gamepad.getButton(3);
  }

  private void mapGeneric()
  {
    leftStick = gamepad.getStick(0);
    rightStick = gamepad.getStick(1);
    T = gamepad.getButton(0);
    C = gamepad.getButton(1);
    X = gamepad.getButton(2);
    S = gamepad.getButton(3);
    R1 = gamepad.getButton(7);
    R2 = gamepad.getButton(5);
    R3 = gamepad.getButton(10);
    L1 = gamepad.getButton(6);
    L2 = gamepad.getButton(4);
    L3 = gamepad.getButton(9);
    Up = gamepad.getButton(12);
    Right = gamepad.getButton(13);
    Down = gamepad.getButton(14);
    Left = gamepad.getButton(15);
    Select = gamepad.getButton(8);
    Start = gamepad.getButton(11);
  }

  private void mapXBOX360()
  {
    leftStick = new ControllStick(gamepad.getSlider(1), gamepad.getSlider(0));
    rightStick = new ControllStick(gamepad.getSlider(3), gamepad.getSlider(2));
    Z1 = gamepad.getSlider(4);
    Z1.setTolerance(0.50f);
    T = gamepad.getButton(3);
    C = gamepad.getButton(1);
    X = gamepad.getButton(0);
    S = gamepad.getButton(2);
    R1 = gamepad.getButton(5);
    R3 = gamepad.getButton(9);
    L1 = gamepad.getButton(4);
    L3 = gamepad.getButton(8);
    DPad = gamepad.getCoolieHat(10);
    Select = gamepad.getButton(6);
    Start = gamepad.getButton(7);
  }

  private void mapSidewinder()
  {
    leftStick = new ControllStick(gamepad.getSlider(1), gamepad.getSlider(0));
    leftStick.setTolerance(0.08f);
    rightStick = new ControllStick(gamepad.getSlider(1), gamepad.getSlider(0));
    rightStick.setTolerance(0.08f);
    Z1 = gamepad.getSlider(2);
    Z1.setTolerance(0.50f);
    Z2 = gamepad.getSlider(3);
    Z2.setTolerance(0.50f);
    T = gamepad.getButton(4);
    C = gamepad.getButton(2);
    X = gamepad.getButton(1);
    S = gamepad.getButton(3);
    R1 = gamepad.getButton(6);
    R3 = gamepad.getButton(9);
    L1 = gamepad.getButton(5);
    L3 = gamepad.getButton(8);
    DPad = gamepad.getCoolieHat(0);
    Select = gamepad.getButton(7);
    Start = gamepad.getButton(7);
  }

  void rumble(float amt)
  {
    gamepad.rumble(amt);
  }

  void rumble(float amt, int id)
  {
    gamepad.rumble(amt, id);
  }
  
  private float leftZ()
  {
    if ( Z1 != null )
      return Z1.getValue();
    else
      return 0;
  }

  private float rightZ()
  {
    if ( Z2 != null )
      return Z2.getValue();
    else
      return 0;
  }

  private boolean L2()
  {
    if ( L2 != null ) return L2.pressed();
    else if ( Z1 != null ) return leftZ() != 0;
    else return false;
  }

  private boolean R2()
  {
    if ( R2 != null ) return R2.pressed();
    else if ( Z2 != null ) return rightZ() != 0;
    else return false;
  }

  private boolean DUp()
  {
    if ( Up != null ) return Up.pressed();
    else if ( DPad != null ) return DPad.getY() < 0;
    else return false;
  }

  private boolean DDown()
  {
    if ( Down != null ) return Down.pressed();
    else if ( DPad != null ) return DPad.getY() > 0;
    else return false;
  }

  private boolean DLeft()
  {
    if ( Left != null ) return Left.pressed();
    else if ( DPad != null ) return DPad.getX() < 0;
    else return false;
  }

  private boolean DRight()
  {
    if ( Right != null ) return Right.pressed();
    else if ( DPad != null ) return DPad.getX() > 0;
    else return false;
  }

  ControllerState getState() {
    int i;
    cs.timestamp = System.nanoTime() / 1000;
    i = (invertLeftX ? -1 : 1);
    cs.leftX = leftStick.getX()*i;
    i = (invertRightX ? -1 : 1);
    cs.rightX = rightStick.getX()*i;
    i = (invertLeftY ? -1 : 1);
    cs.leftY = leftStick.getY()*i;
    i = (invertRightY ? -1 : 1);
    cs.rightY = rightStick.getY()*i;
    cs.X = X.pressed(); 
    cs.C = C.pressed(); 
    cs.T = T.pressed(); 
    cs.S = S.pressed(); 
    cs.L1 = L1.pressed();
    cs.L2 = L2();
    cs.L3 = L3.pressed();
    cs.R1 = R1.pressed();
    cs.R2 = R2();
    cs.R3 = R3.pressed();
    cs.Up = DUp();
    cs.Down = DDown();
    cs.Left = DLeft();
    cs.Right = DRight();
    cs.Start = Start.pressed(); 
    cs.Select = Select.pressed(); 
    return cs;
  }
  
  String toString(){
    return gamepad.getName();
  }

}

