/*
 * Robot control console. Copyright (C) 2010 Darrell Taylor & Eric Hokanson
 * 
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) any
 * later version.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more
 * details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

package com.allthingsgeek.servobot;

import com.allthingsgeek.servobot.R;

import android.app.Activity;
import android.app.ProgressDialog;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.wifi.WifiInfo;
import android.net.wifi.WifiManager;
import android.os.Bundle;
import android.os.PowerManager;
import android.text.format.Formatter;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;
import android.view.View;
import android.widget.TextView;
import android.widget.ToggleButton;

public class MainActivity extends Activity {
	public static final String PREFS_NAME = "ServoBotPrefsFile";

	PulseGenerator noise;
	Thread noiseThread;
	IPCommThread ipComThread;
	RobotState robotState;
	Movement mover;
	int ipAddress;
	int port = 3333;
	
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
        
        PowerManager pm = (PowerManager) getSystemService(Context.POWER_SERVICE);
        PowerManager.WakeLock wl = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "ServoOn");
        //wl.acquire();
        //wl.release();
        
        WifiManager wifiManager = (WifiManager) getSystemService(WIFI_SERVICE);
        WifiInfo wifiInfo = wifiManager.getConnectionInfo();
        int ipAddress = wifiInfo.getIpAddress();
        TextView tv = (TextView)findViewById(R.id.TextViewIP);
        tv.setText(Formatter.formatIpAddress(ipAddress));
        
        robotState = new RobotState();
        noise = PulseGenerator.getInstance();
        mover = Movement.getInstance();
        
        // Restore preferences
        SharedPreferences settings = getSharedPreferences(PREFS_NAME, 0);
        noise.setOffsetPulsePercent(settings.getInt("servo1Percent", 50), 0);
        noise.setOffsetPulsePercent(settings.getInt("servo2Percent", 50), 1);
        noise.setOffsetPulsePercent(settings.getInt("servo3Percent", 50), 2);
        noise.setOffsetPulsePercent(settings.getInt("servo4Percent", 50), 3);
		//noise.setWheelOffset(settings.getFloat("wheelOffset", 0));

    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.menu, menu);
        return true;
    }
    
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle item selection
        switch (item.getItemId()) {
        case R.id.setup:
        	Intent i = new Intent(this, SetupActivity.class);
            startActivity(i);
            return true;
        case R.id.quit:
        	noise.stop();
        	finish();
            return true;
        default:
            return super.onOptionsItemSelected(item);
        }
    }
    
    public void onTogglePowerButton(View v)
    {
    	ToggleButton t = (ToggleButton)v;
    	if (t.isChecked()) {
    		String msg = "IP:" + Formatter.formatIpAddress(ipAddress) + ":" + port;
    		//ProgressDialog dialog = ProgressDialog.show(this, msg, "Waiting for client connection...");
    		//ipComThread = new IPCommThread(port, dialog, robotState);
    		//ipComThread.start();
    		noise.pause(false);
    	} else {
    		noise.pause(true);
    	}
    }

    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event)
    {
    	return mover.processKeyEvent(keyCode);
    }
}
