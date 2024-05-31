
class LLL {
  public:
    LLL();
    int rssi;
    int snr;
    String data;

    String rnd;
    String net;    
    String from;
    String payload;
    
    bool legal();
    void loop();
    void _rx();
} lora;

LLL::LLL() {}

void LLL::_rx() {
  String s = lora.data;
  if (s.startsWith("START ") && s.endsWith(" END")) {
    s.remove(s.length() - 4);
    s.remove(0, 6);

    int it = s.indexOf(" ");
    lora.net = s.substring(0, it);
    s.remove(0, it + 1);

    int iu = s.indexOf(" ");
    lora.from = s.substring(0, iu);
    s.remove(0, iu + 1);

    if (lora.net == z4.net) {
      if (lora.from == z4.net) {
        z4.eval(s); // network
      } else {
        // network peer     
      }
    } else {
      // generic
    }
  }
}

bool LLL::legal() {
  if (millis() > last_tx + minimum_pause) {
    return true;
  } else {
    return false;
  }
}

void LLL::loop() {  
  if (rxFlag) {
    rxFlag = false;
    radio.readData(rxdata);
    rxdata.trim();
    lora.data = rxdata;
    lora.rssi = radio.getRSSI();
    lora.snr = radio.getSNR();
    lora._rx();
    radio.startReceive(RADIOLIB_SX126X_RX_TIMEOUT_INF);
  }
}
