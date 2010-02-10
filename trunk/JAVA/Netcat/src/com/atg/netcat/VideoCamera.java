package com.atg.netcat;

/*
 * Copyright (C) 2009 The Sipdroid Open Source Project
 * Copyright (C) 2007 The Android Open Source Project
 * 
 * This file is part of Sipdroid (http://www.sipdroid.org)
 * 
 * Sipdroid is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 * 
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this source code; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.net.InetAddress;
import java.util.ArrayList;


//import org.sipdroid.sipua.R;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.location.LocationManager;
import android.media.AudioManager;
import android.media.MediaRecorder;
import android.net.LocalServerSocket;
import android.net.LocalSocket;
import android.net.LocalSocketAddress;
import android.os.Bundle;
import android.os.Handler;
import android.os.Message;
import android.os.SystemClock;
import android.provider.MediaStore;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.MenuItem;
import android.view.SurfaceHolder;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.TextView;

public class VideoCamera extends Activity implements  SurfaceHolder.Callback, MediaRecorder.OnErrorListener {
	
	Thread t;
	//Context mContext = this.mContext;

    private static final String TAG = "videocamera";

    private static int UPDATE_RECORD_TIME = 1;
    
    private static final float VIDEO_ASPECT_RATIO = 176.0f / 144.0f;
    VideoPreview mVideoPreview;
    SurfaceHolder mSurfaceHolder = null;
    //ImageView mVideoFrame;

    private MediaRecorder mMediaRecorder;
    private boolean mMediaRecorderRecording = false;
    // The video file that the hardware camera is about to record into
    // (or is recording into.)
    private String mCameraVideoFilename;

    // The video file that has already been recorded, and that is being
    // examined by the user.
    private String mCurrentVideoFilename;

    boolean mPausing = false;

    int mCurrentZoomIndex = 0;

    //private TextView mRecordingTimeView;

    ArrayList<MenuItem> mGalleryItems = new ArrayList<MenuItem>();

    View mPostPictureAlert;
    LocationManager mLocationManager = null;

   // private Handler mHandler = new MainHandler();
    long started;
	LocalSocket receiver,sender;
	LocalServerSocket lss;

    /** This Handler is used to post message back onto the main thread of the application */
	/*
    private class MainHandler extends Handler {
        @Override
        public void handleMessage(Message msg) {
 
         }
    };
*/

    /** Called with the activity is first created. */
    @Override
    public void onCreate(Bundle icicle) {
        super.onCreate(icicle);

        //mLocationManager = (LocationManager) getSystemService(Context.LOCATION_SERVICE);

        //setDefaultKeyMode(DEFAULT_KEYS_SHORTCUT);
        //requestWindowFeature(Window.FEATURE_PROGRESS);
        setContentView(R.layout.video_camera);

        mVideoPreview = (VideoPreview) findViewById(R.id.camera_preview);
        mVideoPreview.setAspectRatio(VIDEO_ASPECT_RATIO);

        // don't set mSurfaceHolder here. We have it set ONLY within
        // surfaceCreated / surfaceDestroyed, other parts of the code
        // assume that when it is set, the surface is also set.
        SurfaceHolder holder = mVideoPreview.getHolder();
        holder.addCallback(this);
        holder.setType(SurfaceHolder.SURFACE_TYPE_PUSH_BUFFERS);

        //mRecordingTimeView = (TextView) findViewById(R.id.recording_time);
        //mVideoFrame = (ImageView) findViewById(R.id.video_frame);
    }

	int speakermode;

	@Override
    public void onResume() {
        super.onResume();

        mPausing = false;

		receiver = new LocalSocket();
		try {
			lss = new LocalServerSocket("Sipdroid");
			receiver.connect(new LocalSocketAddress("Sipdroid"));
			sender = lss.accept();
		} catch (IOException e1) {
			//if (!Sipdroid.release) e1.printStackTrace();
			finish();
			return;
		}

        initializeVideo();
    }

    @Override
    protected void onPause() {
        super.onPause();

        // This is similar to what mShutterButton.performClick() does,
        // but not quite the same.
        if (mMediaRecorderRecording) {
            stopVideoRecording();
        }

        mPausing = true;

        try {
			lss.close();
	        receiver.close();
	        sender.close();
		} catch (IOException e) {
			//if (!Sipdroid.release) e.printStackTrace();
		}
		finish();
    }

	/*
     * catch the back and call buttons to return to the in call activity.
     */
    @Override
    public boolean onKeyDown(int keyCode, KeyEvent event) {

        switch (keyCode) {
        	// finish for these events         	
            case KeyEvent.KEYCODE_BACK:
            	finish();
            	return true;
                
            case KeyEvent.KEYCODE_CAMERA:
                // Disable the CAMERA button while in-call since it's too
                // easy to press accidentally.
            	return true;
        }

        return super.onKeyDown(keyCode, event);
    }


    public void surfaceChanged(SurfaceHolder holder, int format, int w, int h) {
        if (mPausing) {
            // We're pausing, the screen is off and we already stopped
            // video recording. We don't want to start the camera again
            // in this case in order to conserve power.
            // The fact that surfaceChanged is called _after_ an onPause appears
            // to be legitimate since in that case the lockscreen always returns
            // to portrait orientation possibly triggering the notification.
            return;
        }

        stopVideoRecording();
        initializeVideo();
    }

    public void surfaceCreated(SurfaceHolder holder) {
        mSurfaceHolder = holder;
    }

    public void surfaceDestroyed(SurfaceHolder holder) {
        mSurfaceHolder = null;
    }

    private void cleanupEmptyFile() {
        if (mCameraVideoFilename != null) {
            File f = new File(mCameraVideoFilename);
            if (f.length() == 0 && f.delete()) {
              Log.v(TAG, "Empty video file deleted: " + mCameraVideoFilename);
              mCameraVideoFilename = null;
            }
        }
    }

    // initializeVideo() starts preview and prepare media recorder.
    // Returns false if initializeVideo fails
    private boolean initializeVideo() {
        Log.v(TAG, "initializeVideo");

        Intent intent = getIntent();

        releaseMediaRecorder();

        if (mSurfaceHolder == null) {
            Log.v(TAG, "SurfaceHolder is null");
            return false;
        }

        mMediaRecorder = new MediaRecorder();

        mMediaRecorder.setVideoSource(MediaRecorder.VideoSource.CAMERA);
        mMediaRecorder.setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP);
        mMediaRecorder.setOutputFile(sender.getFileDescriptor());

		boolean videoQualityHigh = false;

        if (intent.hasExtra(MediaStore.EXTRA_VIDEO_QUALITY)) {
            int extraVideoQuality = intent.getIntExtra(MediaStore.EXTRA_VIDEO_QUALITY, 0);
            videoQualityHigh = (extraVideoQuality > 0);
        }else
        {
          videoQualityHigh = Receiver.highQuality;
        }
        // Use the same frame rate for both, since internally
        // if the frame rate is too large, it can cause camera to become
        // unstable. We need to fix the MediaRecorder to disable the support
        // of setting frame rate for now.
        mMediaRecorder.setVideoFrameRate(20);
        if (videoQualityHigh) {
            mMediaRecorder.setVideoSize(352,288);
        } else {
            mMediaRecorder.setVideoSize(176,144);//standard
        }
        mMediaRecorder.setVideoEncoder(MediaRecorder.VideoEncoder.H263);
        mMediaRecorder.setPreviewDisplay(mSurfaceHolder.getSurface());

        try {
            mMediaRecorder.prepare();
        } catch (IOException exception) {
            Log.e(TAG, "prepare failed for " + mCameraVideoFilename);
            releaseMediaRecorder();
            finish();
            return false;
        }
        mMediaRecorderRecording = false;

        startVideoRecording();
        return true;
    }

    private void releaseMediaRecorder() {
        Log.v(TAG, "Releasing media recorder.");
        if (mMediaRecorder != null) {
            cleanupEmptyFile();
            mMediaRecorder.reset();
            mMediaRecorder.release();
            mMediaRecorder = null;
        }
    }
        
    private void deleteCurrentVideo() {
        if (mCurrentVideoFilename != null) {
            deleteVideoFile(mCurrentVideoFilename);
            mCurrentVideoFilename = null;
        }
    }

    private void deleteVideoFile(String fileName) {
        Log.v(TAG, "Deleting video " + fileName);
        File f = new File(fileName);
        if (! f.delete()) {
            Log.v(TAG, "Could not delete " + fileName);
        }
    }

    // from MediaRecorder.OnErrorListener
    public void onError(MediaRecorder mr, int what, int extra) {
        if (what == MediaRecorder.MEDIA_RECORDER_ERROR_UNKNOWN) {
            // We may have run out of space on the sdcard.
            finish();
        }
    }

    private void startVideoRecording() {
        Log.v(TAG, "startVideoRecording");
        if (!mMediaRecorderRecording) {

            // Check mMediaRecorder to see whether it is initialized or not.
            if (mMediaRecorder == null && initializeVideo() == false ) {
                Log.e(TAG, "Initialize video (MediaRecorder) failed.");
                return;
            }

            try {
                mMediaRecorder.setOnErrorListener(this);
                mMediaRecorder.start();   // Recording is now started
            } catch (RuntimeException e) {
                Log.e(TAG, "Could not start media recorder. ", e);
                return;
            }
            mMediaRecorderRecording = true;
            started = SystemClock.elapsedRealtime();
            //mRecordingTimeView.setText("");
            //mRecordingTimeView.setVisibility(View.VISIBLE);
            //Handler.sendEmptyMessage(UPDATE_RECORD_TIME);
            setScreenOnFlag();
        
            if (Receiver.listener_video == null) {
    			Receiver.listener_video = this;
    	        (t = new Thread() {
    				public void run() {
    					int frame_size = 1400;
    					//14 = 12 bit RTP header plus two bits for us to mark frame boundrys
    					byte[] buffer = new byte[frame_size + 14];
    					// 4 is a flag for the start of a new frame
    					buffer[12] = 4;
    					RtpPacket rtp_packet = new RtpPacket(buffer, 0);
    					RtpSocket rtp_socket = null;
    					int seqn = 0;
    					int bytesRead,bytesSendabe = 0,src,dest;

    					try {
    						rtp_socket = new RtpSocket(new SipdroidSocket(Receiver.videoPort),Receiver.clientAddress,Receiver.videoPort);
    					} catch (Exception e) {
    						//if (!Sipdroid.release) e.printStackTrace();
    						return;
    					}		
    					
    					InputStream fis = null;
						try {
		   					fis = receiver.getInputStream();
						} catch (IOException e1) {
							//if (!Sipdroid.release) e1.printStackTrace();
							rtp_socket.getDatagramSocket().close();
							return;
						}
						//mark this packet as video
     					rtp_packet.setPayloadType(103);
    					android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_URGENT_DISPLAY);
    					while (Receiver.listener_video != null) {
    					  //-1 means the end of the stream has been reached
    						bytesRead = -1;
    						try {
    						    //read up to 1400 bytes  into the buffer
    						    //we may still have some bytes of the last frame left over to send, so fill what space we have  						  
    							bytesRead = fis.read(buffer,14+bytesSendabe,frame_size-bytesSendabe);
    						} catch (IOException e) {
    							//if (!Sipdroid.release) e.printStackTrace();
    						}
    						if (bytesRead < 0) {
    							try {
    							    //sleep for a while until there is more data to send.
    								sleep(10);
    							} catch (InterruptedException e) {
    								break;
    							}
    							//go back to beining of loop and check the input stream again
    							continue;							
    						}
    						bytesSendabe += bytesRead;
    						
    						
    						//start at end of buffer and read backwards until we find two zeros in a row
    						//finds video frame boundry
    						for (bytesRead = 14+bytesSendabe-2; bytesRead > 14; bytesRead--)
    							if (buffer[bytesRead] == 0 && buffer[bytesRead+1] == 0) break;
    						
    						if (bytesRead == 14) {
    						    //we did not find the frame boundry
    							bytesRead = 0;
    							rtp_packet.setMarker(false);
    						} else {	
    						
    						   //we did find the frame boundry
    						   //packets should not have bytes from more then one frame 
    						    //so don't send any bytes from the newer frame   						   
    							bytesRead = 14+bytesSendabe - bytesRead;
    							rtp_packet.setMarker(true);
    						}
    						
    			 			rtp_packet.setSequenceNumber(seqn++);
    			 			
    			 			//we will send all but the last two bytes
    			 			rtp_packet.setPayloadLength(bytesSendabe-bytesRead+2);
    			 			try {
    			 			    // send this packet of video on its way
    			 				rtp_socket.send(rtp_packet);
    			 			} catch (IOException e) {
    			 				//if (!Sipdroid.release) e.printStackTrace();	
    			 			}
    			 			
    			 			try {
    			 			    //try to prevent the input stream from getting too empty
    			 				if (fis.available() < 24000)
    			 				    //dont sleep for as long if we are about to get a new frame
    			 					Thread.sleep((bytesSendabe-bytesRead)/48); //24
							} catch (Exception e) {
								break;
							}
							
    			 			if (bytesRead > 0) { //we did not send all the data in the buffer because it contains some bytes from the next frame
    			 			    //ignore the two zero frame boundry bytes
    				 			bytesRead -= 2;
    				 			dest = 14;
    				 			src = 14+bytesSendabe - bytesRead;
    				 			bytesSendabe = bytesRead;
    				 			//copy the bytes from the next frame to the begining of the buffer
    				 			while (bytesRead-- > 0)
    				 				buffer[dest++] = buffer[src++];
    				 			// 4 means this is the start of a new frame
    							buffer[12] = 4;
    							//we set the timestamp that will be used for all the packets of this new frame
        			 			rtp_packet.setTimestamp(SystemClock.elapsedRealtime()*90);
    			 			} else {
    			 			    
    			 				bytesSendabe = 0;
    							buffer[12] = 0;
    			 			}
    					}
    					rtp_socket.getDatagramSocket().close();
    				}
    			}).start();   
            }
        	
            //speakermode = Receiver.engine(this).speaker(AudioManager.MODE_NORMAL);
            //RtpStreamSender.delay = 10*1024;
        }
    }

    private void stopVideoRecording() {
        Log.v(TAG, "stopVideoRecording");
        if (mMediaRecorderRecording || mMediaRecorder != null) {
    		Receiver.listener_video = null;
    		t.interrupt();
           // Receiver.engine(this).speaker(speakermode);
           // RtpStreamSender.delay = 0;

            if (mMediaRecorderRecording && mMediaRecorder != null) {
                try {
                    mMediaRecorder.setOnErrorListener(null);
                    mMediaRecorder.setOnInfoListener(null);
                    mMediaRecorder.stop();
                } catch (RuntimeException e) {
                    Log.e(TAG, "stop fail: " + e.getMessage());
                }

                mCurrentVideoFilename = mCameraVideoFilename;
                Log.v(TAG, "Setting current video filename: " + mCurrentVideoFilename);
                mMediaRecorderRecording = false;
            }
            releaseMediaRecorder();
            //mRecordingTimeView.setVisibility(View.GONE);
        }

        deleteCurrentVideo();
    }

    private void setScreenOnFlag() {
        Window w = getWindow();
        final int keepScreenOnFlag = WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON;
        if ((w.getAttributes().flags & keepScreenOnFlag) == 0) {
            w.addFlags(keepScreenOnFlag);
        }
    }

	public void onHangup() {
		finish();
	}
}
