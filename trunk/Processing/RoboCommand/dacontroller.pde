class DAController
{
  private ControllDevice gamepad;
  public ControllStick leftStick;
  public ControllStick rightStick;
  private ControllCoolieHat DPad;
  private ControllSlider XBOXTrig;
  private ControllerState cs;

  // concessions to the XBOX Controller, maybe I'm going a little overboard?
  public float leftTriggerMultiplier, leftTriggerTolerance, leftTriggerTotalValue;
  public float rightTriggerMultiplier, rightTriggerTolerance, rightTriggerTotalValue;

  private float JOYMAX = 127.0; 

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
    println(gamepad.getName());
    gamepad.printSticks();
    gamepad.printButtons();
    gamepad.printSliders();
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
    else if (match(gamepad.getName(), "SideWinder") != null)
      mapSidewinder();
    else 
    {
      println("Unrecognized device name, using Logitech mapping.");
      mapLogitech();
    }
    leftTriggerTotalValue = rightTriggerTotalValue = 0;
    invertLeftX = invertLeftY = invertRightX = invertRightY = false;
  }

  private void mapJoybox()
  {
    leftStick = gamepad.getStick(1);
    rightStick = gamepad.getStick(0);
    leftTriggerMultiplier = rightTriggerMultiplier = 1;
    leftTriggerTolerance = rightTriggerTolerance = 0;
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
    leftTriggerMultiplier = rightTriggerMultiplier = 1;
    leftTriggerTolerance = rightTriggerTolerance = 0;
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
    rightStick = gamepad.getStick(1);
    leftTriggerMultiplier = rightTriggerMultiplier = 1;
    leftTriggerTolerance = rightTriggerTolerance = 0;
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
    leftTriggerMultiplier = rightTriggerMultiplier = 1;
    leftTriggerTolerance = rightTriggerTolerance = 0;
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
    XBOXTrig = gamepad.getSlider(4);
    leftTriggerTolerance = rightTriggerTolerance = XBOXTrig.getTolerance();
    leftTriggerMultiplier = rightTriggerMultiplier = XBOXTrig.getMultiplier();
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
    rightStick = new ControllStick(gamepad.getSlider(1), gamepad.getSlider(0));
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
  
  float leftX()
  {
    int i = (invertLeftX ? -1 : 1);
    return leftStick.getX()*i;
  }

  float rightX()
  {
    int i = (invertRightX ? -1 : 1);
    return rightStick.getX()*i;
  }

  float leftY()
  {
    int i = (invertLeftY ? 1 : -1);
    return leftStick.getY()*i;
  }

  float rightY()
  {
    int i = (invertRightY ? 1 : -1);
    return rightStick.getY()*i;
  }

  float leftZ()
  {
    if ( XBOXTrig != null )
    {
      float v = leftTriggerMultiplier*XBOXTrig.getValue();
      if ( v > leftTriggerTolerance ) 
      {
        leftTriggerTotalValue += v;
        return v;
      }
      else return 0;
    }
    else if ( L2 != null )
    {
      if ( L2.pressed() )
      {
        leftTriggerTotalValue += leftTriggerMultiplier;
        return leftTriggerMultiplier;
      }
      else return 0;
    }
    else return 0;
  }

  float rightZ()
  {
    if ( XBOXTrig != null )
    {
      float v = -rightTriggerMultiplier*XBOXTrig.getValue();
      if ( v > rightTriggerTolerance ) 
      {
        rightTriggerTotalValue += v;
        return v;
      }
      else return 0;
    }
    else if ( R2 != null )
    {
      if ( R2.pressed() )
      {
        rightTriggerTotalValue += rightTriggerMultiplier;
        return rightTriggerMultiplier;
      }
      else return 0;
    }
    else return 0;
  }

  boolean T() { 
    return T.pressed(); 
  }
  boolean C() { 
    return C.pressed(); 
  }
  boolean X() { 
    return X.pressed(); 
  }
  boolean S() { 
    return S.pressed(); 
  }
  boolean L1(){ 
    return L1.pressed(); 
  }

  boolean L2()
  {
    if ( L2 != null ) return L2.pressed();
    else if ( XBOXTrig != null ) return leftZ() > 0;
    else return false;
  }

  boolean L3() { 
    return L3.pressed(); 
  }
  boolean R1() { 
    return R1.pressed(); 
  }

  boolean R2()
  {
    if ( R2 != null ) return R2.pressed();
    else if ( XBOXTrig != null ) return rightZ() > 0;
    else return false;
  }

  boolean R3() { 
    return R3.pressed(); 
  }
  boolean Start() { 
    return Start.pressed(); 
  }
  boolean Select() { 
    return Select.pressed(); 
  }

  boolean DUp()
  {
    if ( Up != null ) return Up.pressed();
    else if ( DPad != null ) return DPad.getY() < 0;
    else return false;
  }

  boolean DDown()
  {
    if ( Down != null ) return Down.pressed();
    else if ( DPad != null ) return DPad.getY() > 0;
    else return false;
  }

  boolean DLeft()
  {
    if ( Left != null ) return Left.pressed();
    else if ( DPad != null ) return DPad.getX() < 0;
    else return false;
  }

  boolean DRight()
  {
    if ( Right != null ) return Right.pressed();
    else if ( DPad != null ) return DPad.getX() > 0;
    else return false;
  }

  ControllerState getState() {
    return cs;
  }
  
  String toString(){
    String pressed = "";
    String delim = " ";

    pressed += this.X() ? "1" + delim : "0"  + delim;
    pressed += this.C() ? "1" + delim : "0"  + delim;
    pressed += this.T() ? "1" + delim : "0"  + delim;
    pressed += this.S() ? "1" + delim : "0"  + delim;

    pressed += this.L1() ? "1" + delim : "0"  + delim;
    pressed += this.L2() ? "1" + delim : "0"  + delim;
    pressed += this.L3() ? "1" + delim : "0"  + delim;

    pressed += this.R1() ? "1" + delim : "0"  + delim;
    pressed += this.R2() ? "1" + delim : "0"  + delim;
    pressed += this.R3() ? "1" + delim : "0"  + delim;

    pressed += this.DUp() ? "1" + delim : "0"  + delim;
    pressed += this.DDown() ? "1" + delim : "0"  + delim;
    pressed += this.DLeft() ? "1" + delim : "0"  + delim;
    pressed += this.DRight() ? "1" + delim : "0"  + delim;

    pressed += this.Select() ? "1" + delim : "0"  + delim;
    pressed += this.Start() ? "1" + delim : "0"  + delim;

    pressed += int(JOYMAX * this.leftX()) + delim;
    pressed += int(JOYMAX * this.leftY()) + delim;

    pressed += int(JOYMAX * this.rightX())+ delim;
    pressed += int(JOYMAX * this.rightY())+ delim;

    pressed +="\n";

    return pressed;
  }

}

