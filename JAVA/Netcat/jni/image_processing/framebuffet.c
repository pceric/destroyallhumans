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

#include "errno.h"

#include <jerror.h>

#define DEBUG_LOGGING

#define UINT16 unsigned short
#define UINT32 unsigned int
#define BYTE unsigned char

int WIDTH   = 480;
int HEIGHT  = 800;
int QUALITY = 20;


UINT32 img_size = 1152000;
BYTE out_buffer[1152000];
//unsigned char *out_buffer;


int SocketFD;

struct jpeg_compress_struct cinfo;
struct jpeg_error_mgr jerr;

int MakeNetworkConnection(char *addr, int port) {

	__android_log_print(ANDROID_LOG_INFO, "FRAMEBUFFET","getting network addres %s : %d ", addr, port);

    struct sockaddr_in stSockAddr;
    int Res;
    SocketFD = socket(PF_INET, SOCK_DGRAM, IPPROTO_UDP);

    if (SocketFD <=0 )
    {
    	__android_log_print(ANDROID_LOG_ERROR, "FRAMEBUFFET","could not get socket file descriptor %d" ,errno);
    	return 2;
    }

    memset(&stSockAddr, 0, sizeof(struct sockaddr_in));

    stSockAddr.sin_family = AF_INET;
    stSockAddr.sin_port = htons(port);
    Res = inet_pton(AF_INET, addr, &stSockAddr.sin_addr);

    // Set buffer size
    	int flag = 64000;
    	if (-1 == setsockopt(SocketFD, IPPROTO_UDP, SO_SNDBUF, (char *) &flag,sizeof(flag)))
    	{
    		__android_log_print(ANDROID_LOG_ERROR, "FRAMEBUFFET","set buffer size failed %d", errno);
    		return 2;
    	}

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



	__android_log_print(ANDROID_LOG_INFO, "FRAMEBUFFET","connect succceded Socket FD is %d", SocketFD);

    //sendto(sock, buffer, buffer_length, 0,(struct sockaddr*)&sa, sizeof (struct sockaddr_in));


    return 0;
}

/* The following declarations and 5 functions are jpeg related
 * functions used by put_jpeg_grey_memory and put_jpeg_yuv420p_memory
 */
typedef struct {
        struct jpeg_destination_mgr pub;
        JOCTET *buf;
        size_t bufsize;
        size_t jpegsize;
} mem_destination_mgr;

typedef mem_destination_mgr *mem_dest_ptr;


METHODDEF(void) init_destination(j_compress_ptr cinfo)
{
        mem_dest_ptr dest = (mem_dest_ptr) cinfo->dest;

        dest->pub.next_output_byte = dest->buf;
        dest->pub.free_in_buffer = dest->bufsize;
        dest->jpegsize = 0;
}

METHODDEF(boolean) empty_output_buffer(j_compress_ptr cinfo)
{
        mem_dest_ptr dest = (mem_dest_ptr) cinfo->dest;

        dest->pub.next_output_byte = dest->buf;
        dest->pub.free_in_buffer = dest->bufsize;

        return FALSE;
        ERREXIT(cinfo, JERR_BUFFER_SIZE);
}

METHODDEF(void) term_destination(j_compress_ptr cinfo)
{
        mem_dest_ptr dest = (mem_dest_ptr) cinfo->dest;
        dest->jpegsize = dest->bufsize - dest->pub.free_in_buffer;
}

GLOBAL(void) jpeg_mem_dest(j_compress_ptr cinfo, JOCTET* buf, size_t bufsize)
{
        mem_dest_ptr dest;

        if (cinfo->dest == NULL) {
                cinfo->dest = (struct jpeg_destination_mgr *)
                    (*cinfo->mem->alloc_small)((j_common_ptr)cinfo, JPOOL_PERMANENT,
                    sizeof(mem_destination_mgr));
        }

        dest = (mem_dest_ptr) cinfo->dest;

        dest->pub.init_destination    = init_destination;
        dest->pub.empty_output_buffer = empty_output_buffer;
        dest->pub.term_destination    = term_destination;

        dest->buf      = buf;
        dest->bufsize  = bufsize;
        dest->jpegsize = 0;
}

GLOBAL(int) jpeg_mem_size(j_compress_ptr cinfo)
{
        mem_dest_ptr dest = (mem_dest_ptr) cinfo->dest;
        return dest->jpegsize;
}


/* put_jpeg_yuv420p_memory converts an input image in the YUV420P format into a jpeg image and puts
 * it in a memory buffer.
 * Inputs:
 * - image_size is the size of the input image buffer.
 * - input_image is the image in YUV420P format.
 * - width and height are the dimensions of the image
 * - quality is the jpeg encoding quality 0-100%
 * Output:
 * - dest_image is a pointer to the jpeg image buffer
 * Returns buffer size of jpeg image
 */
int put_jpeg_yuv420p_memory(unsigned char *dest_image, int image_size,
                            unsigned char *input_image, int width, int height, int quality)
{
	int i, j, jpeg_image_size;

	JSAMPROW y[16],cb[16],cr[16]; // y[2][5] = color sample of row 2 and pixel column 5; (one plane)
	JSAMPARRAY data[3];           // t[0][2][5] = color sample 0 of row 2 and column 5

	struct jpeg_compress_struct cinfo;
	struct jpeg_error_mgr jerr;

	data[0] = y;
	data[1] = cb;
	data[2] = cr;

	cinfo.err = jpeg_std_error(&jerr);  // errors get written to stderr

	jpeg_create_compress(&cinfo);
	cinfo.image_width = width;
	cinfo.image_height = height;
	cinfo.input_components = 3;
	jpeg_set_defaults(&cinfo);

	jpeg_set_colorspace(&cinfo, JCS_YCbCr);

	cinfo.raw_data_in = TRUE; // supply downsampled data
	cinfo.comp_info[0].h_samp_factor = 2;
	cinfo.comp_info[0].v_samp_factor = 2;
	cinfo.comp_info[1].h_samp_factor = 1;
	cinfo.comp_info[1].v_samp_factor = 1;
	cinfo.comp_info[2].h_samp_factor = 1;
	cinfo.comp_info[2].v_samp_factor = 1;

	jpeg_set_quality(&cinfo, quality, TRUE);
	cinfo.dct_method = JDCT_FASTEST;

	jpeg_mem_dest(&cinfo, dest_image, img_size);	// data written to mem

	jpeg_start_compress (&cinfo, TRUE);

	for (j=0; j<height; j+=16) {
		for (i=0; i<16; i++) {
			y[i] = input_image + width*(i+j);
			if (i%2 == 0) {
				cb[i/2] = input_image + width*height + width/2*((i+j)/2);
				cr[i/2] = input_image + width*height + width*height/4 + width/2*((i+j)/2);
			}
		}
		jpeg_write_raw_data(&cinfo, data, 16);
	}

	jpeg_finish_compress(&cinfo);
	jpeg_image_size = jpeg_mem_size(&cinfo);
	jpeg_destroy_compress(&cinfo);

	return jpeg_image_size;
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

	int compressed_size = put_jpeg_yuv420p_memory(out_buffer, img_size, inArray, WIDTH, HEIGHT, QUALITY);

#ifdef DEBUG_LOGGING
	__android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET","writing %d  bytes to socket", compressed_size );
#endif

	/*

	// Write out the image size, and then the image contents
	BYTE *size_bytes = (BYTE*)&img_size;
	/*fwrite(&size_bytes[3], 1, 1, stdout);
	 fwrite(&size_bytes[2], 1, 1, stdout);
	 fwrite(&size_bytes[1], 1, 1, stdout);
	 fwrite(&size_bytes[0], 1, 1, stdout);
	write(SocketFD, &size_bytes[3], 1);
	write(SocketFD, &size_bytes[2], 1);
	write(SocketFD, &size_bytes[1], 1);
	write(SocketFD, &size_bytes[0], 1);


	//fwrite(out_buffer, img_size, 1, stdout);
	write(SocketFD, out_buffer, compressed_size);

	*/

    if (SocketFD == 0 || SocketFD == -1) {
    	__android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET"," ERROR: socket FD is bad");
        return -1;
    }


	int bytes_written = send(SocketFD, out_buffer, 1000, 0);

	if(bytes_written < 0)
	{
#ifdef DEBUG_LOGGING
	__android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET","Error sending packet: %d\n, ", errno);
#endif
	}


	//release arrays:
	(*env)->ReleaseByteArrayElements(env, pinArray, inArray, 0);
	return compressed_size;
}



JNIEXPORT int JNICALL Java_edu_dhbw_andopenglcam_CameraPreviewHandler_setupJPEG
(JNIEnv * env, jobject object, jbyteArray host, jint port, jint width, jint height, jint quality)
{

#ifdef DEBUG_LOGGING
	__android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET","seting up jpeg encoder w=%d h=%d q=%d",width,height,quality);
#endif

	jbyte *hostArray;
	hostArray = (*env)->GetByteArrayElements(env, host, JNI_FALSE);


	WIDTH = width;

	HEIGHT = height;

	QUALITY = quality;


	int sucess = MakeNetworkConnection(hostArray, port);

	//release arrays:
	(*env)->ReleaseByteArrayElements(env, host, hostArray, 0);

	return sucess;
}
