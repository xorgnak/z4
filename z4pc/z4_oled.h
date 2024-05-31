
#define OLED_ROWS 7

class OOO {
  public:
  OOO();
  void setup();
  void display(int f);
  void print(int x, int y, int f, char * text);
  void clear(int f);
  void box(int f);
  char * line[OLED_ROWS];
} oled;

OOO::OOO() {}

void OOO::setup() {
  int rc = oledInit(&_oled, OLED_128x64, 0x3c, FLIPPED, INVERTED, HARDWARE_I2C, SDA_PIN, SCL_PIN, RESET_PIN, 1000000L);
  if (rc != OLED_NOT_FOUND) {
    oledFill(&_oled, 0,1);
    oledSetContrast(&_oled, 255);
    oledWriteString(&_oled, 0,0,0,(char *)"+-------------------+", FONT_6x8, 0, 1);
    oledWriteString(&_oled, 0,0,1,(char *)"|                   |", FONT_6x8, 0, 1);
    oledWriteString(&_oled, 0,0,2,(char *)"|   ___(=^.^=) z4   |", FONT_6x8, 0, 1);
    oledWriteString(&_oled, 0,0,3,(char *)"|                   |", FONT_6x8, 0, 1);
    oledWriteString(&_oled, 0,0,4,(char *)"|                   |", FONT_6x8, 0, 1);
    oledWriteString(&_oled, 0,0,5,(char *)"|  for many things  |", FONT_6x8, 0, 1);
    oledWriteString(&_oled, 0,0,6,(char *)"|                   |", FONT_6x8, 0, 1);
    oledWriteString(&_oled, 0,0,7,(char *)"+-------------------+", FONT_6x8, 0, 1);    
  }
}

void OOO::display(int f) {
  for (int i = 0; i <= OLED_ROWS; i++) {
    oledWriteString(&_oled, 0,0,i, oled.line[i], FONT_6x8, f, 1);
  }
}

void OOO::print(int x, int y, int f, char * text) {
  oledWriteString(&_oled,0,6 * x,y,text, FONT_6x8, f, 1);
}

void OOO::clear(int f) {
  for (int i = 0; i <= OLED_ROWS; i++) {
    oledWriteString(&_oled, 0,0,i,(char *)"                     ", FONT_6x8, f, 1);
  }
}

void OOO::box(int f) {
  oledWriteString(&_oled, 0,0,0,(char *)"+-------------------+", FONT_6x8, f, 1);
  for (int i = 1; i <= (OLED_ROWS - 1); i++) {
    oledWriteString(&_oled, 0,0,i,(char *)"|                   |", FONT_6x8, f, 1);
  }  
  oledWriteString(&_oled, 0,0,7,(char *)"+-------------------+", FONT_6x8, f, 1);
}
