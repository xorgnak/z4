#include "z4_config.h"
#include <LoRa.h>

String pkt_out = "";
uint32_t lora_last = 0;
int lora_beacon_time = 30000;
String lora_beacon = "OK 0";

void Z4::lora(String p) {
  if (!p.startsWith("[") && !p.startsWith("#")) {
  pkt = 4;
  String sig = "";
  for (int i = 0; i < 5; i++) {
    sig += String(random(0, 15), HEX);
  }
  p.trim();
  pkt_out = "";
  pkt_out += String("BEGIN ");
  pkt_out += sig;
  pkt_out += String(" ");
  pkt_out += netId;
  pkt_out += String(" ");
  pkt_out += devId;
  pkt_out += String(" ");
  pkt_out += p;
  pkt_out += String(" END");
  LoRa.beginPacket();
  LoRa.print(pkt_out);
  LoRa.endPacket(true);
  LoRa.receive();
  sprintf(buf, "--[lora][>] %s\n\r", pkt_out.c_str());
  buf_out += String(buf);
  pkt_out = "";
  }
}

void lora_loop() {
  if (LoRa.parsePacket()) {
    digitalWrite(LED_BUILTIN, HIGH);
    pkt = 3;
    String s = LoRa.readString();
    s.trim();
    //      Serial.printf("\n[LORA][RAW][%i] %s\n", LoRa.packetRssi(), s.c_str());
    String _s = s;
    bool lora_fwd = false;
    bool lora_resp = false;
    String _sig;
    String _net;
    String _from;

    if (s.startsWith("BEGIN ") && s.endsWith(" END")) {

      s.remove(s.length() - 4);
      s.remove(0, 6);

      int is = s.indexOf(" ");
      _sig = s.substring(0, is);
      s.remove(0, is + 1);

      int it = s.indexOf(" ");
      _net = s.substring(0, it);
      s.remove(0, it + 1);

      int iu = s.indexOf(" ");
      _from = s.substring(0, iu);
      s.remove(0, iu + 1);

      int _hops = _from.indexOf(">");
      bool hops;
      if (_hops < 0) {
        hops = false;
      } else {
        hops = true;
      }

      
      // only handle network messages
      if (_net.startsWith(netId)) {
        // only handle non-response and non-device messages
        if (!s.startsWith("OK ") && !s.startsWith("ok ") && net_op == false) {
              z4.eval(s);
              if (net_op_lvl == 0) {
                lora_resp = true;
              }
        }
        // FORWARD everything that's not our message.
        if (!_from.startsWith(devId) && !_from.endsWith(_devId)) {
          lora_fwd = true;
        }

        // FORWARD!
        if (!s.startsWith("OK") && !s.startsWith("ok") && lora_fwd == true && hops < 0) {
          _netId = netId;
          _devId = devId;
          devId = _from + String(">") + _devId;
          netId = _net;
          z4.lora(s);
          devId = _devId;
          netId = _netId;
          z4.exec("/fwd");
        } else {
          String sseed = String(seed);
          if (s.startsWith("OK ") && s.endsWith(sseed)) {
            z4.exec("/true");
          } else {
            z4.exec("/false");
          }
        }

        // RESPOND!
        if (!s.startsWith("OK") && !s.startsWith("ok") && lora_resp == true) {
          sprintf(buf, "ok %s %i\n%s", _sig.c_str(), LoRa.packetRssi(), buf_out.c_str());
          String ss = String(buf);
          _netId = netId;
          _devId = devId;
          devId = _from + String(">") + _devId;
          netId = _net;
          z4.lora(ss);
          devId = _devId;
          netId = _netId;
          z4.exec("/resp");          
        }
      }
      // DONE
      sprintf(buf, "--[lora][<][%i][%i%i%i][%s][%s][%s]\n%s\n", LoRa.packetRssi(), lora_fwd, lora_resp, hops, _sig.c_str(), _net.c_str(), _from.c_str(), s.c_str());
      buf_out += String(buf);
    }
    digitalWrite(LED_BUILTIN, LOW);
  }
}

void lora_setup() {
  LoRa.setPins(Z4_LORA_CS, Z4_LORA_RESET, Z4_LORA_IRQ);
  LoRa.begin(915E6);
}

static int lora_before(lua_State * lua_state) {
  lua_pushinteger(lua_state, lora_beacon_time);
  lua_setglobal(lua_state, "beacon");
  return 0;
}
static int lora_after(lua_State * lua_state) {
  lua_getglobal(lua_state, "beacon");
  lora_beacon_time = lua_tointeger(lua_state, -1);
  return 0;
}
