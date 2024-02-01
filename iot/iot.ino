/* ##### z4 basic sketch #####

   written for the heltec lora 32 v2/3 development board

   ALL RIGHTS RESERVED (c) 2023 ERIK OLSON FREE RANGE HOLDINGS, LLC.

   Example uses a simple webserver to interact with the z4 platform.
   Input to the input box will be sent as serial input.
   Output is by eventsource.

   RESET BUTTON: The hardware version of the "ok();" command.
   Boot to a known safe state.

   0. Trigger the /ok event: load config.

   1. Trigger the /ok event: boot safe config.
     - Try config in serial or web terminal first.
     - Use this mechanism to set leds pattern and settings.
     - Use this mechanism to set the beacon time and initial payload.


   2. If connected to network?

   2.1 Trigger the /ntp: local time is set via ntp.
   2.2 Trigger the /connect event: used to denote network connection.
   2.3 Trigger the /false event: used to set normal running state.
   2.4 Trigger the /true event: used to set zapped running state.
   2.5 Trigger the /mqtt event: used to set dm state.
   2.6 Trigger the /cue event: used to initiate the cued state.
   2.7 Trigger a subcue in the /cues collection: used to initiate a subcue state.

   IR: Trigger remote events.
   Watch the output stream to find events according to their infared signiture.

   USAGE:
   The device automatically starts a webserver to accept input.

   QUICKSTART:
   me(256); => help menu.
   me(255); => boss mode.
   me(254); => operator mode.
   me(253); => agent mode.
   me(252); => manager mode.
   me(251); => ambassador mode.
   me(250); => influencer mode.
   me(249); => promotor mode.
   me(248); => character mode.

   nm(1,'ssid','password'); => set the wifi credentials.
   nm(2); => connect wifi.
   nm(0); => disconnect wifi.

   leds(0,fg,bg,gl); => set leds pallet.
   leds(1,fps,fade,glitter,rainbow); => set leds settings.
   leds(2,monochromatic,forward,reverse); => set leds pattern.
*/

#include "z4.h"

#if defined(Z4_TERM)
// only necessary *if* you want a "pretty" web serial terminal
// async web server for esp32
#include <ESPAsyncWebSrv.h>
// "pretty" web terminal
#include "index_html.h"
// html server instance
AsyncWebServer server(80);
// event source for "pretty" web serial terminal defered output.
AsyncEventSource events("/events");
#endif

// Our z4 task loop.
void task( void *pvParameters ) {
  (void) pvParameters;
  while (true) {
    // always do z4 stuff first,
    z4.loop();
    // do more stuff if you'd like.

#if defined(Z4_TERM)
    // DEFERED OUTPUT
    // defered z4 output available?
    if (z4.available() > 0) {
      // do stuff with the available output...
      String o = z4.readString();
      events.send(o.c_str(), NULL);
    }
    vTaskDelay(1);
#endif
  }
}

void setup() {

// if you *need* a "pretty" web serial interface,
// define Z4_TERM  in the z4_config.h file. 
#if defined(Z4_TERM)
  // begin z4 with the true option to defer output,
  z4.begin(true);
  
  // then define the output,
  server.on("/eval", HTTP_GET, [](AsyncWebServerRequest * request) {
    int params = request->params();
    for (int i = 0; i < params; i  ++) {
      AsyncWebParameter* p = request->getParam(i);
      String k = String(p->name());
      String v = String(p->value());
      if (k == String("i")) {
        z4.eval(v);
        delay(10);
        if (z4.available() > 0) {
          String o = z4.readString();
          Serial.print("=> ");
          Serial.println(o);
          events.send(o.c_str(), NULL);
        }
      }
    }
    request->send(201);
  });

  server.on("/", HTTP_GET, [](AsyncWebServerRequest * request) {
    z4.exec("/index"); request->send(200, "text/html", index_html);
  });

  server.onNotFound([](AsyncWebServerRequest * request) { request->send(404); });
  
  events.onConnect([](AsyncEventSourceClient * client) {
    String o = "--[<a href='https://github.com/xorgnak/z4' style='background-color: orange; color: black;'>Z4</a>]";
    o += "<span style='border: thin solid grey; border-radius: 50px; padding: 0 1% 0 1%;'>";
    o += "<a style='padding: 0 2% 0 1%;' href='https://duckduckgo.com/?q=minimal+kernel+and+fs&t=raspberrypi&ia=web'>&#181</a>";
    o += "<span style='color: orange;'>|</span>";
    o += "<a style='padding: 0 1% 0 1%;' href='https://duckduckgo.com/?q=embedded+rtos+wikipedia&t=raspberrypi&ia=web'>RealTime</a>";
    o += "<span style='color: orange;'>|</span>";
    o += "<a style='padding: 0 1% 0 2%;' href='https://en.wikipedia.org/wiki/Plan_9_from_Bell_Labs'>OperatingSystem</a>";
    o += "</span>";
    client->send(o.c_str(), NULL, millis(), 1000);
  });

  server.addHandler(&events);

  server.begin();
#else
// OR... just begin using inline output.
z4.begin(false);
#endif

  xTaskCreate(task,"z4",4096,NULL,1,NULL);
}

void loop() { vTaskDelete(NULL); }
