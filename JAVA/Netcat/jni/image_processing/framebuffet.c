// CameraSend.cpp : Defines the entry point for the console application.
//

#include <jni.h>
#include <preview_handler_jni.h>

#include <android/log.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <jpeglib.h>

#define DEBUG_LOGGING

#define UINT16 unsigned short
#define UINT32 unsigned int
#define BYTE unsigned char

#define WIDTH 480
#define HEIGHT 800

#define BITS_PER_PIXEL 4
#define FB_SIZE (WIDTH * HEIGHT * BITS_PER_PIXEL)
#define IMAGE_SIZE (WIDTH * HEIGHT * 3)

FILE *fb;
BYTE *fb_buffer;
BYTE *img_buffer;
BYTE *scanline;
unsigned long img_size;

int SocketFD;

struct jpeg_compress_struct cinfo;
struct jpeg_error_mgr jerr;

int MakeNetworkConnection(char *addr, int port) {

	__android_log_print(ANDROID_LOG_INFO, "FRAMEBUFFET","getting network addres %s : %d ", addr, port);

    struct sockaddr_in stSockAddr;
    int Res;
    int SocketFD = socket(PF_INET, SOCK_STREAM, IPPROTO_TCP);

    if (-1 == SocketFD)
    {
    	__android_log_print(ANDROID_LOG_ERROR, "FRAMEBUFFET","could not get socket file descriptor");
    	return 2;
    }

    memset(&stSockAddr, 0, sizeof(struct sockaddr_in));

    stSockAddr.sin_family = AF_INET;
    stSockAddr.sin_port = htons(port);
    Res = inet_pton(AF_INET, addr, &stSockAddr.sin_addr);

    if (0 > Res)
    {
      __android_log_print(ANDROID_LOG_ERROR, "FRAMEBUFFET","error: first parameter is not a valid address family");
      close(SocketFD);
      return 2;
    }
    else if (0 == Res)
    {
      __android_log_print(ANDROID_LOG_ERROR, "FRAMEBUFFET","char string (second parameter does not contain valid ipaddress");
      close(SocketFD);
      return 2;
    }

    if (-1 == connect(SocketFD, (const struct sockaddr *)&stSockAddr, sizeof(struct sockaddr_in)))
    {
      __android_log_print(ANDROID_LOG_ERROR, "FRAMEBUFFET","connect failed");
      return 2;
    }

	// Disable NAGLE
	int flag = 1;
	//setsockopt(SocketFD, IPPROTO_TCP, TCP_NODELAY, (char *) &flag,sizeof(flag));

	__android_log_print(ANDROID_LOG_INFO, "FRAMEBUFFET","connect succceded");

    return 0;
}

JNIEXPORT int JNICALL Java_edu_dhbw_andopenglcam_CameraPreviewHandler_sendJPEG
(JNIEnv* env, jobject object, jbyteArray pinArray) {

#ifdef DEBUG_LOGGING
	__android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET","compressing image");
#endif

	jbyte *inArray;
	inArray = (*env)->GetByteArrayElements(env, pinArray, JNI_FALSE);
	//see http://java.sun.com/docs/books/jni/html/functions.html#100868
	//If isCopy is not NULL, then *isCopy is set to JNI_TRUE if a copy is made; if no copy is made, it is set to JNI_FALSE.

	JSAMPROW row_pointer[1]; /* pointer to a single row */

	jpeg_start_compress(&cinfo, TRUE);

	int row_stride; /* physical row width in buffer */

	row_stride = cinfo.image_width * 3; /* JSAMPLEs per row in image_buffer */

	while (cinfo.next_scanline < cinfo.image_height) {
		row_pointer[0] = &inArray[cinfo.next_scanline * row_stride];
		jpeg_write_scanlines(&cinfo, row_pointer, 1);
	}

	jpeg_finish_compress(&cinfo);

#ifdef DEBUG_LOGGING
	__android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET","writing %d  bytes to socket", img_size );
#endif

	// Write out the image size, and then the image contents
	BYTE *size_bytes = (BYTE*)&img_size;
	/*fwrite(&size_bytes[3], 1, 1, stdout);
	 fwrite(&size_bytes[2], 1, 1, stdout);
	 fwrite(&size_bytes[1], 1, 1, stdout);
	 fwrite(&size_bytes[0], 1, 1, stdout);*/
	write(SocketFD, &size_bytes[3], 1);
	write(SocketFD, &size_bytes[2], 1);
	write(SocketFD, &size_bytes[1], 1);
	write(SocketFD, &size_bytes[0], 1);

	//fwrite(img_buffer, img_size, 1, stdout);
	write(SocketFD, img_buffer, img_size);

	//release arrays:
	(*env)->ReleaseByteArrayElements(env, pinArray, inArray, 0);
	return 0;
}

JNIEXPORT int JNICALL Java_edu_dhbw_andopenglcam_CameraPreviewHandler_setupJPEG
(JNIEnv * env, jobject object, jbyteArray host, jint port, jint width, jint height, jint quality)
{

#ifdef DEBUG_LOGGING
	__android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET","seting up jpeg encoder w=%d h=%d q=%d",width,height,quality);
#endif

	jbyte *hostArray;
	hostArray = (*env)->GetByteArrayElements(env, host, JNI_FALSE);

	//char portStr[8];
	//sprintf(portStr, "%d\n", port);

	cinfo.err = jpeg_std_error(&jerr);
	jpeg_create_compress(&cinfo);

	cinfo.in_color_space = JCS_YCbCr;
	cinfo.input_components = 3;
	cinfo.image_width = width;
	cinfo.image_height = height;

	jpeg_set_defaults(&cinfo);
	jpeg_set_colorspace(&cinfo,JCS_YCbCr);
	jpeg_set_quality(&cinfo, quality, TRUE);
	cinfo.dct_method = JDCT_FASTEST;

	jpeg_mem_dest(&cinfo, &img_buffer, &img_size);

	int sucess = MakeNetworkConnection(hostArray, port);

	//release arrays:
	(*env)->ReleaseByteArrayElements(env, host, hostArray, 0);

	return sucess;
}
