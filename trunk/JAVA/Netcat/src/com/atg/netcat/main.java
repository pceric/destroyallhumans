package com.atg.netcat;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.ServerSocket;
import java.net.Socket;

import android.app.Activity;
import android.os.Bundle;
import android.serialport.SerialPort;
import android.widget.TextView;

public class main extends Activity {
    private TextView tv;
    private SerialPort sp = null;
    private InputStream is;
    private OutputStream os;

	/** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
    	tv = new TextView(this);
        setContentView(tv);
		try {
			sp = new SerialPort(new File("/dev/ttyMSM2"), 9600);
		} catch (SecurityException e1) {
			// TODO Auto-generated catch block
			tv.append(e1.getMessage());
			e1.printStackTrace();
		} catch (IOException e1) {
			// TODO Auto-generated catch block
			tv.append(e1.getMessage());
			e1.printStackTrace();
		}
    }

	/* (non-Javadoc)
	 * @see android.app.Activity#onDestroy()
	 */
	@Override
	protected void onDestroy() {
		// TODO Auto-generated method stub
		super.onDestroy();
        if (sp != null) {
            sp.close();
            sp = null;
        }
    }

	/* (non-Javadoc)
	 * @see android.app.Activity#onResume()
	 */
	@Override
	protected void onResume() {
		// TODO Auto-generated method stub
		super.onResume();
    	try {
        	ServerSocket ss = new ServerSocket(44444);
        	Socket s;
    		s = ss.accept();
    		is = s.getInputStream();
    		os = s.getOutputStream();
            SendThread mSendThread = new SendThread();
            mSendThread.start();
            ReadThread mReadThread = new ReadThread();
            mReadThread.start();
    	} catch (IOException e) {
			// TODO Auto-generated catch block
			tv.append("Socket: " + e.getMessage());
    		e.printStackTrace();
		}
	}
	
    private class SendThread extends Thread {
		InputStream spis = sp.getInputStream();
    	byte[] buffer = new byte[1024];
    	@Override
        public void run() {
            while(!isInterrupted()) {
                try {
	    			if (spis.read(buffer) > 0) {
	    				os.write(buffer);
	        	        //tv.append("Send: " + buffer.length);
                    }
                } catch (IOException e) {
                		tv.append(e.getMessage());
                        e.printStackTrace();
                        return;
                }
            }
        }
    }

    private class ReadThread extends Thread {
		OutputStream spos = sp.getOutputStream();
    	byte[] buffer = new byte[1024];
    	@Override
        public void run() {
                while(!isInterrupted()) {
                        try {
                			if (is.read(buffer) > 0) {
                				spos.write(buffer);
                    	        //tv.append("Read: ");
                			}
                        } catch (IOException e) {
                        		tv.append(e.getMessage());
                                e.printStackTrace();
                                return;
                        }
                }
        }
    }
}