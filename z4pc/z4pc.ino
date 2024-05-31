SET_LOOP_TASK_STACK_SIZE(1024 * 8); // 8KB
#define LUA_EXTRASPACE 1024*2
#define LUAI_MAXSTACK 1024*4
#include <LuaWrapper.h>
LuaWrapper lua;
#include <FS.h>
#include <LittleFS.h>
#define LED_BUILTIN 35
#include <WiFi.h>
#include <AsyncTCP.h>
#include "ESPAsyncWebSrv.h"
AsyncWebServer server(80);
AsyncEventSource events("/es");
#include <PicoMQTT.h>
PicoMQTT::Client mqtt("propedicab.com");
#include "time.h"
#include "sntp.h"

#define NUM_LEDS_A 8
#define NUM_LEDS_B 8
#define NUM_LEDS_C 8
#define LEDS_PIN_A 36
#define LEDS_PIN_B 34
#define LEDS_PIN_C 33
#include <FastLED.h>
CRGB ledsA[NUM_LEDS_A];
CRGB ledsB[NUM_LEDS_B];
CRGB ledsC[NUM_LEDS_C];

using namespace std;
#include <iostream>
#include <vector>
// at constructs
vector<int> at_time;
vector<String> at_macro;

#define BTN_PIN 0
#include <HotButton.h>
HotButton myButton(BTN_PIN);

#include <ToneESP32.h>
#define BUZZER_PIN 19
#define BUZZER_CHANNEL 0
ToneESP32 buzzer(BUZZER_PIN, BUZZER_CHANNEL);

#define IR_PIN 37
#include <IRremoteESP8266.h>
#include <IRrecv.h>
#include <IRutils.h>
IRrecv irrecv(IR_PIN);
decode_results results;


// BEGIN OLED
#include <ss_oled.h>
#define SDA_PIN 17
#define SCL_PIN 18
#define RESET_PIN 21
#define FLIPPED 1 // 0=RST down
#define INVERTED 0
// Use bit banging to get higher speed output
#define HARDWARE_I2C 0
#define WIDTH 128
#define HEIGHT 64
SSOLED _oled;
// END OLED

// BEGIN LORA
#define PAUSE               300
#define FREQUENCY           915.0
#define BANDWIDTH           250.0
#define SPREADING_FACTOR    9
#define TRANSMIT_POWER      0

//#define SS GPIO_NUM_8
//#define MOSI GPIO_NUM_10
//#define MISO GPIO_NUM_11
//#define SCK GPIO_NUM_9

#define SS_LoRa GPIO_NUM_8
#define MOSI_LoRa GPIO_NUM_10
#define MISO_LoRa GPIO_NUM_11
#define SCK_LoRa GPIO_NUM_9
#define DIO1 GPIO_NUM_14
#define RST_LoRa GPIO_NUM_12
#define BUSY_LoRa GPIO_NUM_13

String rxdata;
volatile bool rxFlag = false;
long counter = 0;
uint64_t last_tx = 0;
uint64_t tx_time;
uint64_t minimum_pause;

#include <SPI.h>
#include <RadioLib.h>
SPIClass* hspi = new SPIClass(HSPI);
SX1262 radio = new Module(SS_LoRa, DIO1, RST_LoRa, BUSY_LoRa, *hspi);

void rx() {
  rxFlag = true;
}
// END LORA

#include "z4.h"

void z4_setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(115200);
  while (!Serial) {}
  Serial.println();                               // always a good idea.

  for (int i = 0; i < 17; i = i + 8) {
    z4.chip |= ((ESP.getEfuseMac() >> (40 - i)) & 0xff) << i;
  }

  FastLED.addLeds<NEOPIXEL, LEDS_PIN_A>(ledsA, NUM_LEDS_A);
  FastLED.addLeds<NEOPIXEL, LEDS_PIN_B>(ledsB, NUM_LEDS_B);
  FastLED.addLeds<NEOPIXEL, LEDS_PIN_C>(ledsC, NUM_LEDS_C);
  FastLED.setBrightness(255);
  
  server.on("/", HTTP_GET, [](AsyncWebServerRequest *request){
    if (request->hasParam("i")) {
       String s = request->getParam("i")->value();
       z4.eval(s);
       request->send(201);

    } else {
      z4.exec("/index");
      String ss = String("<a href='https://propedicab.com/?net=") + z4.net + String("&dev=") + z4.dev + String("'>HOME</a>");
      String s = String(z4_index_head) + String("<h1 style='width: 100%; text-align: left;'>") + z4.buttons + ss + String("</h1>") + String(z4_index_term) + String(z4_index_tail);
      request->send(200, "text/html", s);
    }
  });

  events.onConnect([](AsyncEventSourceClient *client){
    client->send("--+---[<span style='color: gold;'>z4</span>]",NULL,millis(),1000);
  });
  
  server.addHandler(&events);
  
  sprintf(vm.buf, "\n\n--| [z4] tiny event iot shell\n--| RIP 12/23/2019 ~~(, ,c>\n--| (c) 2024 Free Range LLC.\n");
  vm.output += String(vm.buf);

  if (LittleFS.begin()) {
    sprintf(vm.buf, "--[little] OK\n");    
  } else {
    sprintf(vm.buf, "--[little] FAIL\n");
  }    
  vm.output += String(vm.buf);

  hspi->begin(SCK_LoRa, MISO_LoRa, MOSI_LoRa, SS_LoRa);
  if (radio.begin(FREQUENCY, BANDWIDTH, SPREADING_FACTOR, 5, 0x34, TRANSMIT_POWER, 8) == RADIOLIB_ERR_NONE) {
    radio.setDio1Action(rx);
    radio.startReceive(RADIOLIB_SX126X_RX_TIMEOUT_INF);
    sprintf(vm.buf, "--[LoRa] %.2fMHz\n", FREQUENCY);    
  } else {
    sprintf(vm.buf, "--[LoRa] FAIL\n");
  }

  vm.output += String(vm.buf);

  irrecv.enableIRIn();

  oled.setup();

  //  WiFi.onEvent(WiFiEvent);
  sprintf(vm.buf , "Z4%0X", String(z4.chip, HEX));
  
  z4.id = String(vm.buf);
  z4.net = z4.id;
  z4.dev = z4.id;
  
  lua.Lua_register("z4", (const lua_CFunction) &lua_wrapper_z4);

  vm.buffer = String(lua_z4_go);
  z4.eval(vm.buffer);
  
  vm.buffer = String(lua_z4_p);
  z4.eval(vm.buffer);

  vm.buffer = String(lua_z4_on);
  z4.eval(vm.buffer);

  vm.buffer = String(lua_z4_roll);
  z4.eval(vm.buffer);

  vm.buffer = String(lua_z4_pipe);
  z4.eval(vm.buffer);  

  String ss;
  File file;

  file = LittleFS.open("/ok", "r");
  ss = file.readString();
  file.close();
  lua.Lua_dostring(&ss);

  vm.buffer = String("");

  WiFi.setHostname(z4.dev.c_str());
  WiFi.disconnect(false);

  file = LittleFS.open("/net", "r");
  ss = file.readString();
  file.close();
  
  if (ss.length() > 0) {
    lua.Lua_dostring(&ss);
  } else {
    if (WiFi.softAP(z4.dev.c_str())) {
      server.begin();
      String ii = WiFi.softAPIP().toString();
      sprintf(vm.buf, "--[OP] %s %s\n", z4.dev.c_str(), ii.c_str());
      vm.output += String(vm.buf);
    }
  }
  
  file = LittleFS.open("/mud", "r");
  ss = file.readString();
  file.close();
  
  if (ss.length() > 0) {
    lua.Lua_dostring(&ss);
  }

  sntp_set_time_sync_notification_cb( timeavailable );
  sntp_servermode_dhcp(1);
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer1, ntpServer2);
  
  
  z4.timer = true;
  z4.debug = true;
  z4.trace = true; 

  Serial.println(z4.output());                    // print info or not.
}

class UI
{
  public:
    UI() {}
    long last;
    String code;
    String prev;
} ui;

void z4_loop() {
  z4.now = millis();
  sprintf(vm.buf, "");  
  myButton.update();

  if (myButton.isDoubleClick()) {
    z4.exec("/btn/2");
  }

  if (myButton.isTripleClick()) {
    z4.exec("/btn/3");
  }

  if (myButton.isQuadrupleClick()) {
    z4.exec("/btn/4");
  }
  
  if (myButton.event(UNDER(250))) {
    z4.exec("/btn/1");
  }

  if (myButton.event(OVER(250))) {
    z4.exec("/btn/X");
  }

  if (irrecv.decode(&results)) {
    String _ir = String(results.value, HEX);
    irrecv.resume();
    if (_ir.length() == 6 && _ir != String("ffffffffffffffff")) {
      ui.last = z4.now;
      ui.prev = ui.code;
      ui.code = _ir;
      sprintf(vm.buf, "/code/%s", ui.code.c_str());
      if (ui.prev.length() > 0) {
        sprintf(vm.buf, "/seq/%s", ui.prev.c_str());
        String pv = String(vm.buf);
        z4.exec(pv.c_str());        
      }
      String ev = String(vm.buf);
      z4.exec(ev.c_str());
      sprintf(vm.buf, "");
    } else if (_ir == String("ffffffffffffffff")) {
      z4.exec("/zap");
    }
  }
  if (z4.now - ui.last > 750) {
    ui.prev = String("");
    ui.code = String("");
  }

  // eval each line as available.
  while (Serial.available()) {
    z4.eval(Serial.readStringUntil('\n'));
  }

  if (at_time.size() > 0) {
    if (z4.now >= at_time.front()) {
      z4.eval(at_macro.front());
      at_time.erase(at_time.begin());
      at_macro.erase(at_macro.begin());
    }
  }

  lora.loop();
  
  pc.loop();
  
  if (vm.branch.length() > 0) {    
    z4.eval(vm.branch);    
    vm.branch = String("");
  }
  
  if (z4.now - z4.last > z4.delay) {
    if (vm.count <= vm.times) {
      z4.last = z4.now;
      z4.poll();
      vm.count += 1;
    }
  }

  eyes.loop();

  // do something with the output
  if (z4.available()) {
    Serial.println(z4.output());
    //z4.output();
  }

  if (z4.emit.length() > 0) {
    if (lora.legal()) {
      sprintf(vm.buf, "BEGIN %s %s %s END", z4.net.c_str(), z4.dev.c_str(), z4.emit.c_str());
      String ss = String(vm.buf);
      radio.clearDio1Action();
      tx_time = millis();
      if (radio.transmit(ss.c_str()) == RADIOLIB_ERR_NONE) {
        sprintf(vm.buf,"--[LoRa] %s\n", ss.c_str());
        z4.emit = String("");
      } else {
        sprintf(vm.buf,"--[LoRa] fail\n");
      }
      vm.output += String(vm.buf);
      tx_time = millis() - tx_time;
      minimum_pause = tx_time * 100; // Maximum 1% duty cycle
      last_tx = millis();
      radio.setDio1Action(rx);
      radio.startReceive(RADIOLIB_SX126X_RX_TIMEOUT_INF);    
    }    
  }

}

// Arduino Example
void setup() {
  z4_setup();
}
void loop() {
  z4_loop();
}
