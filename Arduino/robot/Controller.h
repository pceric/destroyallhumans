// Controller Dead Zone
#define DEAD_ZONE 10

typedef struct {
  long timestamp;
  
  char X;
  char C;
  char T; 
  char S;
  char L1;
  char L2;
  char L3;
  char R1;
  char R2;
  char R3;
  char Select;
  char Start;
  char Up;
  char Down;
  char Left;
  char Right;
  
  char LeftX;
  char LeftY;
  char RightX;
  char RightY;
} Controller;
