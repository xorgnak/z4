#ifndef Z4_h
#define Z4_h

#include <Arduino.h>

#include "z4_config.h"

String ssid = "";
String pass = "";
int net_state = 0;
uint32_t net_last = 0;
uint32_t net_last_try = 0;
uint32_t net_try_delay = 30000;
bool net_scanning = false;
bool net_connecting = false;
bool net_connected = false;
bool net_mqtt_connecting = false;
String ifip4 = "";
String ifip6 = "";
String apip = "";

int net_delay = 5000;
bool net_op = false;
uint16_t net_op_lvl = 0;
bool eval_trusted = true;
bool retain = false;
String z4_ui_buffer = "";
String z4_ui_input = "";
uint32_t z4_ui_click_now = 0;
uint32_t z4_ui_xy_now = 0;

String irCmd = "";
uint32_t irCmd_last = 0;

#define BUZZER_CHANNEL 0
#define BEAT 250

// ui
//#define Z4_UI_CENTER (Z4_UI_MAX / 2)
//#define Z4_UI_X_LIM_DN Z4_UI_CENTER - Z4_UI_DRIFT
//#define Z4_UI_X_LIM_UP Z4_UI_CENTER + Z4_UI_DRIFT
//#define Z4_UI_Y_LIM_DN Z4_UI_CENTER - Z4_UI_DRIFT
//#define Z4_UI_Y_LIM_UP Z4_UI_CENTER + Z4_UI_DRIFT

SET_LOOP_TASK_STACK_SIZE(1024 * 16); // 16KB
#define LUA_EXTRASPACE 1024*16 // 16KB
#define LUAI_MAXSTACK 1024*32 // 32KB

char buf[1024];

#include <DNSServer.h>
#include <IRremoteESP8266.h>
#include <IRrecv.h>
#include <IRutils.h>
#include <WiFi.h>
#include <MQTT.h>
//#include <WiFiMulti.h>
#include <WiFiClient.h>
#include <Esp.h>
#include <iostream>
#include <vector>
#include <LuaWrapper.h>
#include <FS.h>
#include <LittleFS.h>
//#include <Adafruit_Sensor.h>
#include <DHT.h>
//#include <DHT_U.h>
#include <ToneESP32.h>
#include <analogWrite.h>
#include "Wire.h"
#include <MPU6050_light.h>
#include "lua.h"

using namespace std;

bool fnd = false;

bool z4_output = false;

uint8_t cmd = 0;
uint8_t pkt = 0;

vector<int> at_time;
vector<int> at_mode;
vector<String> at_macro;
IRrecv irrecv(PIN_IR_IN);
decode_results results;
#if defined(Z4_BEEP)
ToneESP32 buzzer(BUZZER_PIN, BUZZER_CHANNEL);
#endif
WiFiClient client;
MQTTClient mqtt;
#if defined(Z4_GYRO)
float gyro_temp = 0;
float gyro_accl_x = 0;
float gyro_accl_y = 0;
float gyro_accl_z = 0;
float gyro_x = 0;
float gyro_y  = 0;
float gyro_z = 0;
float gyro_accl_angle_x = 0;
float gyro_accl_angle_y = 0;
//float gyro_angle_z = 0;
float gyro_angle_x = 0;
float gyro_angle_y = 0;
float gyro_angle_z = 0;

MPU6050 mpu(Wire);
#endif
LuaWrapper lua;

IPAddress ip;
uint16_t  port = 23;
DNSServer dnsServer;

#if defined(Z4_TEMP)
float dht_f = 0;
float dht_c = 0;
float dht_hi_f = 0;
float dht_hi_c = 0;
float dht_h = 0;
DHT dht(DHTPIN, DHTTYPE);
#endif

uint32_t now;

uint32_t zap_last = 0;
uint16_t zap_wait = 0;

//uint32_t hall;
uint32_t was = 0;
uint32_t took = 0;
uint32_t seed = 0;

String buf_in = "";
String buf_out = "";
String buf_tmp = "";
String buf_hist = "";
String buf_eval = "";
String devId;
String nickId = "";
String netId;
String _devId;
String _netId;
String mqttInId;
String mqttOutId;
String userId;
String passId;

String mqttBroker = "propedicab.com";

bool blink_state = false;
bool blink_update = false;
bool blink_wait = false;
int blink_till = 0;


//int z4_mud_status = 0;
//int z4_mud_lvl = 0;
//int z4_mud_xp = 0;
//int z4_mud_gp = 0;
//int z4_mud_hp = 0;
//int z4_mud_ac = 0;
//String z4_mud_here = "mobile";
//String z4_mud_name = devId;
//String z4_mud_doing = "";

class Z4
{
  public:
    Z4();
    void begin(bool ret);
    void loop();
    void input(String i);
    void eval(String s);
    void exec(const char * ev);
    String readString();
    void flush();
    String dev();
    String net();
    bool available();
    void blink(int dur);
    bool state();
    void on();
    void off();
#if defined(Z4_LEDS)
    void tick();
#endif
#if defined(Z4_LORA)
    void lora(String p);
#endif
#if defined(Z4_TIME)
    void date();
#endif
} z4;

bool Z4::state() {
  return(digitalRead(LED_BUILTIN));
}

void Z4::blink(int dur) {
  blink_state = true;
  blink_till = now + dur;
  blink_update = true;
}

void Z4::on() {
  digitalWrite(LED_BUILTIN, HIGH);
  blink_update = false;
}

void Z4::off() {
  digitalWrite(LED_BUILTIN, LOW);
  blink_update = false;
}

#if defined(Z4_TIME)
#include "z4_time.h"
#endif

#if defined(Z4_LEDS)
#include "z4_leds.h"
#endif

#if defined(Z4_LORA)
#include "z4_lora.h"
#endif

#if defined(Z4_OLED)
#include "z4_oled.h"
#endif

void setupIds() {
  char a[64];
  sprintf(a, "%s/", devId.c_str());
  mqttInId = String(a);
  sprintf(a, "%s/%s", netId.c_str(), devId.c_str());
  mqttOutId = String(a);
}


String formatBytes(size_t bytes) {
  if (bytes < 1024) {
    if (bytes < 10) {
      return "  " + String(bytes) + "B ";
    } else if (bytes < 100) {
      return " " + String(bytes) + "B ";
    } else {
      return String(bytes) + "B ";
    }
  } else if (bytes < (1024 * 1024)) {
    return String(bytes / 1024.0) + "KB";
  } else if (bytes < (1024 * 1024 * 1024)) {
    return String(bytes / 1024.0 / 1024.0) + "MB";
  } else {
    return String(bytes / 1024.0 / 1024.0 / 1024.0) + "GB";
  }
}

void messageReceived(String &topic, String &payload) {
  if (topic == netId) {
    pkt = 2;
    if (net_op == false) {
      buf_in += payload;
    }
  }
  if (topic == devId) {
    pkt = 6;
    sprintf(buf, "--[mqtt][!][%s] %s\n", topic.c_str(), payload.c_str());
  } else if (topic == mqttInId) {
    pkt = 5;
    sprintf(buf, "--[mqtt][<][%s] %s\n", topic.c_str(), payload.c_str());
  } else if (topic == mqttOutId) {
    pkt = 4;
    sprintf(buf, "--[mqtt][>][%s] %s\n", topic.c_str(), payload.c_str());
  } else {
    pkt = 3;
    sprintf(buf, "--[mqtt][#][%s] %s\n", topic.c_str(), payload.c_str());
  }
  buf_out += String(buf);
  z4.exec("/mqtt");
}

void wifi_loop() {
  // check mqtt first
  mqtt.loop();

  // reset network if disconnected
  if (WiFi.status() != WL_CONNECTED) {
    net_connected = false;
  }

  if (net_state == 2 && net_connecting == true && net_connected == false) {
    if (now - net_last_try >= net_try_delay) {
      net_state = 3;
    }
  }
  // IF scanning? scan.
  if (net_scanning == true && net_state == 3 || net_state == 4) {
    if (now - net_last >= net_delay) {
      net_last = now;
      fnd = false;
      int n = WiFi.scanNetworks();
      if (n > 0) {
        for (int i = 0; i < n; ++i) {
          if (WiFi.SSID(i) == ssid.c_str()) {
            fnd = true;
          }
          if (WiFi.RSSI(i) >= -90) {
            sprintf(buf, "--[NM][%i][%i][%i] %s\n", i, WiFi.encryptionType(i), WiFi.RSSI(i), WiFi.SSID(i));
            buf_out += String(buf);
          }
        }
      }
      // IF found? connect.
      if (net_state == 3 && fnd == true) {
        net_state = 2;
        net_scanning = false;
      }
      sprintf(buf, "--[NM][%i][%s][%i] %i\n", net_state, ssid.c_str(), fnd, n);
      buf_out += String(buf);
    }
  }
  // IF connect?
  if (net_state == 2) {
    // IF NOT connecting? && connected? && scanning? begin!
    if (net_connecting == false && net_connected == false && net_scanning == false) {
      net_last_try = now;
      WiFi.mode(WIFI_STA);
      WiFi.begin(ssid.c_str(), pass.c_str());
      net_connecting = true;
    }
    // wait...
    if (WiFi.waitForConnectResult() == WL_CONNECTED) {
      // IF connected. && NOT mqtt_connecting? && NOT mqtt_connected?
      if (net_connected == true && net_mqtt_connecting == false && mqtt.connected() == false) {
        net_mqtt_connecting = true;
        mqtt.connect(devId.c_str(), userId.c_str(), passId.c_str());
      }
      // IF mqtt_connecting? && mqtt_connected?
      if (net_mqtt_connecting == true && mqtt.connected() == true) {
        net_mqtt_connecting = false;
        // IF OP
        if (net_op == true) {
          //          sprintf(buf, "#", netId.c_str());
          //          String s = String(buf);
          mqtt.subscribe("#");
        } else {
          mqtt.subscribe(netId.c_str());
        }

        pkt = 2;
        z4.exec("/connected");
      }
    }
  }
}

// WIFI EVENTS
void WiFiEvent(WiFiEvent_t event)
{
  String txt = "event";
  switch (event) {
    case ARDUINO_EVENT_WIFI_AP_START:
      txt = String("AP START");
      //can set ap hostname here
      WiFi.softAPsetHostname(devId.c_str());
      //enable ap ipv6 here
      WiFi.softAPenableIpV6();
      break;

    case ARDUINO_EVENT_WIFI_STA_START:
      txt = String("START");
      WiFi.setHostname(devId.c_str());
      WiFi.enableIpV6();
      break;

    case ARDUINO_EVENT_WIFI_STA_CONNECTED:
      txt = String("CONNECTED");
      //enable sta ipv6 here
      
      break;

    case ARDUINO_EVENT_WIFI_READY:
      txt = String("READY");
      break;
    case ARDUINO_EVENT_WIFI_SCAN_DONE:
      txt = String("SCAN DONE");
      break;
    case ARDUINO_EVENT_WIFI_STA_STOP:
      txt = String("STOP");
      break;
    case ARDUINO_EVENT_WIFI_STA_DISCONNECTED:
      txt = String("DISCONNECTED");
      net_connected = false;
      break;
    case ARDUINO_EVENT_WIFI_STA_AUTHMODE_CHANGE:
      txt = String("CHANGE");
      break;
    case ARDUINO_EVENT_WIFI_STA_GOT_IP:
      ifip4 = WiFi.localIP().toString();
      //      net_connecting = false;
      //      net_connected = true;
      txt = String("GOT IP4");
      sprintf(buf, "--[nm][ip4] %s\n", ifip4.c_str());
      buf_out += String(buf);
      break;
    case ARDUINO_EVENT_WIFI_STA_GOT_IP6:
      ifip6 = WiFi.localIPv6().toString();
      //      net_connecting = false;
      //      net_connected = true;
      txt = String("GOT IP6");
      sprintf(buf, "--[nm][ip6] %s\n", ifip6.c_str());
      buf_out += String(buf);
      break;
    case ARDUINO_EVENT_WIFI_STA_LOST_IP:
      txt = String("LOST IP");
      net_connected = false;
      z4.exec("/disconnected");
      break;
    case ARDUINO_EVENT_WIFI_AP_STOP:
      txt = String("AP STOP");
      break;
    case ARDUINO_EVENT_WIFI_AP_STACONNECTED:
      txt = String("AP CONNECTED");
      break;
    case ARDUINO_EVENT_WIFI_AP_STADISCONNECTED:
      txt = String("AP DISCONNECTED");
      break;
    case ARDUINO_EVENT_WIFI_AP_STAIPASSIGNED:
      txt = String("AP IP ASSIGNED");
      break;
    case ARDUINO_EVENT_WIFI_AP_PROBEREQRECVED:
      txt = String("AP PROBE");
      break;
    case ARDUINO_EVENT_WIFI_AP_GOT_IP6:
      apip = WiFi.softAPIPv6().toString();
      txt = String("AP GOT IP6");
      sprintf(buf, "--[nm][AP] %s\n", apip.c_str());
      buf_out += String(buf);
      break;
    default: break;
  }
  pkt = 4;
  sprintf(buf, "--[WIFI][%d] %s\n", event, txt.c_str());
  buf_out += String(buf);
}

//
// LUA CORE
//

// AT

static int lua_wrapper_at(lua_State *lua_state) {
  // do at time;
  int t = luaL_checknumber(lua_state, 1);
  const char * p = luaL_checkstring(lua_state, 2);
  uint32_t at = now + t;
  at_time.push_back(at);
  char buf[256];
  sprintf(buf, "%s", p);
  at_macro.push_back(String(buf));
  sprintf(buf, "--[at][%u] %s\n", at, p);
  cmd = 1;
  buf_out += String(buf);
  return 0;
}

// IO

static int lua_wrapper_io(lua_State * lua_state) {
  int m = luaL_checknumber(lua_state, 1);
  cmd = 2;
  const char * f = luaL_checkstring(lua_state, 2);
  if (m == 0) {
    buf_tmp = String(f);
    lua_pushstring(lua_state, buf_tmp.c_str());
  } else if (m == 1) {
    buf_out += String(f);
    lua_pushstring(lua_state, buf_out.c_str());
  } else if (m == 2) {
    mqtt.publish(f, buf_tmp);
    z4.exec("/sent");
#if defined(Z4_LORA)
  } else if (m == 3) {
    sprintf(buf, "--%s\n%s\n", f, buf_tmp.c_str());
    String s = String(buf);
    z4.lora(s);
    z4.exec("/beacon");
  } else if (m == 4) {
    lora_beacon = String(f);
    //    z4.exec("/beacons/set");
    //    lua_pushstring(lua_state, lora_beacon.c_str());
#endif
  } else if (m == 11) {
    z4.eval(String(f));
  } else if (m == 12) {
    buf_out += buf_hist;
  } else if (m == 13) {
    buf_in += buf_hist;
  } else if (m == 14) {
    buf_eval += String(f);
  } else if (m == 15) {
    buf_in += String(f);
  } else {
    sprintf(buf, "--%s\n%s\n", f, buf_tmp.c_str());
    buf_out += String(buf);
  }
  return 0;
}

// EV

static int lua_wrapper_ev(lua_State * lua_state) {
  int r = 0;
  int m = luaL_checknumber(lua_state, 1);
  const char * f = luaL_checkstring(lua_state, 2);
  if (f == "/setup" || f == "/hi") {
    if (net_op == false && eval_trusted == false) {
      buf_out += String("--[Z4] access forbidden.\n");
      return -1;
    }
  }
  
  cmd = 3;
  if (m == 8) {
    File root = LittleFS.open(f);
    time_t r = root.getLastWrite();
    struct tm * rr = localtime(&r);
    File file = root.openNextFile();
    String ff = file.name();
    while (file) {
      time_t t = file.getLastWrite();
      struct tm * tmstruct = localtime(&t);
      if (!file.isDirectory()) {
        LittleFS.remove(ff.c_str());
      }
      file = root.openNextFile();
    }
    LittleFS.rmdir(f); 
  } else if (m == 7) {
    // delete dir
    LittleFS.rmdir(f);
  } else if (m == 6) {
    // delete file
    LittleFS.remove(f);
  } else if (m == 0) {
    // read file
    File file = LittleFS.open(f);
    buf_tmp += file.readString();
    file.close();
  } else if (m == 1) {
    // write file
    File file = LittleFS.open(f, FILE_WRITE);
    file.print(buf_tmp.c_str());
    file.close();
  } else if (m == 2) {
    // append file
    File file = LittleFS.open(f, FILE_APPEND);
    file.print(buf_tmp.c_str());
    file.close();    
  } else if (m == 3) {
    // make dir
    LittleFS.mkdir(f);
  } else if (m == 4) {
    const char * t = luaL_checkstring(lua_state, 3);
    LittleFS.rename(f, t);
  } else if (m == 5) {
    z4.exec(f);
  } else {
    int bytes = 0;
    File root = LittleFS.open(f);
    time_t r = root.getLastWrite();
    struct tm * rr = localtime(&r);
    sprintf(buf, "[R] %d-%02d-%02d %02d:%02d:%02d ===== %s\n", (rr->tm_year) + 1900, ( rr->tm_mon) + 1, rr->tm_mday, rr->tm_hour , rr->tm_min, rr->tm_sec, f);
    buf_out += String(buf);
    File file = root.openNextFile();
    while (file) {
      time_t t = file.getLastWrite();
      struct tm * tmstruct = localtime(&t);
      if (file.isDirectory()) {
        sprintf(buf, "[C] %d-%02d-%02d %02d:%02d:%02d ----- %s\n", (tmstruct->tm_year) + 1900, ( tmstruct->tm_mon) + 1, tmstruct->tm_mday, tmstruct->tm_hour , tmstruct->tm_min, tmstruct->tm_sec, file.name());
      } else {
        bytes += file.size();
        sprintf(buf, "[E] %d-%02d-%02d %02d:%02d:%02d %s %s\n", (tmstruct->tm_year) + 1900, ( tmstruct->tm_mon) + 1, tmstruct->tm_mday, tmstruct->tm_hour , tmstruct->tm_min, tmstruct->tm_sec, formatBytes(file.size()), file.name());
        lua_pushstring(lua_state, file.name());
      }
      buf_out += String(buf);
      file = root.openNextFile();
    }
    sprintf(buf, "--[ls] %s\n", formatBytes(bytes));
    buf_out += String(buf);
    r = bytes;
  }
  return 0;
}

// NM

static int lua_wrapper_nm(lua_State * lua_state) {
  cmd = 4;
  net_state = luaL_checknumber(lua_state, 1);

  if (net_state == 5) {
    const char * s = luaL_checkstring(lua_state, 2);
    const char * p = luaL_checkstring(lua_state, 3);
    WiFi.mode(WIFI_AP);
    WiFi.softAP(s, p);
    apip = WiFi.softAPIP().toString();
    buf_out += String("--[nm][-2] ap up.\n");
  } else if (net_state == 3 || net_state == 4) {
    net_scanning = true;
    buf_out += String("--[nm]_[-1] scanning...\n");
  } else if (net_state == 0) {
    buf_out += String("--[nm][0] disconnecting...\n");
    WiFi.disconnect();
  } else if (net_state == 1) {
    const char * s = luaL_checkstring(lua_state, 2);
    const char * p = luaL_checkstring(lua_state, 3);
    ssid = String(s);
    pass = String(p);
    buf_out += String("--[nm][1] credentials set...\n");
  } else if (net_state == 2) {
    buf_out += String("--[nm][2] connecting...\n");
  }
  return 0;
}

static int lua_wrapper_ok(lua_State * lua_state) {
  ESP.restart();
  return 0;
}

// PM

static int lua_wrapper_pm(lua_State * lua_state) {
  int m = luaL_checkinteger(lua_state, 1);
  if (m == 0) {
    int a = luaL_checkinteger(lua_state, 2);
    int b = luaL_checkinteger(lua_state, 3);
    if (b > 0) {
      pinMode(a, INPUT);
    } else if (b == 0) {
      pinMode(a, OUTPUT);
    } else if (b < 0) {
      pinMode(a, INPUT_PULLUP);
    }
  } else if (m == 1) {
    int a = luaL_checkinteger(lua_state, 2);
    int b = luaL_checkinteger(lua_state, 3);
    if (b == -2) {
      lua_pushinteger(lua_state, analogRead(a));
    } else if (b == -1) {
      lua_pushinteger(lua_state, digitalRead(a));
    } else if (b == 0) {
      digitalWrite(a, LOW);
    } else if (b == 1) {
      digitalWrite(a, HIGH);
    }
  } else if (m == 2) {
    int p = luaL_checknumber(lua_state, 2);
    int a = luaL_checknumber(lua_state, 3);
    analogServo(p, a);    
  }
  return 0;
}

// TONE
#if defined(Z4_BEEP)
static int lua_wrapper_beep(lua_State * lua_state) {
  int i = (int)luaL_checknumber(lua_state, 1);
  int d = (int)luaL_checknumber(lua_state, 2);
  if (i == 0) {
    buzzer.noTone();
  } else {
    buzzer.tone(i, d * 0.9);
    delay(d * 0.1);
  }
  return 0;
}
#endif

// Z4

static int lua_wrapper_me(lua_State * lua_state) {
  int m = luaL_checknumber(lua_state, 1);
  cmd = 5;
  if (eval_trusted == true && m == 255) {
    net_op = true;
    net_op_lvl = 9;
    sprintf(buf, "--[op] 10\n");
    buf_out += String(buf);
  } else if (eval_trusted == true && m == 254) {
    net_op_lvl = 9;
    sprintf(buf, "--[op] 9\n");
    buf_out += String(buf);
  } else if (eval_trusted == true && m == 253) {
    net_op_lvl = 8;
    sprintf(buf, "--[op] 8\n");
    buf_out += String(buf);
  } else if (eval_trusted == true && m == 252) {
    net_op_lvl = 7;
    sprintf(buf, "--[op] 7\n");
    buf_out += String(buf);
  } else if (eval_trusted == true && m == 251) {
    net_op_lvl = 6;
    sprintf(buf, "--[op] 6\n");
    buf_out += String(buf);
  } else if (eval_trusted == true && m == 250) {
    net_op_lvl = 5;
    sprintf(buf, "--[op] 5\n");
    buf_out += String(buf);
  } else if (eval_trusted == true && m == 249) {
    net_op_lvl = 4;
    sprintf(buf, "[op] 4\n");
    buf_out += String(buf);
  } else if (eval_trusted == true && m == 248) {
    net_op_lvl = 3;
    sprintf(buf, "--[op] 3\n");
    buf_out += String(buf);
  } else if (eval_trusted == true && m == 247) {
    net_op_lvl = 2;
    sprintf(buf, "--[op] 2\n");
    buf_out += String(buf);
  } else if (eval_trusted == true && m == 246) {
    net_op_lvl = 1;
    sprintf(buf, "--[op] 1\n");
    buf_out += String(buf);
  } else if (m == 44) {
    sprintf(buf, "--[44] \n");
    buf_out += String(buf);
  } else if (m == 43) {
    sprintf(buf, "--[43] \n");
    buf_out += String(buf);
  } else if (m == 42) {
    sprintf(buf, "--[42] \n");
    buf_out += String(buf);
  } else if (m == 41) {
#if defined(Z4_GYRO)
    mpu.update();
    gyro_temp = mpu.getTemp();
    gyro_accl_x = mpu.getAccX();
    gyro_accl_y = mpu.getAccY();
    gyro_accl_z = mpu.getAccZ();
    gyro_x = mpu.getGyroX();
    gyro_y = mpu.getGyroY();
    gyro_z = mpu.getGyroZ();
    gyro_accl_angle_x = mpu.getAccAngleX();
    gyro_accl_angle_y = mpu.getAccAngleY();
//    gyro_angle_z = mpu.getAccAngleZ();
    gyro_angle_x = mpu.getAngleX();
    gyro_angle_y = mpu.getAngleY();
    gyro_angle_z = mpu.getAngleZ();
    sprintf(buf, "--[GYRO] accl: %f %f %f\n--[GYRO] %f %f %f\n--[GYRO] accl angle: x: %f, y: %f\n--[GYRO] %f %f %f\n", gyro_accl_x, gyro_accl_y, gyro_accl_z, gyro_x, gyro_y, gyro_z, gyro_accl_angle_x, gyro_accl_angle_y, gyro_angle_x, gyro_angle_y, gyro_angle_z);
#else
      sprintf(buf, "--[40] \n");  
#endif      
      buf_out += String(buf);
  } else if (m == 40) {
#if defined(Z4_TEMP)    
    dht_h = dht.readHumidity();
    dht_c = dht.readTemperature();
    dht_f = dht.readTemperature(true);
    dht_hi_c = dht.computeHeatIndex(dht_c, dht_h, false);
    dht_hi_f = dht.computeHeatIndex(dht_f, dht_h);
    sprintf(buf, "--[WEATHER] temperature: %f°C %f°F\n--[WEATHER] humidity: %f%%\n--[WEATHER] heat index: %f°C %f°F\n", dht_c, dht_f, dht_h, dht_hi_c, dht_hi_f);
#else
      sprintf(buf, "--[40] \n");  
#endif      
      buf_out += String(buf);
  } else if (m == 39) {
    sprintf(buf, "--[39] \n");
    buf_out += String(buf);
  } else if (m == 38) {
    sprintf(buf, "--[38] \n");
    buf_out += String(buf);
  } else if (m == 37) {
    sprintf(buf, "--[37] \n");
    buf_out += String(buf);
  } else if (m == 36) {
    sprintf(buf, "--[36] \n");
    buf_out += String(buf);
  } else if (m == 35) {
    z4.off();
  } else if (m == 34) {
    z4.on();
  } else if (m == 33) {
    sprintf(buf, "--[33] \n");
    buf_out += String(buf);
  } else if (m == 32) {
    sprintf(buf, "--[32] \n");
    buf_out += String(buf);
  } else if (m == 31) {
    sprintf(buf, "--[31] \n");
    buf_out += String(buf);
  } else if (m == 30) {
    sprintf(buf, "--[30] \n");
    buf_out += String(buf);
  } else if (m == 29) {
    sprintf(buf, "--[29] \n");
    buf_out += String(buf);
  } else if (m == 28) {
    sprintf(buf, "--[28] \n");
    buf_out += String(buf);
  } else if (m == 27) {
    sprintf(buf, "--[27] \n");
    buf_out += String(buf);
  } else if (m == 26) {
    sprintf(buf, "--[26] \n");
    buf_out += String(buf);
  } else if (m == 25) {
    sprintf(buf, "--[25] \n");
    buf_out += String(buf);
  } else if (m == 24) {
    sprintf(buf, "--[24] \n");
    buf_out += String(buf);
  } else if (m == 23) {
    sprintf(buf, "--[23] \n");
    buf_out += String(buf);
  } else if (m == 22) {
    sprintf(buf, "--[22] \n");
    buf_out += String(buf);
  } else if (m == 21) {
    sprintf(buf, "--[21] \n");
    buf_out += String(buf);
  } else if (m == 20) {
    sprintf(buf, "--[20] \n");
    buf_out += String(buf);
  } else if (m == 19) {
    sprintf(buf, "--[19] \n");
    buf_out += String(buf);
  } else if (m == 18) {
    sprintf(buf, "--[18] \n");
    buf_out += String(buf);
  } else if (m == 17) {
    sprintf(buf, "--[17] \n");
    buf_out += String(buf);
  } else if (m == 16) {
    sprintf(buf, "--[HELP][spawn] spawn(event, t); => spawn an event from within an event.\n");
    buf_out += String(buf);
  } else if (m == 15) {
    sprintf(buf, "--[HELP][meow] meow(input); => have a cute kitty say your input - with emotion!\n");
    buf_out += String(buf);
  } else if (m == 14) {
    sprintf(buf, "--[HELP][random] random event sources.\ndie(s); => roll one die with s sides.\ndice(n, s); => roll n dice with s sides.\nroll({{n,s}...}); => roll each pair in table as n,s dice pairs.\n");
    buf_out += String(buf);
  } else if (m == 13) {
    sprintf(buf, "--[HELP][t] calculate time offset from miliseconds, seconds, minutes, and hours.\nt(ms, s, m, h); => now + time\n");
    buf_out += String(buf);
  } else if (m == 12) {
    sprintf(buf, "--[HELP][cat] cat(event, [heading]); => display contents of event with optional heading.\n");
    buf_out += String(buf);
  } else if (m == 11) {
    sprintf(buf, "--[HELP][ln] ln(to, from); => link the to event to the from event.\n");
    buf_out += String(buf);
  } else if (m == 10) {
    sprintf(buf, "--[HELP][on] on(event, [script]); => set event to script or trigger event.\n");
    buf_out += String(buf);
  } else if (m == 9) {
    sprintf(buf, "--[LOVE][lua] the interpreter used for this project was lovingly developed by:\n--authors %s\n--release: %s\n--copyright: %s\n", LUA_AUTHORS, LUA_RELEASE, LUA_COPYRIGHT);
    buf_out += String(buf);
    buf_out += String("-----> for more information, visit: https://lua.org\n");
  } else if (m == 8) {
    sprintf(buf, "--[HELP][at] at(t, input); => evaluate input at now + time.\n");
    buf_out += String(buf);
  } else if (m == 7) {
    sprintf(buf, "--[HELP][ev] ev(mode, target); => general event operations.\n--modes:\n8: delete target directory and it's children.\n7: delete target directory.\n6: delete target event.\n0: read target event.\n1: write buffer to target event.\n2: append buffer to target event.\n3: make target directory.\n4: move target event to destination event.\n5: trigger event.\n6: list target events.\n");
    buf_out += String(buf);
  } else if (m == 6) {
    sprintf(buf, "--[HELP][io] io(mode, payload); => general buffer operations.\n--modes:\n0: set buffer to payload.\n1: append payload to output.\n2: publish buffer to payload topic.\n16: finalize buffer for display.\n");
    buf_out += String(buf);
  } else if (m == 5) {
    sprintf(buf, "--[HELP][nm] nm(mode, [ssid], [password]); => general network manager.\n--modes:\n5: start ap with ssid and password.\n4: scan for ssid and connect if found.\n3: scan for ssid.\n0: disconnect network.\n1: add ssid and password to known networks.\n2: connect to known network.\n");
    buf_out += String(buf);
  } else if (m == 4) {
    sprintf(buf, "--[HELP][buffers] the z4 system has three buffers.\n--in: the buffer which holds input to process.\n--pipe: the actively managed buffer.\n--out: processed input results to be displayed.\n");
    buf_out += String(buf);
  } else if (m == 3) {
    sprintf(buf, "--[INFO][MEMORY] free: %s, low: %s, high: %s, size: %s\n", formatBytes(ESP.getFreeHeap()), formatBytes(ESP.getMinFreeHeap()), formatBytes(ESP.getMaxAllocHeap()), formatBytes(ESP.getHeapSize()));
    buf_out += String(buf);
  } else if (m == 2) {
    sprintf(buf, "--[INFO][METAL] %s %u %u cores @ %uMHz\n", ESP.getChipModel(), ESP.getChipRevision(), ESP.getChipCores(), ESP.getCpuFreqMHz());
    buf_out += String(buf);
  } else if (m == 1) {
    sprintf(buf, "--[INFO][SKETCH] %s/%s\n", formatBytes(ESP.getSketchSize()), formatBytes(ESP.getFreeSketchSpace()));
    buf_out += String(buf);
  } else if (m == 0) {
    buf_out += String("--[INFO] Z4 iot device.\n");
    buf_out += String("--[INFO] simple iot interaction.\n");
    buf_out += String("--[INFO] (c) 2023 Free Range Holdings LLC.\n");
  } else {
    buf_out += String("--[INFO][0] project information.\n");
    buf_out += String("--[INFO][1] sketch information.\n");
    buf_out += String("--[INFO][2] chip information.\n");
    buf_out += String("--[INFO][3] memory information.\n");
    buf_out += String("--[INFO][4] buffers.\n");
    buf_out += String("--[INFO][5] the network manager.\n");
    buf_out += String("--[INFO][6] buffer operations.\n");
    buf_out += String("--[INFO][7] event operation.\n");
    buf_out += String("--[INFO][8] the at utility.\n");
    buf_out += String("--[INFO][9] the lua scripting environment.\n");
  }
  return 0;
}

static int lua_wrapper_z4_before(lua_State * lua_state) {
  took = 0;
  lua_pushinteger(lua_state, now);
  lua_setglobal(lua_state, "now");  
  //  lua_pushinteger(lua_state, hall);
  //  lua_setglobal(lua_state, "hall");
#if defined(Z4_TEMP)  
  lua_pushinteger(lua_state, dht_f);
  lua_setglobal(lua_state, "fahrenheit");
  lua_pushinteger(lua_state, dht_c);
  lua_setglobal(lua_state, "celsius");
  lua_pushinteger(lua_state, dht_hi_c);
  lua_setglobal(lua_state, "heatIndexCelsius");
  lua_pushinteger(lua_state, dht_hi_f);
  lua_setglobal(lua_state, "heatIndexFahrenheit");  
  lua_pushinteger(lua_state, dht_h);
  lua_setglobal(lua_state, "humidity");  
#endif

#if defined(Z4_GYRO)  
  lua_pushinteger(lua_state, gyro_accl_x);
  lua_setglobal(lua_state, "acclX");
  lua_pushinteger(lua_state, gyro_accl_y);
  lua_setglobal(lua_state, "acclY");
  lua_pushinteger(lua_state, gyro_accl_z);
  lua_setglobal(lua_state, "acclZ");
  lua_pushinteger(lua_state, gyro_x);
  lua_setglobal(lua_state, "gyroX");
  lua_pushinteger(lua_state, gyro_y);
  lua_setglobal(lua_state, "gyroY");
  lua_pushinteger(lua_state, gyro_z);
  lua_setglobal(lua_state, "gyroZ");  
  lua_pushinteger(lua_state, gyro_angle_x);
  lua_setglobal(lua_state, "angleX");
  lua_pushinteger(lua_state, gyro_angle_y);
  lua_setglobal(lua_state, "angleY");
  lua_pushinteger(lua_state, gyro_angle_z);
  lua_setglobal(lua_state, "acclZ");
  lua_pushinteger(lua_state, gyro_accl_angle_x);
  lua_setglobal(lua_state, "acclAngleX");
  lua_pushinteger(lua_state, gyro_accl_angle_y);
  lua_setglobal(lua_state, "acclAngleY");  
#endif
  
  lua_pushinteger(lua_state, pkt);
  lua_setglobal(lua_state, "pkt");
  lua_pushinteger(lua_state, seed);
  lua_setglobal(lua_state, "seed");
  lua_pushinteger(lua_state, cmd);
  lua_setglobal(lua_state, "cmd");
  lua_pushinteger(lua_state, WiFi.status());
  lua_setglobal(lua_state, "wifi");
  lua_pushinteger(lua_state, LED_BUILTIN);
  lua_setglobal(lua_state, "led");
  lua_pushinteger(lua_state, net_op_lvl);
  lua_setglobal(lua_state, "op");
  lua_pushstring(lua_state, buf_tmp.c_str());
  lua_setglobal(lua_state, "pipe");
  lua_pushstring(lua_state, netId.c_str());
  lua_setglobal(lua_state, "net");
  lua_pushstring(lua_state, devId.c_str());
  lua_setglobal(lua_state, "dev");
  lua_pushstring(lua_state, irCmd.c_str());
  lua_setglobal(lua_state, "cmd");
  lua_pushstring(lua_state, mqttBroker.c_str());
  lua_setglobal(lua_state, "broker");
  lua_pushstring(lua_state, ifip4.c_str());
  lua_setglobal(lua_state, "ip4");
  lua_pushstring(lua_state, ifip6.c_str());
  lua_setglobal(lua_state, "ip6");
  lua_pushstring(lua_state, apip.c_str());
  lua_setglobal(lua_state, "ap");

#if defined(Z4_TIME)
  if (got_time == true) {
  z4.date();
  //time_before(lua_state);
  lua_pushinteger(lua_state, now_Y);
  lua_setglobal(lua_state, "year");
  lua_pushinteger(lua_state, now_M);
  lua_setglobal(lua_state, "month");
  lua_pushinteger(lua_state, now_D);
  lua_setglobal(lua_state, "day");
  lua_pushinteger(lua_state, now_h);
  lua_setglobal(lua_state, "hour");
  lua_pushinteger(lua_state, now_m);
  lua_setglobal(lua_state, "minute");
  lua_pushinteger(lua_state, now_s);
  lua_setglobal(lua_state, "second");  
    
  lua_pushinteger(lua_state, now_ntp);
  lua_setglobal(lua_state, "ntp");
  lua_pushinteger(lua_state, now - now_ntp);
  lua_setglobal(lua_state, "since");
  lua_pushinteger(lua_state, now_epoch);
  lua_setglobal(lua_state, "epoch");
  lua_pushinteger(lua_state, now_epoch + ((now - now_ntp) / 1000));
  lua_setglobal(lua_state, "time");
  }
#endif
#if defined(Z4_LEDS)
  leds_before(lua_state);
#endif
#if defined(Z4_LORA)
  lora_before(lua_state);
#endif
  return 0;
}

static int lua_wrapper_z4_after(lua_State * lua_state) {
#if defined(Z4_LORA)
  lora_after(lua_state);
#endif
  lua_getglobal(lua_state, "now");
  was = lua_tointeger(lua_state, -1);
  took = millis() - was;
  lua_getglobal(lua_state, "seed");
  seed = lua_tointeger(lua_state, -1);
  lua_getglobal(lua_state, "broker");
  mqttBroker = (String)lua_tostring(lua_state, -1);
  lua_getglobal(lua_state, "net");
  netId = (String)lua_tostring(lua_state, -1);
  lua_getglobal(lua_state, "dev");
  devId = (String)lua_tostring(lua_state, -1);
  _netId = netId;
  _devId = devId;
  setupIds();
  return 0;
}

Z4::Z4() {

}

void Z4::begin(bool ret) {
  retain = ret;
  Serial.begin(115200);
  irrecv.enableIRIn();

  while (!Serial) {
    delay(1);
  }

  String line0 = "";
  String line1 = "";

  uint32_t chipId = 0;
  for (int i = 0; i < 17; i = i + 8) {
    chipId |= ((ESP.getEfuseMac() >> (40 - i)) & 0xff) << i;
  }

  char a[64];
  sprintf(a , "Z4%06X", chipId);
  devId = String(a);
  netId = devId;
  sprintf(a, "u%s%u", devId.c_str(), random(0, 9));
  userId = String(a);
  sprintf(a, "p%s%u", devId.c_str(), random(0, 9));
  passId = String(a);

  setupIds();

  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(0, INPUT_PULLUP);

// the z4 core
  lua.Lua_register("z4_before", (const lua_CFunction) &lua_wrapper_z4_before);
  lua.Lua_register("z4_after", (const lua_CFunction) &lua_wrapper_z4_after);

  z4.on();

  int took_cue = millis();

  for (int i=0;i<30;i++) {
    Serial.println();
  }

#if defined(Z4_TEMP)
  dht.begin();
  Serial.println("--[weather] available.");
#endif

  Serial.println("--[z4][<3] z4: the smallest interactive real-time OS for the ESP32");
  Serial.println("--[z4][<3] (c) 2023 ERIK OLSON FREE RANGE HOLDINGS, LLC.");
  Serial.println("--[z4][<3] RIP 23/12/2019 She was a very good cat.");
  Serial.println("--[z4][<3] =^.^= think of a cat while you wait.");

#if defined(Z4_TIME)
  time_setup();
#endif

#if defined(Z4_LEDS)
  leds_setup();
#endif

#if defined(Z4_LORA)
  lora_setup();
#endif

#if defined(Z4_OLED)
  oled_setup();
#endif

  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("--[z4][boot]\twake");
  line1 += String("--[z4][time]\t") + String(took);
  
  Serial.println("");
  Serial.print("--[z4][post]");

#if defined(Z4_GYRO)
  Serial.print(" gyro");
  Wire.begin();
  byte status = mpu.begin();
  while(status!=0){ }
  mpu.calcOffsets(true,true);
  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("\tgyro");
  line1 += String("\t" ) + String(took);
#endif

  //WiFi.disconnect(true);
  WiFi.disconnect();
  WiFi.onEvent(WiFiEvent);
  //WiFi.mode(WIFI_STA);
  //WiFi.mode(WIFI_MODE_APSTA);
  
  Serial.print(" wifi");

  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("\twifi");
  line1 += String("\t" ) + String(took);  
  
  mqtt.begin("propedicab.com", client);
  mqtt.onMessage(messageReceived);
  
  Serial.print(" mqtt");

  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String(" \tmqtt");
  line1 += String(" \t" ) + String(took);
  
  LittleFS.begin(true);
  
  Serial.print(" fs");

  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String(" \tfs");
  line1 += String("\t" ) + String(took);
  
#if defined(Z4_BEEP)  
  lua.Lua_register("beep", (const lua_CFunction) &lua_wrapper_beep);
#endif


//
// the z4 base
//

  // pin managment
  lua.Lua_register("pm", (const lua_CFunction) &lua_wrapper_pm);
  // network managment
  lua.Lua_register("nm", (const lua_CFunction) &lua_wrapper_nm);
  // reading and writing event registers.
  lua.Lua_register("ev", (const lua_CFunction) &lua_wrapper_ev);
  // basic input and output.
  lua.Lua_register("io", (const lua_CFunction) &lua_wrapper_io);
  // timed event spawning.
  lua.Lua_register("at", (const lua_CFunction) &lua_wrapper_at);
  // introspection and the manual.
  lua.Lua_register("me", (const lua_CFunction) &lua_wrapper_me);
  // boot to a known safe state.
  lua.Lua_register("ok", (const lua_CFunction) &lua_wrapper_ok);

  Serial.print(" lua");

  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("\tz4");
  line1 += String("\t" ) + String(took);  
  //  buf_out += String("[lua][core] ok, me, io, ev, and at.\n\r");

  z4.eval(String(lua_man));
    
  // PRE BOOT
  z4.eval(String(lua_z4));
  z4.eval(String(lua_time));

  Serial.print(" core");
  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("\tcore");
  line1 += String(" \t" ) + String(took);

  z4.eval(String(lua_man));
  
  z4.eval(String(lua_z4));
  z4.eval(String(lua_time));
  

  z4.eval(String(lua_random));
  Serial.print(" dice");
  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("\tdice");
  line1 += String(" \t" ) + String(took);

  z4.eval(String(lua_notes));
  Serial.print(" beep");
  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("\tbeep");
  line1 += String("\t" ) + String(took);
  
  z4.eval(String(lua_morse));
  Serial.print(" morse");
  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("\tmorse");
  line1 += String("\t" ) + String(took);  

  z4.eval(String(lua_fun));
  Serial.print(" fun");
  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("\tfun");
  line1 += String("\t" ) + String(took);  

  z4.eval(String(lua_mud));
  Serial.print(" mud");
  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("\tmud");
  line1 += String("\t" ) + String(took);  

  Serial.print(" OK!");
  took = millis() - took_cue; 
  took_cue = millis();
  line0 += String("\tOK!");
  line1 += String("\t" ) + String(took);  

  Serial.println();
  Serial.println(line0);
  Serial.println(line1);
  
  z4.exec("/ok");

  eval_trusted = false;
  
  took = millis() - took_cue;
  
  Serial.printf("--[ok] %ums\n--[z4][boot][DONE] took: %ums\n", took, millis());
  Serial.println();

  
  if (ssid == "" || pass == "") {
    WiFi.softAP(devId.c_str());
    dnsServer.start(53, "*", WiFi.softAPIP());

    sprintf(buf, "--[AP] %s\n",apip.c_str());
    buf_out += String(buf);
  } 
}

void Z4::input(String i) {
  buf_in += i;
}

bool Z4::available() {
  return buf_out.length();
}

void Z4::flush() {
  buf_out = "";
  z4_output = false;
}

String Z4::readString() {
  String s = buf_out;
  buf_out = "";
  z4_output = false;
  return s;
}

String Z4::dev() {
  return devId;
}
String Z4::net() {
  return netId;
}
void Z4::loop() {
  now = millis();
  //  hall = hallRead();

  if (at_time.size() > 0) {
    if (now >= at_time.front()) {
      buf_in += at_macro.front();
      at_time.erase(at_time.begin());
      at_macro.erase(at_macro.begin());
    }
  }

  if (Serial.available()) {
    buf_in += Serial.readString();
  }

  if (blink_update == true) {
    digitalWrite(LED_BUILTIN,blink_state);
    blink_update = false;
    blink_wait = true;
  }

  if (blink_wait == true && now >= blink_till) {
    digitalWrite(LED_BUILTIN,!blink_state);
  }

  if (irrecv.decode(&results)) {
    // read ir ev
    String res = String(results.value, HEX);
    // construct ev
    sprintf(buf, "/cues/%s", res.c_str());
    String ex = String(buf);
    // output ir event
    sprintf(buf, "--[zap] %s\n", ex.c_str());
    buf_out += String(buf);
    // listen for more ir input
    irrecv.resume();
    // read ex event into execution cue
//    File file = LittleFS.open(ex.c_str());
//    buf_in += file.readString();
//    file.close();
    z4.exec("/zap");

    // works
    z4.exec(ex.c_str());
  }


  wifi_loop();

  dnsServer.processNextRequest();

  //  ui_loop();

#if defined(Z4_LORA)
  lora_loop();
#endif

  if (buf_in != "" && !buf_in.startsWith("--")) {
    //    Serial.println(buf_in);
    z4.eval(buf_in);
    if (net_op == true) {
      mqtt.publish(mqttInId.c_str(), buf_in.c_str());
#if defined(Z4_LORA)
      if (buf_in != String("on(\"/zap\");") && buf_in != String("on('/zap');")) {
        z4.lora(buf_in);
      }
#endif
    }

    Serial.println(buf_in);
    //    Serial1.println(buf_in);
    buf_in = "";
  }

  if (buf_out != "" ) {
    if (!buf_out.startsWith("--[mqtt]")) {
      if (buf_out.startsWith("--")) {
        mqtt.publish(mqttInId.c_str(), buf_out.c_str());
      } else {
        mqtt.publish(mqttOutId.c_str(), buf_out.c_str());
      }
    }


    Serial.println(buf_out);
    
    if (retain == false) {
      buf_out = "";
    }
  }

#if defined(Z4_LORA)
  if (now - lora_last >= lora_beacon_time) {
    lora_last = now;
    z4.lora(lora_beacon);
    z4.exec("/beacon");
  }
#endif

#if defined(Z4_LEDS)
  if (now - leds_last >= (1000 / leds_fps)) {
    leds_last = now;
    z4.tick();
  }
#endif

  if (buf_out != "" && z4_output == false) {
    z4_output = true;
  } else {
    z4_output = false;
  }
}

void Z4::exec(const char * ev) {
//  if (ev != "/cues/ffffffffffffffff") {
    File ff = LittleFS.open(ev); 
    sprintf(buf, "--[ev] %s\n", ev);
    buf_out += String(buf);
    took = 0;
    z4.eval(ff.readString());
//  } else {
//    z4.exec("/zap");
//  }
}

void Z4::eval(String s) {
  //sprintf(buf,"z4_before(); print('pipe: %s'); %s ; z4_after();", buf_tmp.c_str(), s.c_str());
  //String ss = String(buf);
  String ss = String("z4_before(); ") + s + String(" ; z4_after();");
  buf_out += (String)lua.Lua_dostring(&ss);
}

#endif
