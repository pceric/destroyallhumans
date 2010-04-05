package com.atg.netcat;

public class ControllerState
{
  
   public long timestamp;
   
   public boolean X;
   public boolean C;
   public boolean T; 
   public boolean S;
   public boolean L1;
   public boolean L2;
   public boolean L3;
   public boolean R1;
   public boolean R2;
   public boolean R3;
   public boolean Select;
   public boolean Start;
   public boolean Up;
   public boolean Down;
   public boolean Left;
   public boolean Right;

   public boolean invertLeftX;
   public boolean invertLeftY;
   public boolean invertRightX;
   public boolean invertRightY;
   
   
   public float leftX;
   public float leftY;
   public float rightX;
   public float rightY;
   
   public String extraData = "";

   private float JOYMAX = (float) 127.0; 

  
   
   public String toString(){
     String pressed = "";
     String delim = " ";

     pressed += this.X ? "1" + delim : "0"  + delim;
     pressed += this.C ? "1" + delim : "0"  + delim;
     pressed += this.T ? "1" + delim : "0"  + delim;
     pressed += this.S ? "1" + delim : "0"  + delim;

     pressed += this.L1 ? "1" + delim : "0"  + delim;
     pressed += this.L2 ? "1" + delim : "0"  + delim;
     pressed += this.L3 ? "1" + delim : "0"  + delim;

     pressed += this.R1 ? "1" + delim : "0"  + delim;
     pressed += this.R2 ? "1" + delim : "0"  + delim;
     pressed += this.R3 ? "1" + delim : "0"  + delim;

     pressed += this.Up ? "1" + delim : "0"  + delim;
     pressed += this.Down ? "1" + delim : "0"  + delim;
     pressed += this.Left ? "1" + delim : "0"  + delim;
     pressed += this.Right ? "1" + delim : "0"  + delim;

     pressed += this.Select ? "1" + delim : "0"  + delim;
     pressed += this.Start ? "1" + delim : "0"  + delim;

     pressed += (int)(JOYMAX * this.leftX) + delim;
     pressed += (int)(JOYMAX * this.leftY) + delim;

     pressed += (int)(JOYMAX * this.rightX)+ delim;
     pressed += (int)(JOYMAX * this.rightY)+ delim;

     pressed +="\n";

     return pressed;
   }

   
}
