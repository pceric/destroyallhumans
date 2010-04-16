

typedef struct
{
    int luma;
	int cb;
    int cr;
    int x;
    int y;
}Color;


Color getAvgColor(unsigned char *input_image, int width, int height);
Color getBlockAvg(unsigned char *input_image, int width, int height,int x,int y);
int getBestBlock( unsigned char *input_image, int width, int height, int u, int v, int tolarance);
