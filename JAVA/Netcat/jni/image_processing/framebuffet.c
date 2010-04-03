// CameraSend.cpp : Defines the entry point for the console application.
//

#include <jni.h>
#include <preview_handler_jni.h>

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
#include <android/log.h>



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

int socket_fd;


struct jpeg_compress_struct cinfo;
struct jpeg_error_mgr jerr;



void MakeNetworkConnection(char *host, char *port)
{
	struct addrinfo hints;
    struct addrinfo *result, *rp;

	int s;


	/* Obtain address(es) matching host/port */

    memset(&hints, 0, sizeof(struct addrinfo));
    hints.ai_family = AF_UNSPEC;    /* Allow IPv4 or IPv6 */
    hints.ai_socktype = SOCK_STREAM; /* TCPIP socket */
    hints.ai_flags = 0;
    hints.ai_protocol = 0;          /* Any protocol */

    s = getaddrinfo(host, port, &hints, &result);
    if (s != 0) {
        fprintf(stderr, "getaddrinfo error: %s\n", gai_strerror(s));
        exit(EXIT_FAILURE);
    }

    /* getaddrinfo() returns a list of address structures.
       Try each address until we successfully connect(2).
       If socket(2) (or connect(2)) fails, we (close the socket
       and) try the next address. */

    for (rp = result; rp != NULL; rp = rp->ai_next) {
        socket_fd = socket(rp->ai_family, rp->ai_socktype,
                     rp->ai_protocol);
        if (socket_fd == -1)
            continue;

        if (connect(socket_fd, rp->ai_addr, rp->ai_addrlen) != -1)
            break;                  /* Success */

        close(socket_fd);
    }

    if (rp == NULL) {               /* No address succeeded */
        fprintf(stderr, "Could not connect\n");
        exit(EXIT_FAILURE);
    }

    freeaddrinfo(result);           /* No longer needed */

	// Disable NAGLE
	int flag = 1;
	setsockopt( socket_fd, IPPROTO_TCP, TCP_NODELAY, (char *)&flag, sizeof(flag) );

}


JNIEXPORT void JNICALL Java_edu_dhbw_andopenglcam_CameraPreviewHandler_sendJPEG
  (JNIEnv* env, jobject object, jbyteArray pinArray) {
	jbyte *inArray;
	inArray = (*env)->GetByteArrayElements(env, pinArray, JNI_FALSE);
	//see http://java.sun.com/docs/books/jni/html/functions.html#100868
	//If isCopy is not NULL, then *isCopy is set to JNI_TRUE if a copy is made; if no copy is made, it is set to JNI_FALSE.

	JSAMPROW row_pointer[1];	/* pointer to a single row */

	jpeg_start_compress(&cinfo, TRUE);

    int row_stride;                 /* physical row width in buffer */

    row_stride = cinfo.image_width * 3;   /* JSAMPLEs per row in image_buffer */

    while (cinfo.next_scanline < cinfo.image_height) {
        row_pointer[0] = &inArray[cinfo.next_scanline * row_stride];
        jpeg_write_scanlines(&cinfo, row_pointer, 1);
    }

    jpeg_finish_compress(&cinfo);
	// Write out the image size, and then the image contents
	BYTE *size_bytes = (BYTE*)&img_size;
	/*fwrite(&size_bytes[3], 1, 1, stdout);
	fwrite(&size_bytes[2], 1, 1, stdout);
	fwrite(&size_bytes[1], 1, 1, stdout);
	fwrite(&size_bytes[0], 1, 1, stdout);*/
	write(socket_fd, &size_bytes[3], 1);
	write(socket_fd, &size_bytes[2], 1);
	write(socket_fd, &size_bytes[1], 1);
	write(socket_fd, &size_bytes[0], 1);

	//fwrite(img_buffer, img_size, 1, stdout);
	write(socket_fd, img_buffer, img_size);


	//release arrays:
	(*env)->ReleaseByteArrayElements(env, pinArray, inArray, 0);
}


JNIEXPORT void JNICALL Java_edu_dhbw_andopenglcam_CameraPreviewHandler_setupJPEG
(JNIEnv * env, jobject object, jstring host, jint port, jint width, jint height, jint quality)
{


    char portStr[8];
	sprintf(portStr, "%d\n", port);

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


	MakeNetworkConnection(host, portStr);
}
