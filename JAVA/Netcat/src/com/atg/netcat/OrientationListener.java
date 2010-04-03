package com.atg.netcat;

  public interface OrientationListener {
    
    public void onOrientationChanged(float azimuth, 
            float pitch, float roll);
 
    public void onCompassChanged(float x, 
        float y, float z);
    
    
    /**
     * Top side of the phone is up
     * The phone is standing on its bottom side
     */
    public void onTopUp();
 
    /**
     * Bottom side of the phone is up
     * The phone is standing on its top side
     */
    public void onBottomUp();
 
    /**
     * Right side of the phone is up
     * The phone is standing on its left side
     */
    public void onRightUp();
 
    /**
     * Left side of the phone is up
     * The phone is standing on its right side
     */
    public void onLeftUp();

    public void onLightLevelChanged(float level);
 

}
