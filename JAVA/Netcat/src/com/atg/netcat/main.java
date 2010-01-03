package com.atg.netcat;

import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.net.ServerSocket;
import java.net.Socket;

import android.app.Activity;
import android.os.Bundle;

public class main extends Activity {
    /** Called when the activity is first created. */
    @Override
    public void onCreate(Bundle savedInstanceState) {
    	FileOutputStream fos = null;
    	int buffer;
        try {
			fos = new FileOutputStream("/dev/ttyMSM2");
		} catch (FileNotFoundException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
    	try {
        	ServerSocket ss = new ServerSocket(44444);
        	Socket s;
    		s = ss.accept();
    		InputStream is = s.getInputStream();
    		do {
    			buffer = is.read();
    			fos.write(buffer);
    		} while (buffer != 123);
    	} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main);
    }
}