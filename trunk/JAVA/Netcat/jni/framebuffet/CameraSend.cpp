// CameraSend.cpp : Defines the entry point for the console application.
//

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

//void ReadFrameBuffer()
//{
//	fb = fopen("/dev/graphics/fb0", "rb");
//	//FILE* fb = fopen("test.raw", "rb");
//	fread(fb_buffer, FB_SIZE, 1, fb);
//	fclose(fb);
//}

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

void ConvertScanlineFrom565To888(int line_num)
{
	int pos16 = line_num * WIDTH * 4;
	for (int pos24 = 0; pos24 < (WIDTH * 3); pos24 += 3, pos16 += 4) 
	{
		//scanline[pos24+0] = fb_buffer[pos16+1] & 248;
		//scanline[pos24+1] = ((fb_buffer[pos16+1] & 7) << 5) | ((fb_buffer[pos16] & 224) >> 3);
		//scanline[pos24+2] = fb_buffer[pos16] << 3;
		scanline[pos24+0] = fb_buffer[pos16+0] ;
		scanline[pos24+1] = fb_buffer[pos16+1] ; 
		scanline[pos24+2] = fb_buffer[pos16+2];
	}
}

void ConvertFrameBufferToJpeg(jpeg_compress_struct *cinfo)
{
	JSAMPROW row_pointer[1];	/* pointer to a single row */
	row_pointer[0] = scanline;

	jpeg_start_compress(cinfo, TRUE);

	while (cinfo->next_scanline < cinfo->image_height)
	{
		ConvertScanlineFrom565To888(cinfo->next_scanline);
	    jpeg_write_scanlines(cinfo, row_pointer, 1);
	}

	jpeg_finish_compress(cinfo);
}

int main(int argc, char* argv[])
{
	if (argc != 5)
	{
		fprintf(stderr, "Usage: CameraSend <Hostname> <Port> <QualityLevel> <SleepMilliseconds>");
		return 1;
	}

	char *host = argv[1];
	char *port = argv[2];

	int quality;
	sscanf(argv[3], "%d", &quality);

	int sleep_time;
	sscanf(argv[4], "%d", &sleep_time);
	
	fb_buffer = new BYTE[FB_SIZE];
	scanline = new BYTE[WIDTH * 3];

	struct jpeg_compress_struct cinfo;
	struct jpeg_error_mgr jerr;
	cinfo.err = jpeg_std_error(&jerr);
	jpeg_create_compress(&cinfo);

	cinfo.image_width = WIDTH;
	cinfo.image_height = HEIGHT;
	cinfo.in_color_space = JCS_RGB;
	cinfo.input_components = 3;
	

	jpeg_set_defaults(&cinfo);
	jpeg_set_colorspace(&cinfo,JCS_RGB);
	jpeg_set_quality(&cinfo, quality, TRUE);
	cinfo.dct_method = JDCT_FASTEST;

	fb = fopen("/dev/graphics/fb0", "rb");

	MakeNetworkConnection(host, port);

	while (1)
	{
		// Read from the framebuffer
		fread(fb_buffer, FB_SIZE, 1, fb);
		fseek(fb, 0, SEEK_SET);

		jpeg_mem_dest(&cinfo, &img_buffer, &img_size);
		ConvertFrameBufferToJpeg(&cinfo);

		if (argc > 1)
		{
			fprintf(stderr, "%d\n", img_size);
		}

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

		/*free(img_buffer);
		img_buffer = NULL;
		img_size = 0;*/

		usleep(sleep_time);
	}
}

