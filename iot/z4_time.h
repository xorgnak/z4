/*
 * The z4 ntp engine.
 * 
 * sets local epoch on network connection, triggering 
 * the "/ntp" event.
 * 
 */

#include "z4_config.h"
#include "time.h"
#include "sntp.h"

const char* ntpServer1 = "pool.ntp.org";
const char* ntpServer2 = "time.nist.gov";
const long  gmtOffset_sec = 3600;
const int   daylightOffset_sec = 3600;

String now_date;
time_t now_epoch;

uint32_t now_ntp = 0;

bool got_time = false;

uint32_t now_Y = 0;
uint32_t now_M = 0;
uint32_t now_D = 0;
uint32_t now_h = 0;
uint32_t now_m = 0;
uint32_t now_s = 0;

void Z4::date() {
  struct tm timeinfo;
  if (!getLocalTime(&timeinfo)) { return; }
  time(&now_epoch);
  sprintf(buf, "%u/%u/%u %u:%u:%u UTC", timeinfo.tm_year + 1900, timeinfo.tm_mon + 1, timeinfo.tm_mday, timeinfo.tm_hour, timeinfo.tm_min, timeinfo.tm_sec);
  now_date = String(buf);
  now_ntp = now;
  now_Y = timeinfo.tm_year + 1900;
  now_M = timeinfo.tm_mon + 1;
  now_D = timeinfo.tm_mday;
  now_h = timeinfo.tm_hour;
  now_m = timeinfo.tm_min;
  now_s = timeinfo.tm_sec;
}

//Callback function (get's called when time adjusts via NTP)
void timeavailable(struct timeval *t)
{
  got_time = true;
  z4.date();
  z4.exec("/ntp");
  net_connecting = false;
  net_connected = true;
}

static int lua_wrapper_date(lua_State * lua_state) {
  z4.date();
  sprintf(buf, "--[DATE] %s\n-- epoch: %u\n-- local: %u\n", now_date.c_str(), now_epoch, now_ntp);
  buf_out += String(buf); 
  return 0;
}

void time_setup() { 
  sntp_set_time_sync_notification_cb( timeavailable );
  configTime(gmtOffset_sec, daylightOffset_sec, ntpServer1, ntpServer2);
  lua.Lua_register("date", (const lua_CFunction) &lua_wrapper_date);
}


static int time_before(lua_State * lua_state) {
  lua_pushinteger(lua_state, now_ntp);
  lua_setglobal(lua_state, "time");
}
