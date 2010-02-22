// Controller Dead Zone
#define DEAD_ZONE 10

typedef struct {
  long timestamp;
  
  uint8_t X;
  uint8_t C;
  uint8_t T; 
  uint8_t S;
  uint8_t L1;
  uint8_t L2;
  uint8_t L3;
  uint8_t R1;
  uint8_t R2;
  uint8_t R3;
  uint8_t Select;
  uint8_t Start;
  uint8_t Up;
  uint8_t Down;
  uint8_t Left;
  uint8_t Right;
  
  char LeftX;
  char LeftY;
  char RightX;
  char RightY;
} Controller;
