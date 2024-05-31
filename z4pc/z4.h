#include "z4_term.h"

const char* ntpServer1 = "pool.ntp.org";
const char* ntpServer2 = "time.nist.gov";
const long  gmtOffset_sec = (((60 * 60) * 7) * -1);
const int   daylightOffset_sec = (60 * 60);

const char lua_z4_p[] PROGMEM = R"=====(
p = function(e); z4(0,3, tostring(e)); end;
c = function(e); z4(15,8, e); end;
ls = function(v); if v then; z4(0,11,'/' .. v,0); else; z4(0,11,'/',0); end; end;
jump = function(v); if v then; z4(32,'/' .. v); else; z4(32,''); end; end;
rm = function(e); z4(0,8,'/' .. e); end;
lcd = function(m,t); for i,e in ipairs(t) do; z4(127,0,i,m,e); end; end;
mk = function(v); z4(0,9,'/' .. v .. '/code'); z4(0,9,'/' .. v .. '/seq'); z4(0,9,'/' .. v .. 'btn'); on(v .. '/ok',''); on(v .. '/hi',''); end;
)=====";

const char lua_z4_go[] PROGMEM = R"=====(
go = function(e,mm,g); if (e) then; z4(0,mm,g); end; end;
at = function(t,p); z4(19,t,p); end;
)=====";

const char lua_z4_roll[] PROGMEM = R"=====(
roll = function(n,s); local r = 0; for i =1,n,1 do; local rr = math.random(s); z4(4,1,i,rr); r = r + rr; z4(0,3,'--[' .. i .. '][d' .. s .. '] ' .. rr); end; z4(0,3,'--[' .. n .. 'd' .. s ..  '] ' .. r); z4(4,1,0,r); return(r); end;
)=====";

const char lua_z4_on[] PROGMEM = R"=====(
on = function(e, p); if p then; z4(0,0,p); z4(0,5,'/' .. e); else; z4(0,6,'/' .. e); end; end;
)=====";

const char lua_z4_pipe[] PROGMEM = R"=====(
pipe = function(p,b,d,n); z4(15,0,d or 0); z4(15,1,n or 1); z4(0,2,b); z4(0,1,p);  end;
loop = function(p,b,d); pipe(p,b .. [[ z4(15,4); z4(15,1,count + 1);]],d); end;
fire = function(e,b,d,n); pipe([[at(0,"z4(0,6,']] .. e .. [['");]],b,d,n); end;
)=====";

struct NET {
  long last;        // last connection
  int mode;         // nm
  bool connecting;  // nm
  bool connected;   // nm
  String ssid;      // pc
  String pass;      // pc
  String topic;     // pc
  String payload;   // pc
} net = {0, 0, false, false, String("Z4"), String("meow"), String("/Z4"), String("OK")};

struct VM {
  String buffer;    // ev
  String poll;      // ev
  String block;     // ev
  String output;    // ev
  String branch;    // ev

  bool loop;        // vm
  int count;        // vm
  int times;        // vm
  int reg[64];      // vm
  int acc;          // vm

  char buf[4096];   //
} vm;

class PC {
  public:
    PC();
    size_t bytes = 0;
    size_t internal = 0;  // internal heap
    size_t external = 0;  // external heap
    size_t ram = 0;       // total heap
#if defined(ESP8266)    
    int processor = esp_get_cpu_freq_mhz();
#elif defined(ESP32)
    int processor = ESP.getCpuFreqMHz();
#endif
    void mem();           // update mem
    void loop();           // net loop
} pc;

PC::PC() {
  pc.mem();
}

class Z4 {
  public:
    Z4();

    String emit = String("OK");

    void setup();
    void loop();

    void eval(String s);        // eval s
    void poll();                // eval vm.poll
    void exec(const char * s);  // exec s
    void push(String s);
    void publish(String s);

    int available();            // output available
    String output();            // print output

    bool timer = false;          // display time info
    bool debug = false;          // display tmp output
    bool trace = false;

    String buttons = String("");

    long ntp;                   // ntp now
    long now;                   // internal clock
    long last;                  // last poll
    long delay;                 // poll delay

    long ping = 0;
    long beacon = 15000;

    String net;                 // device network
    String dev;                 // device
    String id;                  // z4 id

    String context = String("");

    String ip = "0.0.0.0";
    String date = "01/01/1970";
    String time = "00:00:00";
    String tz = "+000";
    
    String topic();
    String network();
#if defined(ESP8266)    
    uint32_t chip = system_get_chip_id();              // chip id
#elif defined(ESP32)
    uint32_t chip;
#endif
} z4;

#include "z4_lora.h"
#include "z4_oled.h"
#include "z4_leds.h"

Z4::Z4() {}

void LocalTime() {
  struct tm _tm;
  if(getLocalTime(&_tm)){
    sprintf(vm.buf, "%02d/%02d/%4d", _tm.tm_mday, _tm.tm_mon + 1, _tm.tm_year + 1900);
    z4.date = String(vm.buf);
    sprintf(vm.buf, "%02d:%02d:%02d", _tm.tm_hour, _tm.tm_min, _tm.tm_sec);
    z4.time = String(vm.buf);
    sprintf(vm.buf,"");
    time(&z4.ntp);
  }
}

// Callback function (get's called when time adjusts via NTP)
void timeavailable(struct timeval *t) {
  LocalTime();
  z4.exec("/ntp");
}

void PC::loop() {
  if (net.mode == 1) {
    if (WiFi.status() == WL_CONNECTED) {
      if (net.connecting == true && net.connected == false) {
        IPAddress ip = WiFi.localIP();
        sprintf(vm.buf, "%u.%u.%u.%u", ip[0], ip[1], ip[2], ip[3]);
        if (String(vm.buf) != String("0.0.0.0")) {
          z4.ip = String(vm.buf);
          net.connected = true;
          server.begin();
          sprintf(vm.buf,"--<[term] %s\n", z4.ip.c_str());
          vm.output += String(vm.buf);
          sprintf(vm.buf,"");
          z4.exec("/ip");
          sprintf(vm.buf, "/%s#", z4.dev.c_str());
          mqtt.subscribe(z4.topic(), [](const char * topic, const char * payload) {
            if (z4.topic() == String(topic))  {
              z4.exec(payload);
            } else if (z4.network() == String(topic)) {
              sprintf(vm.buf, "%s\n", payload);
              vm.output += String(vm.buf);
            }
          });
          mqtt.will.topic = z4.network();
          mqtt.will.payload = "bye";
          mqtt.will.qos = 1;
          mqtt.will.retain = true;
          mqtt.begin();
          sprintf(vm.buf, "--<[mqtt] /%s %s\n", z4.dev.c_str(), z4.ip.c_str());
          z4.publish(String(vm.buf));
          net.connecting = false;          
        }
      } else if (net.connecting == false && net.connected == true) {
        mqtt.loop();
      }
    }
  }
}

void PC::mem() {
  pc.ram = 0;
#if defined(ESP8266)
  ESP.resetHeap();
  pc.internal = ESP.getFreeHeap();
  pc.ram += pc.internal;
  ESP.setExternalHeap();
  pc.external = ESP.getFreeHeap();
  pc.ram += pc.external;
  ESP.resetHeap();
#elif defined(ESP32)
  pc.internal = uxTaskGetStackHighWaterMark(NULL);
  pc.external = ESP.getMaxAllocHeap();
  pc.ram = pc.internal + pc.external;
#endif
}

String Z4::topic() {
  sprintf(vm.buf, "/%s", z4.dev.c_str());
  return(String(vm.buf));
}

String Z4::network() {
  sprintf(vm.buf, "/%s/", z4.dev.c_str());
  return(String(vm.buf));
}

void Z4::push(String s) {
  events.send(s.c_str(),NULL,millis(),1000);
}

void Z4::publish(String s) {
  mqtt.publish(z4.network(), s);
}

int Z4::available() {
  return (vm.output.length());
}

String Z4::output() {
  vm.output.trim();
  String s = vm.output;
  events.send(s.c_str(),NULL,millis(),1000);
  vm.output = String("");
  return(s);
}

void Z4::eval(String s) {
  long began = z4.now;
  s.trim();
  String ss = s + String(" ") + vm.block;
  if (z4.debug == true) {
    sprintf(vm.buf, "--< %s\n", s.c_str());
    vm.output += String(vm.buf);    
  }
  lua.Lua_dostring(&ss);
  if (z4.timer == true) {
    sprintf(vm.buf, "--> %ums\n", millis() - began);
    vm.output += String(vm.buf);
  }
}

void Z4::poll() {
  String ss = vm.poll + String(" ") + vm.block;
  lua.Lua_dostring(&ss);
}

void Z4::exec(const char * s) {
      sprintf(vm.buf, "%s%s", z4.context.c_str(), s);
      String ss = String(vm.buf);
      sprintf(vm.buf, "");
      File file = LittleFS.open(ss.c_str(), "r");
      String sss = file.readString();
      file.close();
      if (z4.trace) {
        sprintf(vm.buf,"--<[%s] %s\n", ss.c_str(), sss.c_str());
        vm.output += String(vm.buf);
        sprintf(vm.buf,"");
      }    
      if (sss.length() > 1) {
        at_time.push_back(z4.now);
        at_macro.push_back(sss);
      }
}

static int lua_wrapper_z4(lua_State * lua_state) {
  int ret = 0;
  sprintf(vm.buf, "");
  String tmp = String("");
  int m = luaL_checknumber(lua_state, 1);
  if (m == 0) {
    int mm = luaL_checknumber(lua_state, 2);
    const char * s = luaL_checkstring(lua_state, 3);
    if (mm == 0) {
      vm.buffer = String(s);
    } else if (mm == 1) {
      vm.poll = String(s);
      vm.count = 1;
    } else if (mm == 2) {
      vm.block = String(s);
    } else if (mm == 3) {
      vm.output += String(s);
      vm.output += String("\n");
    } else if (mm == 4) {
      sprintf(vm.buf,"%s%s", z4.context.c_str(), s);
      String _s = String(vm.buf);
      File file = LittleFS.open(_s.c_str(), "r");
      vm.buffer = file.readString();
      file.close();
    } else if (mm == 5) {
      sprintf(vm.buf,"%s%s", z4.context.c_str(), s);
      String _s = String(vm.buf);
      File file = LittleFS.open(_s.c_str(), "w");
      String ss = vm.buffer + String(" ") + vm.block;
      file.print(ss.c_str());
      file.close();
    } else if (mm == 6) {
      z4.exec(s);      
    } else if (mm == 7) {
      z4.eval(String(s));
    } else if (mm == 8) {
      sprintf(vm.buf,"%s%s", z4.context.c_str(), s);
      String _s = String(vm.buf);      
      LittleFS.remove(_s.c_str());
    } else if (mm == 9) {
      sprintf(vm.buf,"%s%s", z4.context.c_str(), s);
      String _s = String(vm.buf);      
      LittleFS.mkdir(_s.c_str());
    } else if (mm == 10) {
      sprintf(vm.buf,"%s%s", z4.context.c_str(), s);
      String _s = String(vm.buf);      
      LittleFS.rmdir(_s.c_str());
    } else if (mm == 11) {
      int mmm = luaL_checknumber(lua_state, 4);
      if (mmm == 0) {
        pc.bytes = 0;
      }
      String ss = "";
      String sd = "";
      sprintf(vm.buf, "%s%s", z4.context, s);
      size_t bb = 0;
      String _ss = String(vm.buf);
      File root = LittleFS.open(_ss.c_str(), "r");
      File file = root.openNextFile();
      while (file) {
        if (file.isDirectory()) {
          sprintf(vm.buf, "z4(0,11,'/%s',1);", file.name());
          String _x = String(vm.buf);
          z4.eval(_x);
          sprintf(vm.buf, "--|---[/%s]\n", file.name());
          sd += String(vm.buf);
        } else {
          bb += file.size();
          pc.bytes += file.size();
          sprintf(vm.buf, "--+-[%s] %uB\n", file.name(), file.size());
          ss += String(vm.buf);
        }
        file = root.openNextFile();
      }
      if (mmm == 0) {
        sprintf(vm.buf, "%s%s--o===[%s] %uB\n", sd.c_str(), ss.c_str(), s, pc.bytes);
      } else if (mmm == 1) {
        sprintf(vm.buf, "%s%s--o-=-[%s] %uB\n", sd.c_str(), ss.c_str(), s, bb);  
      }
    } else {
      sprintf(vm.buf, "--X[ev][%i][%i]\n", m, mm);
    }
  } else if (m == 1) {
    int mm = luaL_checknumber(lua_state, 2);
    const char * s = luaL_checkstring(lua_state, 3);
    int mr = luaL_checknumber(lua_state, 4);
    if (mm == 0) {
      if (mr == 1) {
        z4.net = String(s);
      } else {
        lua_pushstring(lua_state, z4.net.c_str());
        lua_setglobal(lua_state, s);
      }
    } else if (mm == 1) {
      if (mr == 1) {
        z4.dev = String(s);
      } else {
        lua_pushstring(lua_state, z4.dev.c_str());
        lua_setglobal(lua_state, s);
      }                  
    } else if (mm == 2) {
      if (mr == 1) {
        String ss = z4.topic();
        sprintf(vm.buf, "%s", s);
        mqtt.publish(ss.c_str(), vm.buf);
      } else {
        String ss = z4.topic();
        lua_pushstring(lua_state, ss.c_str());
        lua_setglobal(lua_state, s);
      }
    } else if (mm == 3) {
      if (mr == 1) {
        String ss = z4.network();
        sprintf(vm.buf, "%s", s);
        mqtt.publish(ss.c_str(), vm.buf);
      } else {
        String ss = z4.network();
        lua_pushstring(lua_state, ss.c_str());
        lua_setglobal(lua_state, s);
      }         
    } else {
      sprintf(vm.buf, "--X[io][%i][%i]\n", m, mm);
    }

  } else if (m == 2) {
    int mm = luaL_checknumber(lua_state, 2);
    net.mode = mm;
    WiFi.disconnect();
    if (mm == 0) {
      sprintf(vm.buf,"--+-[disconnect]\n");
      File file = LittleFS.open("/disconnect", "r");
      vm.branch = file.readString();
      file.close();      
    } else if (mm == 1) {
      const char * s = luaL_checkstring(lua_state, 3);
      const char * p = luaL_checkstring(lua_state, 4);
      if (WiFi.begin(s,p)) {
        net.connecting = true;
        net.mode = 1;
        z4.exec("/connecting");
      }
    } else if (mm == 2) {
      const char * s = luaL_checkstring(lua_state, 3);
      const char * p = luaL_checkstring(lua_state, 4);      
      if (WiFi.softAP(s,p)) {
        sprintf(vm.buf,"--+-[ap] %s %s http://192.168.4.1\n", s, p);
      }
    } else {
      sprintf(vm.buf, "--X[nm][%i][%i]\n", m, mm);
    }

  } else if (m == 3) {
    int mm = luaL_checknumber(lua_state, 2);    
    if (mm == 1) {
       vm.acc = luaL_checknumber(lua_state, 3); 
    } else if (mm == 0) {       
      lua_pushinteger(lua_state, (lua_Number)vm.acc);
      lua_setglobal(lua_state, "acc");
    } else {
      sprintf(vm.buf, "--X[acc][%i][%i]\n", m, mm);
    }

  } else if (m == 4) {
    int mm = luaL_checknumber(lua_state, 2);
    if (mm == 0) {
      int mi = luaL_checknumber(lua_state, 3);
      lua_pushinteger(lua_state, (lua_Number)vm.reg[mi]);      
      lua_setglobal(lua_state, "reg");
    } else if (mm == 1) {
      int mi = luaL_checknumber(lua_state, 3);
      int mx = luaL_checknumber(lua_state, 4);
      vm.reg[mi] = mx;
    } else {
      sprintf(vm.buf, "--X[reg][%i][%i]\n", m, mm);
    }

  } else if (m == 15) {
    int mm = luaL_checknumber(lua_state, 2);
    if (mm == 0) {
      z4.delay = luaL_checknumber(lua_state, 3);    
    } else if (mm == 1) {
      vm.times = luaL_checknumber(lua_state, 3);
    } else if (mm == 2) {
      vm.count = 1;
    } else if (mm == 3) {
      lua_pushinteger(lua_state, (lua_Number)z4.now);      
      lua_setglobal(lua_state, "now");
    } else if (mm == 4) {
      lua_pushinteger(lua_state, (lua_Number)vm.count);      
      lua_setglobal(lua_state, "count");
    } else if (mm == 5) {
      z4.timer = !z4.timer;
    } else if (mm == 6) {
      z4.debug = !z4.debug;
    } else if (mm == 7) {
      z4.trace = !z4.trace;      
    } else if (mm == 8) {
      const char * s = luaL_checkstring(lua_state, 3);
      sprintf(vm.buf,"/%s%s", z4.context.c_str(), s);
      String ss = String(vm.buf);
      File file = LittleFS.open(ss.c_str(), "r");
      String sx = file.readString();
      file.close();
      sprintf(vm.buf, "--#[%s] %s\n", s, sx.c_str());  
    } else {
      sprintf(vm.buf, "--X[poll][%i][%i]\n", m, mm);
    } 
    
  } else if (m == 16) {    
    int mm = luaL_checkinteger(lua_state, 2);
    if (mm == 0) {
      lua_pushinteger(lua_state, (lua_Number)LED_BUILTIN);      
      lua_setglobal(lua_state, "led");      
    } else if (mm == 1) {
      int a = luaL_checkinteger(lua_state, 3);
      int b = luaL_checkinteger(lua_state, 4);
      if (b == 1) {
        pinMode(a, INPUT);
      } else if (b == 0) {
        pinMode(a, OUTPUT);
      } else if (b == 2) {
        pinMode(a, INPUT_PULLUP);
      }
    } else if (mm == 2) {
      int a = luaL_checkinteger(lua_state, 3);
      int b = luaL_checkinteger(lua_state, 4);
      if (b == 2) {
        lua_pushinteger(lua_state, digitalRead(a));
        lua_setglobal(lua_state, "pin");
      } else if (b == 0) {
        digitalWrite(a, LOW);
      } else if (b == 1) {
        digitalWrite(a, HIGH);
      }
    } else {
      sprintf(vm.buf, "--X[gpio][%i][%i]\n", m, mm);     
    }
  } else if (m == 17) {
    LocalTime();
    int mm = luaL_checkinteger(lua_state, 2);
    if (mm == 0) {
      lua_pushinteger(lua_state, z4.ntp);      
      lua_setglobal(lua_state, "epoch");      
      lua_pushstring(lua_state, z4.time.c_str());      
      lua_setglobal(lua_state, "time");      
      lua_pushstring(lua_state, z4.date.c_str());      
      lua_setglobal(lua_state, "date");
    } else if (mm == 1) {
      int mx = (long)luaL_checkinteger(lua_state, 3);
      lua_pushinteger(lua_state, (lua_Number)z4.ntp + mx);      
      lua_setglobal(lua_state, "till");           
    } else {
      sprintf(vm.buf, "--X[ntp][%i][%i]\n", m, mm);
    }

  } else if (m == 18) {
    int mm = luaL_checkinteger(lua_state, 2);
    if (mm == 0) {
      int md = luaL_checkinteger(lua_state, 3);
      delay(md);
    } else if (mm == 1) {
      int md = luaL_checkinteger(lua_state, 3);
      int mn = luaL_checkinteger(lua_state, 4);
      buzzer.tone(mn, md);
    } else if (mm == 2) {
      buzzer.noTone();
    } else {
      sprintf(vm.buf, "--X[ntp][%i][%i]\n", m, mm);
    }

  } else if (m == 19) {
      long t = (long)luaL_checknumber(lua_state, 2);
      const char * p = luaL_checkstring(lua_state, 3);
      long tt = z4.now + t;
      at_time.push_back(tt);
      sprintf(vm.buf, "%s", p);
      at_macro.push_back(String(vm.buf));
      sprintf(vm.buf, "--<<<[%u] %s\n", t, p);

  } else if (m == 20) {
      int mm = luaL_checknumber(lua_state, 2);  
      if (mm == 0) {
        eyes.fps = luaL_checknumber(lua_state, 3);
        eyes.fade = luaL_checknumber(lua_state, 4);
      } else if (mm == 1) {
        eyes.fg = luaL_checknumber(lua_state, 3);
        eyes.bg = luaL_checknumber(lua_state, 4);        
      } else if (mm == 2) {
        eyes.chance = luaL_checknumber(lua_state, 3);
        eyes.bounce = luaL_checknumber(lua_state, 4);        
      } else if (mm == 3) {
        eyes.gl = luaL_checknumber(lua_state, 3);
        eyes.clr = (bool)luaL_checknumber(lua_state, 4);
      } else if (mm == 4) {
        eyes.fwd = (bool)luaL_checknumber(lua_state, 3);
        eyes.rev = (bool)luaL_checknumber(lua_state, 4);
      }
  } else if (m == 31) {    
    const char * s = luaL_checkstring(lua_state, 2);
    z4.emit = String(s);

  } else if (m == 32) {    
    const char * s = luaL_checkstring(lua_state, 2);
    sprintf(vm.buf, "%s", s);
    z4.context = String(vm.buf);
    LittleFS.mkdir(z4.context.c_str());
    z4.exec("/ok");
    z4.exec("/net");
    z4.exec("/mud");
    z4.exec("/hi");
    
  } else if (m == 127) {
    int mx = luaL_checkinteger(lua_state, 2);
    int my = luaL_checkinteger(lua_state, 3);
    int mf = luaL_checkinteger(lua_state, 4);    
    const char * ms = luaL_checkstring(lua_state, 5);
    oled.print(mx, my, mf, (char *)ms);

  } else if (m == 128) {
    int mm = luaL_checkinteger(lua_state, 2);
    int mf = luaL_checkinteger(lua_state, 3);
    if (mm == 0) {
      oled.clear(mf);
    } else if (mm == 1) {
      oled.box(mf);
    }

  } else if (m == 255) {
    int mm = luaL_checknumber(lua_state, 2);
    if (mm == 0) {
      pc.mem();
      lua_pushstring(lua_state, ESP.getChipModel());
      lua_setglobal(lua_state, "device");
      lua_pushinteger(lua_state, ESP.getChipCores());
      lua_setglobal(lua_state, "cores");      
      lua_pushinteger(lua_state, pc.processor);
      lua_setglobal(lua_state, "cpu");      
      lua_pushinteger(lua_state, pc.ram);
      lua_setglobal(lua_state, "ram");
      lua_pushinteger(lua_state, pc.internal);
      lua_setglobal(lua_state, "internal");
      lua_pushinteger(lua_state, pc.external);
      lua_setglobal(lua_state, "external"); 
    } else if (mm == 255) {
      ESP.restart();
    }
    
  } else {
    sprintf(vm.buf, "--XX[%i]\n", m);
  }

  vm.output += String(vm.buf);

  return (ret);
}
