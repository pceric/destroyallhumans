/*  framebuffet.c by Darrell Taylor
 *
 *  Uses code from:
 * 	picture.c
 *
 *	Various funtions for saving/loading pictures.
 *	Copyright 2002 by Jeroen Vreeken (pe1rxq@amsat.org)
 *	Portions of this file are Copyright by Lionnel Maugis
 *	This software is distributed under the GNU public license version 2
 *
 */



#include <framebuffet.h>

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

//#define DEBUG_LOGGING

#define UINT16 unsigned short
#define UINT32 unsigned int
#define BYTE unsigned char

int WIDTH   = 480;
int HEIGHT  = 800;
int QUALITY = 20;

int CB_OFFSET = -128;
int CR_OFFSET = -128;


UINT32 img_size = 1152000;
BYTE out_buffer[1152000];

unsigned char cbData[288000];
unsigned char crData[288000];

int blocks = 32;
long blockTmp[32][32];

BYTE frameTerminator[32];
//unsigned char *out_buffer;


typedef struct
{
    int luma;
	int cb;
    int cr;
    int x;
    int y;
}Color;

Color avgColor;


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
    /*
    	int flag = 64000;
    	if (-1 == setsockopt(SocketFD, IPPROTO_UDP, SO_SNDBUF, (char *) &flag,sizeof(flag)))
    	{
    		__android_log_print(ANDROID_LOG_ERROR, "FRAMEBUFFET","set buffer size failed %d", errno);
    		return 2;
    	}
    */

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
	int i, j, jpeg_image_size, chroma_size;
	unsigned char tmp;
	unsigned char *chroma_start;

	JSAMPROW y[16], cb[8], cr[8]; // y[2][5] = color sample of row 2 and pixel column 5; (one plane)
	JSAMPARRAY data[3];           // t[0][2][5] = color sample 0 of row 2 and column 5

	struct jpeg_compress_struct cinfo;
	struct jpeg_error_mgr jerr;

	data[0] = y;
	data[1] = cb;
	data[2] = cr;

	chroma_size = (width*height)/4;
	chroma_start = input_image + width * height;

	//convert from interleaved to planer format
	for(j=0; j<chroma_size*2; j+=2)
	{
		cbData[j] = chroma_start[j + chroma_size];
		crData[j] = chroma_start[j + 1];
	}


	/*
	//convert from interleaved to planer format
    for(j=0; j<chroma_size*2; j+=2)
    {
    	tmp = chroma_start[j + 1];
    	chroma_start[j + 1] = chroma_start[j + chroma_size];
    	chroma_start[j + chroma_size] = tmp;
    }

    */

	cinfo.err = jpeg_std_error(&jerr);  // errors get written to stderr

	jpeg_create_compress(&cinfo);
	cinfo.image_width = width;
	cinfo.image_height = height;
	cinfo.input_components = 3;
	cinfo.in_color_space = JCS_YCbCr;
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
	cinfo.dct_method = JDCT_IFAST;

	jpeg_mem_dest(&cinfo, dest_image, img_size);	// data written to mem

	jpeg_start_compress (&cinfo, TRUE);

	for (j=0; j<height; j+=16) {
		for (i=0; i<16; i++) {
			//set y to be a pointer to the bw pixel
			y[i] = input_image + width*(i+j);
			//set the chroma
			if (i%2 == 0) {
				//cr[i/2] = input_image + width*height + width/2*((i+j)/2);
				//cb[i/2] = input_image + width*height + width*height/4 + width/2*((i+j)/2);

				 cb[i/2] = cbData + (width/2)*((i+j)/2);
				 cr[i/2] = crData + (width/2)*((i+j)/2);
			}
		}
		jpeg_write_raw_data(&cinfo, data, 16);
	}

	jpeg_finish_compress(&cinfo);
	jpeg_image_size = jpeg_mem_size(&cinfo);
	jpeg_destroy_compress(&cinfo);

/*
	//convert from planer back to interleaved format
    for(j=0; j<chroma_size*2; j+=2)
    {
    	tmp = chroma_start[j + 1];
    	chroma_start[j + 1] = chroma_start[j + chroma_size];
    	chroma_start[j + chroma_size] = tmp;
    }

    */

	return jpeg_image_size;
}



/* put_jpeg_yuv420p_memory converts an input image in the YUV420P format into a jpeg image and puts

 */
int getAvgColor(unsigned char *input_image, int width, int height)
{
	long i, j, jpeg_image_size, chroma_size;
	unsigned char tmp;
	unsigned char *chroma_start;


	long cbAvg = 0;

	long crAvg = 0;


	chroma_size = (width*height)/4;
	chroma_start = input_image + width * height;

	//
	for(j=0; j<chroma_size; j++)
	{
		//the color balance seems to be off ! --floruencent
		cbAvg += chroma_start[j*2] + CB_OFFSET;
		crAvg += chroma_start[j*2 + 1] + CR_OFFSET;
	}

	cbAvg = cbAvg/chroma_size;
	crAvg = crAvg/chroma_size;

	__android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET","Got color avg cb=%d cr=%d",cbAvg,crAvg);

	return 0;
}




Color getBlockAvg(unsigned char *input_image, int width, int height,int x,int y)
{

	//u = cb
	//v = cr



	int i, j;
	unsigned long  k, chroma_size, cr, cb;
	unsigned char *chroma_start;

	int chroma_height = height/2;
	int chroma_width = width/2;

	int blockWidth = chroma_width/blocks;

	int blockHeight = chroma_height/blocks;

	chroma_start = input_image + (width * height);

	Color avg;


	for(i=0;i<blockHeight;i++) {
		for(j=0;j<blockWidth;j++) {


            k = ((i+(blockHeight*y))*chroma_width*2) + ((j+(blockWidth * x))*2);

			cb += chroma_start[k] + CB_OFFSET;
			cr += chroma_start[k + 1] + CR_OFFSET;

		}
	}


	avg.cb = cb/(blockWidth * blockHeight);
	avg.cr = cr/(blockWidth * blockHeight);
    avg.x = (blockWidth * x + (blockWidth/2))*2;
    avg.y = (blockHeight * y + (blockHeight/2))*2;


    return avg;
}


/* put_jpeg_yuv420p_memory converts an input image in the YUV420P format into a jpeg image and puts

 */
int getBestBlock( unsigned char *input_image, int width, int height, int u, int v, int tolarance)
{

	//u = cb
	//v = cr



	int i, j, cr, cb, bestX ,bestY;
	unsigned long  k, chroma_size;
	unsigned char *tmp;
	unsigned char *chroma_start;

	int chroma_height = height/2;
	int chroma_width = width/2;

	int blockWidth = chroma_width/blocks;

	int blockHeight = chroma_height/blocks;

	chroma_size = (width*height)/4;
	chroma_start = input_image + (width * height);



	for(i=0;i<blocks;i++) {
		for(j=0;j<blocks;j++) {
			blockTmp[i][j] = 0;

		}
	}


	for(i=0;i<chroma_height;i++) {
		for(j=0;j<chroma_width;j++) {

            k = (i*chroma_width*2) + (j*2);
			cb = chroma_start[k] + CB_OFFSET;
			cr = chroma_start[k + 1] + CR_OFFSET;


			blockTmp[j/blockWidth][i/blockHeight] += abs(u-cb) + abs(v-cr);

		}
	}

	bestX = 0;
	bestY = 0;
	long score = (blockWidth * blockHeight * tolarance) + 1;
	for(i=0;i<blocks;i++) {
			for(j=0;j<blocks;j++) {
				if( blockTmp[i][j] < score)
				{
					bestX = i;
					bestY = j;
					score = blockTmp[bestX][bestY];
				}

			}
		}

    if(score < (blockWidth * blockHeight * tolarance))
    {

      avgColor = getBlockAvg(input_image,width,height,bestX,bestY);


	 // __android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET","Found Target       Cb=%d Cr=%d   x=%d y=%d score=%d",avgColor.cb, avgColor.cr, bestX, bestY, score);
	  return score;
    }
    else
    {
       return -1;
    }
}



/* put_jpeg_grey_memory converts an input image in the grayscale format into a jpeg image
 * Inputs:
 * - image_size is the size of the input image buffer.
 * - input_image is the image in grayscale format.
 * - width and height are the dimensions of the image
 * - quality is the jpeg encoding quality 0-100%
 * Output:
 * - dest_image is a pointer to the jpeg image buffer
 * Returns buffer size of jpeg image
 */
static int put_jpeg_grey_memory(unsigned char *dest_image, int image_size, unsigned char *input_image, int width, int height, int quality)
{
	int y, dest_image_size;
	JSAMPROW row_ptr[1];
	struct jpeg_compress_struct cjpeg;
	struct jpeg_error_mgr jerr;

	cjpeg.err = jpeg_std_error(&jerr);
	jpeg_create_compress(&cjpeg);
	cjpeg.image_width = width;
	cjpeg.image_height = height;
	cjpeg.input_components = 1; /* one colour component */
	cjpeg.in_color_space = JCS_GRAYSCALE;

	jpeg_set_defaults(&cjpeg);

	jpeg_set_quality(&cjpeg, quality, TRUE);
	cjpeg.dct_method = JDCT_FASTEST;
	jpeg_mem_dest(&cjpeg, dest_image, image_size);  // data written to mem

	jpeg_start_compress (&cjpeg, TRUE);

	row_ptr[0] = input_image;

	for (y=0; y<height; y++) {
		jpeg_write_scanlines(&cjpeg, row_ptr, 1);
		row_ptr[0] += width;
	}

	jpeg_finish_compress(&cjpeg);
	dest_image_size = jpeg_mem_size(&cjpeg);
	jpeg_destroy_compress(&cjpeg);

	return dest_image_size;
}

/* put_jpeg_yuv420p_file converts an YUV420P coded image to a jpeg image and writes
 * it to an already open file.
 * Inputs:
 * - image is the image in YUV420P format.
 * - width and height are the dimensions of the image
 * - quality is the jpeg encoding quality 0-100%
 * Output:
 * - The jpeg is written directly to the file given by the file pointer fp
 * Returns nothing
 */
static void put_jpeg_yuv420p_file(FILE *fp, unsigned char *image, int width, int height, int quality)
{
	int i,j;

	JSAMPROW y[16],cb[16],cr[16]; // y[2][5] = color sample of row 2 and pixel column 5; (one plane)
	JSAMPARRAY data[3]; // t[0][2][5] = color sample 0 of row 2 and column 5

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

	jpeg_stdio_dest(&cinfo, fp);  	  // data written to file
	jpeg_start_compress(&cinfo, TRUE);

	for (j=0;j<height;j+=16) {
		for (i=0;i<16;i++) {
			y[i] = image + width*(i+j);
			if (i%2 == 0) {
				cb[i/2] = image + width*height + width/2*((i+j)/2);
				cr[i/2] = image + width*height + width*height/4 + width/2*((i+j)/2);
			}
		}
		jpeg_write_raw_data(&cinfo, data, 16);
	}

	jpeg_finish_compress(&cinfo);
	jpeg_destroy_compress(&cinfo);
}


/* put_jpeg_grey_file converts an greyscale image to a jpeg image and writes
 * it to an already open file.
 * Inputs:
 * - image is the image in greyscale format.
 * - width and height are the dimensions of the image
 * - quality is the jpeg encoding quality 0-100%
 * Output:
 * - The jpeg is written directly to the file given by the file pointer fp
 * Returns nothing
 */
static void put_jpeg_grey_file(FILE *picture, unsigned char *image, int width, int height, int quality)
{
	int y;
	JSAMPROW row_ptr[1];
	struct jpeg_compress_struct cjpeg;
	struct jpeg_error_mgr jerr;

	cjpeg.err = jpeg_std_error(&jerr);
	jpeg_create_compress(&cjpeg);
	cjpeg.image_width = width;
	cjpeg.image_height = height;
	cjpeg.input_components = 1; /* one colour component */
	cjpeg.in_color_space = JCS_GRAYSCALE;

	jpeg_set_defaults(&cjpeg);

	jpeg_set_quality(&cjpeg, quality, TRUE);
	cjpeg.dct_method = JDCT_FASTEST;
	jpeg_stdio_dest(&cjpeg, picture);

	jpeg_start_compress(&cjpeg, TRUE);

	row_ptr[0]=image;
	for (y=0; y<height; y++) {
		jpeg_write_scanlines(&cjpeg, row_ptr, 1);
		row_ptr[0]+=width;
	}
	jpeg_finish_compress(&cjpeg);
	jpeg_destroy_compress(&cjpeg);
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

	//int compressed_size = put_jpeg_yuv420p_memory(out_buffer, img_size, inArray, WIDTH, HEIGHT, QUALITY);

	int compressed_size = put_jpeg_grey_memory(out_buffer, img_size, inArray, WIDTH, HEIGHT, QUALITY);


#ifdef DEBUG_LOGGING
	__android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET","writing %d  bytes to socket", compressed_size );
#endif


    if (SocketFD == 0 || SocketFD == -1) {
    	__android_log_print(ANDROID_LOG_INFO,"FRAMEBUFFET"," ERROR: socket FD is bad");
        return -1;
    }


	int i=0;
	for(i = 0; i<32; i++)
	{
		out_buffer[compressed_size + i] += 0;
	}

	int bytes_written = send(SocketFD, out_buffer, compressed_size + 32, 0);


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



JNIEXPORT int JNICALL Java_edu_dhbw_andopenglcam_CameraPreviewHandler_detectTargetBlob
(JNIEnv* env, jobject object, jbyteArray pinArray, jint width, jint height, jint target_cb, jint target_cr, jint tolerance, jobject blob) {

	jbyte *inArray;
		inArray = (*env)->GetByteArrayElements(env, pinArray, JNI_FALSE);

    int sucess;


	//sucess = getAvgColor(inArray,width,height);

	sucess = getBestBlock(inArray,width,height,target_cb,target_cr,tolerance);


    if( sucess  >= 0)
    {
      jclass cls = (*env)->GetObjectClass(env,blob);
      jfieldID fid = (*env)->GetFieldID(env, cls, "x", "I");
      (*env)->SetIntField(env, blob, fid, avgColor.x);

      fid = (*env)->GetFieldID(env, cls, "y", "I");
      (*env)->SetIntField(env, blob, fid, avgColor.y);

      fid = (*env)->GetFieldID(env, cls, "chromaBlue", "I");
      (*env)->SetIntField(env, blob, fid, avgColor.cb);

      fid = (*env)->GetFieldID(env, cls, "chromaRed", "I");
      (*env)->SetIntField(env, blob, fid, avgColor.cr);

      fid = (*env)->GetFieldID(env, cls, "width", "I");
      (*env)->SetIntField(env, blob, fid, width/blocks);

      fid = (*env)->GetFieldID(env, cls, "height", "I");
      (*env)->SetIntField(env, blob, fid, height/blocks);
    }

    //int value = env->GetIntField(obj, fid);


    (*env)->ReleaseByteArrayElements(env, pinArray, inArray, 0);

	return sucess;
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
