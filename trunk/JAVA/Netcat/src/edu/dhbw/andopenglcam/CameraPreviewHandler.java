/**
	Copyright (C) 2009  Tobias Domhan

    This file is part of AndOpenGLCam.

    AndObjViewer is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    AndObjViewer is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with AndObjViewer.  If not, see <http://www.gnu.org/licenses/>.
 
 */
package edu.dhbw.andopenglcam;

import java.lang.reflect.Method;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.Date;
import java.util.List;

import javax.microedition.khronos.opengles.GL10;

import com.atg.netcat.Receiver;
import com.atg.netcat.RobotStateHandler;
import com.atg.netcat.TargetBlob;
import com.atg.netcat.TargetSettings;

import edu.dhbw.andopenglcam.interfaces.PreviewFrameSink;
import android.content.res.Resources;
import android.graphics.BitmapFactory;
import android.graphics.PixelFormat;
import android.hardware.Camera;
import android.hardware.Camera.Parameters;
import android.hardware.Camera.PreviewCallback;
import android.hardware.Camera.Size;
import android.opengl.GLSurfaceView;
import android.provider.MediaStore.Video;
import android.util.Log;

/**
 * Handles callbacks of the camera preview
 * camera preview demo:
 * http://developer.android.com/guide/samples/ApiDemos/src/com/example/android/apis/graphics/CameraPreview.html
 * YCbCr 420 colorspace infos:
	 * http://wiki.multimedia.cx/index.php?title=YCbCr_4:2:0
	 * http://de.wikipedia.org/wiki/YCbCr-Farbmodell
	 * http://www.elektroniknet.de/home/bauelemente/embedded-video/grundlagen-der-videotechnik-ii-farbraum-gammakorrektur-digitale-video-signale/4/
 * @see android.hardware.Camera.PreviewCallback
 * @author Tobias Domhan
 *
 */
public class CameraPreviewHandler implements PreviewCallback {
	private GLSurfaceView glSurfaceView;
	private PreviewFrameSink frameSink;
	private Resources res;
	private int textureSize=256;
	private int previewFrameWidth;
	private int previewFrameHeight;
	private int bwSize;//size of the black/white image
	private int NUMBER_OF_BUFFERS = 16;
	private boolean sendVideo = false;
	
	//Modes:
	public final static int MODE_RGB=0;
	public final static int MODE_GRAY=1;
	public final static int MODE_BIN=2;
	public final static int MODE_EDGE=3;
	public final static int MODE_CONTOUR=4;
	private int mode = MODE_GRAY;
	private Object modeLock = new Object();
	private MarkerInfo markerInfo;
	private ConversionWorker convWorker;
	
	private Camera mCamera;
	
    Date start;
    int proccessedFrameCount;
	
    int rawFrameCount;
	
	public CameraPreviewHandler(GLSurfaceView glSurfaceView,
			PreviewFrameSink sink, Resources res, MarkerInfo markerInfo) {
		this.glSurfaceView = glSurfaceView;
		this.frameSink = sink;
		this.res = res;
		this.markerInfo = markerInfo;
		convWorker = new ConversionWorker(sink);
	}
	
	/**
	 * native libraries
	 */
	static { 
	    System.loadLibrary( "imageprocessing" );
	    System.loadLibrary( "yuv420sp2rgb" );	
	    System.loadLibrary( "framebuffet" );  
	} 

	   /**
     * native function, that finds a color

     */
    public native int detectTargetBlob(byte[] in, int width, int height, int target_cb, int target_cr, int tolerance, TargetBlob marker);
    
	
    /**
     * native function, that gets avg color for calibration
     * @param in  = the byte array of the picture
     * @param width 
     * @param height
     * @param percentOfView = how much of the area to use for the avg, allways uses the center;

     */
    public native int getAvgColor(byte[] in, int width, int height, int CrOffset, int CbOffset, int percentOfView, TargetBlob marker);
    
    
	
	/**
     * native function, that sends a jpeg
     * @param in
     * @param width
     * @param height
     * @param textureSize
     * @param out
     */
    public native int setupJPEG(byte[] host, int port, int width, int height, int quality);
    
    /**
     * native function, that converts a byte array from ycbcr420 to RGB
     * @param in
     * @param width
     * @param height
     * @param textureSize
     * @param out
     */
    private native int sendJPEG(byte[] in);
	
	
	/**
	 * native function, that converts a byte array from ycbcr420 to RGB
	 * @param in
	 * @param width
	 * @param height
	 * @param textureSize
	 * @param out
	 */
	private native void yuv420sp2rgb(byte[] in, int width, int height, int textureSize, byte[] out);

	/**
	 * binarize a image
	 * @param in the input array
	 * @param width image width
	 * @param height image height
	 * @param out the output array
	 * @param threshold the binarization threshold
	 */
	private native void binarize(byte[] in, int width, int height, byte[] out, int threshold);
	
	/**
	 * detect edges in the image
	 * @param in the image
	 * @param width image width
	 * @param height image height
	 * @param magnitude the magnitude of the edge(width*height bytes)
	 * @param gradient the gradient(angle) of the edge(width*height bytes)
	 */
	private native void detect_edges(byte[] in, int width, int height, byte[] out, int threshold);

	/**
	 * detect edges in the image
	 * @param in the image
	 * @param width image width
	 * @param height image height
	 * @param magnitude the magnitude of the edge(width*height bytes)
	 * @param gradient the gradient(angle) of the edge(width*height bytes)
	 */
	private native void detect_edges_simple(byte[] in, int width, int height, byte[] out, int threshold);
	
	/**
	 * the size of the camera preview frame is dynamic
	 * we will calculate the next power of two texture size
	 * in which the preview frame will fit
	 * and set the corresponding size in the renderer
	 * how to decode camera YUV to RGB for opengl:
	 * http://groups.google.de/group/android-developers/browse_thread/thread/c85e829ab209ceea/d3b29d3ddc8abf9b?lnk=gst&q=YUV+420#d3b29d3ddc8abf9b
	 * @param camera
	 */
	public void init(Camera camera) throws Exception {
	    mCamera= camera;
	    listAllCameraMethods();
	    
	    start = new Date();
	    proccessedFrameCount = 0;
	    
	    rawFrameCount = 0;
	  
		Parameters camParams = camera.getParameters();
		//check if the pixel format is supported
		if (camParams.getPreviewFormat() != PixelFormat.YCbCr_420_SP) {
			//Das Format ist semi planar, Erklärung:
			//semi-planar YCbCr 4:2:2 : two arrays, one with all Ys, one with Cb and Cr. 
			//Quelle: http://www.celinuxforum.org/CelfPubWiki/AudioVideoGraphicsSpec_R2
			//throw new Exception(res.getString(R.string.error_unkown_pixel_format));
			throw new Exception("R.string.error_unkown_pixel_format");
			
		}					
		//get width/height of the camera
		Size previewSize = camParams.getPreviewSize();
		previewFrameWidth = previewSize.width;
		previewFrameHeight = previewSize.height;		
		
	    PixelFormat p = new PixelFormat();
        PixelFormat.getPixelFormatInfo(camParams.getPreviewFormat(),p);
        //int bufSize = (previewFrameWidth*previewFrameHeight*p.bitsPerPixel)/8;
           
		textureSize = GenericFunctions.nextPowerOfTwo(Math.max(previewFrameWidth, previewFrameHeight));
		//frame = new byte[textureSize*textureSize*3];
		bwSize = previewFrameWidth * previewFrameHeight;	
		
		frame = new byte[bwSize*3];
		for (int i = 0; i < frame.length; i++) {
			frame[i]=(byte) 128;
		}		
		
		frameSink.setPreviewFrameSize(textureSize, previewFrameWidth, previewFrameHeight);
		//default mode:
		setMode(MODE_RGB);
		markerInfo.setImageSize(previewFrameWidth, previewFrameHeight);
		
	    //Must call this before calling addCallbackBuffer to get all the
	    // reflection variables setup
	    initForACB();
		
	    //Add three buffers to the buffer queue. I re-queue them once they are used in
	    // onPreviewFrame, so we should not need many of them.  
	    for (int i = 0; i < NUMBER_OF_BUFFERS; i++)
	    {
	       addCallbackBuffer(new byte[bwSize*3]);                               
	    }
		
		setPreviewCallbackWithBuffer();
	}

	//size of a texture must be a power of 2
	private byte[] frame;
	
	/**
	 * new frame from the camera arrived. convert and hand over
	 * to the renderer
	 * how to convert between YUV and RGB:http://en.wikipedia.org/wiki/YUV#Y.27UV444
	 * Conversion in C-Code(Android Project):
	 * http://www.netmite.com/android/mydroid/donut/development/tools/yuv420sp2rgb/yuv420sp2rgb.c
	 * http://code.google.com/p/android/issues/detail?id=823
	 * @see android.hardware.Camera.PreviewCallback#onPreviewFrame(byte[], android.hardware.Camera)
	 */
	//@Override
	public void onPreviewFrame(byte[] data, Camera camera) {
		//prevent null pointer exceptions	  
		if (data == null)
			return;
		
        if(rawFrameCount % 30 == 0){
            double ms = (new Date()).getTime() - start.getTime();
            
            float rawFps =  (float) ( 30/(ms/1000.0) );
            float camFps =  (float) ( proccessedFrameCount/(ms/1000.0));
            
            proccessedFrameCount = 0;
            start = new Date();
                          
            Log.i("AR","fps raw:" +rawFps + "fps processed:"+ camFps);
            
            TargetBlob avgColor = new TargetBlob();
            
            getAvgColor(data, previewFrameWidth, previewFrameHeight, -128 , -128, 100, avgColor);
            
        }
        
        rawFrameCount++;		
		if(convWorker.nextFrame(data))
		{
		 // markerInfo.detectMarkers(data);
	      proccessedFrameCount++;
		}
		else
		{
		  //We are done with this buffer, so add it back to the pool     
		  addCallbackBuffer(data);
		}

		
	
		if(sendVideo == false )
		{
		  String ip = RobotStateHandler.getClientIpAddress();
		  if(ip != null)
		  {
		    //Log.d("CamPreview", "Calling setupJPEG with" + ip +" "+ Receiver.videoPort+" "+previewFrameWidth+" "+ previewFrameHeight+" "+Receiver.JPEG_QUALITY);
		    
		    if( setupJPEG(ip.getBytes(), Receiver.videoPort, previewFrameWidth, previewFrameHeight, Receiver.JPEG_QUALITY)  != 0)
		    {
		     sendVideo = false; 
		    }
		    else
		    {
		      sendVideo = true;
		    }
		  }
		}
		
		
			
		      
	}
	
	public void setMode(int pMode) {
		synchronized (modeLock) {
			this.mode = pMode;
			switch(mode) {
			case MODE_RGB:
				frameSink.setMode(GL10.GL_RGB);
				break;
			case MODE_GRAY:
				frameSink.setMode(GL10.GL_LUMINANCE);
				break;
			case MODE_BIN:
				frameSink.setMode(GL10.GL_LUMINANCE);
				break;
			case MODE_EDGE:
				frameSink.setMode(GL10.GL_LUMINANCE);
				break;
			case MODE_CONTOUR:
				frameSink.setMode(GL10.GL_LUMINANCE);
				break;
			}
		}		
	}
	  
    /**
     * This method will list all methods of the android.hardware.Camera class,
     * even the hidden ones. With the information it provides, you can use the same
     * approach I took below to expose methods that were written but hidden in eclair
     */
    private void listAllCameraMethods(){
        try {
            Class c = Class.forName("android.hardware.Camera");
            Method[] m = c.getMethods();
            for(int i=0; i<m.length; i++){
                Log.i("AR","  method:"+m[i].toString());
            }
        } catch (Exception e) {
            // TODO Auto-generated catch block
            Log.i("AR",e.toString());
        }
        
        try {
          Class c = Class.forName("android.hardware.Camera.Parameters");
          Method[] m = c.getMethods();
          for(int i=0; i<m.length; i++){
              Log.i("AR","  method:"+m[i].toString());
          }
      } catch (Exception e) {
          // TODO Auto-generated catch block
          Log.i("AR",e.toString());
      }
    }
    
    /**
     * These variables are re-used over and over by
     * addCallbackBuffer
     */
    Method mAcb;
    Object[] mArglist;
    
    private void initForACB(){
        try {
            Class mC = Class.forName("android.hardware.Camera");
        
            Class[] mPartypes = new Class[1];
            mPartypes[0] = (new byte[1]).getClass(); //There is probably a better way to do this.
            mAcb = mC.getMethod("addCallbackBuffer", mPartypes);

            mArglist = new Object[1];
        } catch (Exception e) {
            Log.e("AR","Problem setting up for addCallbackBuffer: " + e.toString());
        }
    }
    
    /**
     * This method allows you to add a byte buffer to the queue of buffers to be used by preview.
     * See: http://android.git.kernel.org/?p=platform/frameworks/base.git;a=blob;f=core/java/android/hardware/Camera.java;hb=9db3d07b9620b4269ab33f78604a36327e536ce1
     * 
     * @param b The buffer to register. Size should be width * height * bitsPerPixel / 8.
     */
    public void addCallbackBuffer(byte[] b){
        //Check to be sure initForACB has been called to setup
        // mAcb and mArglist
        if(mArglist == null){
            initForACB();
        }

        mArglist[0] = b;
        try {
            mAcb.invoke(mCamera, mArglist);
        } catch (Exception e) {
            Log.e("AR","invoking addCallbackBuffer failed: " + e.toString());
        }
    }
    
    /**
     * Use this method instead of setPreviewCallback if you want to use manually allocated
     * buffers. Assumes that "this" implements Camera.PreviewCallback
     */
    private void setPreviewCallbackWithBuffer(){
        try {
            Class c = Class.forName("android.hardware.Camera");
            
            Method spcwb = null;
            //This way of finding our method is a bit inefficient, but I am a reflection novice,
            // and didn't want to waste the time figuring out the right way to do it.
            // since this method is only called once, this should not cause performance issues
            Method[] m = c.getMethods();
            for(int i=0; i<m.length; i++){
                if(m[i].getName().compareTo("setPreviewCallbackWithBuffer") == 0){
                    spcwb = m[i];
                    break;
                }
            }
            
            //If we were able to find the setPreviewCallbackWithBuffer method of Camera, 
            // we can now invoke it on our Camera instance, setting 'this' to be the
            // callback handler
            if(spcwb != null){
                Object[] arglist = new Object[1];
                arglist[0] = this;
                spcwb.invoke(mCamera, arglist);
                Log.i("AR","setPreviewCallbackWithBuffer: Called method");
            } else {
                Log.i("AR","setPreviewCallbackWithBuffer: Did not find method");
            }
            
        } catch (Exception e) {
            // TODO Auto-generated catch block
            Log.i("AR",e.toString());
        }
    }
	
	/**
	 * A worker thread that does colorspace conversion in the background.
	 * Need so that we can throw frames away if we can't handle the throughput.
	 * Otherwise the more and more frames would be enqueued, if the conversion did take
	 * too long.
	 * @author Tobias Domhan
	 *
	 */
	class ConversionWorker extends Thread {
		private byte[] curFrame = null;
		private PreviewFrameSink frameSink;
		
		/**
		 * 
		 */
		public ConversionWorker(PreviewFrameSink frameSink) {
			setDaemon(true);
			this.frameSink = frameSink;	
			start();
		}
		
		/* (non-Javadoc)
		 * @see java.lang.Thread#run()
		 */
		@Override
		public synchronized void run() {			
			try {
				wait();//wait for initial frame
			} catch (InterruptedException e) {}
			while(true) {
				//Log.d("ConversionWorker","starting conversion");
				frameSink.getFrameLock().lock();
				synchronized (modeLock) {
					switch(mode) {
					case MODE_RGB:			     
					    if(sendVideo)
					    {
					      //Log.d("PreviewHandler", "calling sendJPEG");
					      sendJPEG(curFrame);
					    }
					    else
					    {
    						//color:
    						yuv420sp2rgb(curFrame, previewFrameWidth, previewFrameHeight, textureSize, frame);   
    						//Log.d("ConversionWorker","handing frame over to sink");						
    						frameSink.setNextFrame(ByteBuffer.wrap(frame));
					    }
					    
					    TargetSettings ts = RobotStateHandler.getTargetSettings();
					    
	                    //pink marker
					    if(ts != null)
					    {
					      TargetBlob b = new TargetBlob();
                          int result = detectTargetBlob(curFrame, previewFrameWidth, previewFrameHeight, ts.targetChromaBlue ,ts.targetChromaRed, ts.tollerance, b);
					    
                          if(result >= 0)
                          {
                            Date d = new Date();
                            b.timestamp = d.getTime();
                            Log.d("TARGET BLOB","found blob with error : " + result + " " + b.toString()); 
                            RobotStateHandler.onTargetBlobFound(b);
                          }
					    }
						break;
					case MODE_GRAY:
						//luminace: 
						//we will copy the array, assigning a new reference will cause multihreading issues
						//frame = curFrame;//WILL CAUSE PROBLEMS, WHEN SWITCHING BACK TO RGB
						System.arraycopy(curFrame, 0, frame, 0, bwSize);
						frameSink.setNextFrame(ByteBuffer.wrap(frame));		
						break;
					case MODE_BIN:
						binarize(curFrame, previewFrameWidth, previewFrameHeight, frame, 100);
						frameSink.setNextFrame(ByteBuffer.wrap(frame));
						break;
					case MODE_EDGE:
						detect_edges(curFrame, previewFrameWidth, previewFrameHeight, frame,20);
						frameSink.setNextFrame(ByteBuffer.wrap(frame));
						break;
					case MODE_CONTOUR:
						detect_edges_simple(curFrame, previewFrameWidth, previewFrameHeight, frame,150);
						frameSink.setNextFrame(ByteBuffer.wrap(frame));
						break;
					}
					
				}
				//We are done with this buffer, so add it back to the pool
				addCallbackBuffer(curFrame);
				frameSink.getFrameLock().unlock();
				glSurfaceView.requestRender();	      
		        
				try {
					wait();//wait for next frame
				} catch (InterruptedException e) {}
			}
		}
		
		synchronized boolean nextFrame(byte[] frame) {
			if(this.getState() == Thread.State.WAITING) 
			{
              //ok, we are ready for a new frame:
			    curFrame = frame;
				//do the work:
				this.notify();
				return true;
			} else {
				//ignore it
			  return false;

			}
			
		}
	}

}
