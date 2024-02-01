#include "z4_config.h"

bool leds_fwd = true;
bool leds_rev = true;
bool leds_mono = true;

bool leds_d = true;

int leds_fade = 144;
int leds_glitter = 10;

int leds_bg = 0;
int leds_fg = 290;
int leds_gl = 180;

int leds_fps = 24;
int leds_incr = 0;
int leds_last = 0;

#include <FastLED.h>

CRGB ledsA[Z4_LEDS_LEDS_A];
CRGB ledsB[Z4_LEDS_LEDS_B];

uint32_t idx[2] = {0, 0};

void Z4::tick() {
  // fade
  fadeToBlackBy(ledsA, Z4_LEDS_LEDS_A, leds_fade);
  fadeToBlackBy(ledsB, Z4_LEDS_LEDS_B, leds_fade);

  // fwd || rev
  if (leds_d == true)  {
    // d fwd && fwd
    if (leds_fwd == true) {
      ledsA[idx[0]] = CHSV(leds_fg, 255, 255);
      ledsA[Z4_LEDS_LEDS_A - idx[0]] = CHSV(leds_bg, 255, 255);
      ledsB[idx[1]] = CHSV(leds_fg, 255, 255);
      ledsB[Z4_LEDS_LEDS_B - idx[1]] = CHSV(leds_bg, 255, 255);
    }
  } else {
    // d rev && rev
    if ( leds_rev == true) {
      ledsA[idx[0]] = CHSV(leds_bg, 255, 255);
      ledsA[Z4_LEDS_LEDS_A - idx[0]] = CHSV(leds_fg, 255, 255);
      ledsB[idx[1]] = CHSV(leds_bg, 255, 255);
      ledsB[Z4_LEDS_LEDS_B - idx[1]] = CHSV(leds_fg, 255, 255);
    }
  }

  if (leds_glitter < 100) {
    // A glitter
    if (random(0, leds_glitter) == 0) {
      if (leds_mono == true) {
        ledsA[random(0, Z4_LEDS_LEDS_A - 1)] = CRGB::White;
        ledsB[random(0, Z4_LEDS_LEDS_B - 1)] = CRGB::White;
      } else {
        ledsA[random(0, Z4_LEDS_LEDS_B - 1)] = CHSV(leds_gl, 255, 255);
        ledsB[random(0, Z4_LEDS_LEDS_B - 1)] = CHSV(leds_gl, 255, 255);
      }
    }
  }

  // display
  FastLED.show();

  // incr fg
  if (leds_fg + leds_incr > 360) {
    leds_fg = 0;
  } else {
    leds_fg += leds_incr;
  }
  // incr bg
  if (leds_bg + leds_incr > 360) {
    leds_bg = 0;
  } else {
    leds_bg += leds_incr;
  }
  // incr glitter
  if (leds_gl + leds_incr > 360) {
    leds_gl = 0;
  } else {
    leds_gl += leds_incr;
  }

  // toggle direction
  
//  if (idx[0] == Z4_LEDS_LEDS_A || idx[1] == Z4_LEDS_LEDS_B) {
//    leds_d = !leds_d;
//  }

  // reset index
  if (idx[0] > Z4_LEDS_LEDS_A) {
    idx[0] = 0;
    if (idx[1] > Z4_LEDS_LEDS_B) {
      idx[1] = 0;
      leds_d = !leds_d;
    } else {
      idx[1]++;
    }
  } else {
    idx[0]++;
    if (idx[1] > Z4_LEDS_LEDS_B) {
      idx[1] = 0;
      leds_d = !leds_d;
    } else {
      idx[1]++;
    }    
  }
}

static int lua_wrapper_leds(lua_State * lua_state) {
  int m = luaL_checkinteger(lua_state, 1);
  if ( m == 0 ) {
    // theme
    leds_bg = luaL_checkinteger(lua_state, 2);
    leds_fg = luaL_checkinteger(lua_state, 3);
    leds_gl = luaL_checkinteger(lua_state, 4);
  } else if ( m == 1 ) {
    // settings
    leds_fps = luaL_checkinteger(lua_state, 2);
    leds_fade = luaL_checkinteger(lua_state, 3);
    leds_glitter = luaL_checkinteger(lua_state, 4);
    leds_incr = luaL_checkinteger(lua_state, 5);
  } else if ( m == 2 ) {
    // pattern
    leds_mono = (bool)luaL_checkinteger(lua_state, 2);
    leds_fwd = (bool)luaL_checkinteger(lua_state, 3);
    leds_rev = (bool)luaL_checkinteger(lua_state, 4);
  }
  return 0;
}

void leds_setup() {
  lua.Lua_register("leds", (const lua_CFunction) &lua_wrapper_leds);
  FastLED.addLeds<WS2811, Z4_LEDS_PIN_A, GRB>(ledsA, Z4_LEDS_LEDS_A);
  FastLED.addLeds<WS2811, Z4_LEDS_PIN_B, GRB>(ledsB, Z4_LEDS_LEDS_B);
  FastLED.setBrightness(255);
//  Serial.print(" leds");
//  int took_cue = millis();
  z4.eval(String(lua_pallet));
//  int took = millis() - took_cue; 
//  line0 += String("\tleds");
//  line1 += String("\t") + String(took);
}

static int leds_before(lua_State * lua_state) {
  lua_pushinteger(lua_state, leds_fg);
  lua_setglobal(lua_state, "fg");
  lua_pushinteger(lua_state, leds_bg);
  lua_setglobal(lua_state, "bg");
  lua_pushinteger(lua_state, leds_gl);
  lua_setglobal(lua_state, "gl");  
  lua_pushinteger(lua_state, leds_fps);
  lua_setglobal(lua_state, "fps");
  lua_pushinteger(lua_state, leds_fade);
  lua_setglobal(lua_state, "fade");
  lua_pushinteger(lua_state, leds_glitter);
  lua_setglobal(lua_state, "glitter");
  lua_pushinteger(lua_state, leds_incr);
  lua_setglobal(lua_state, "rainbow");
  lua_pushinteger(lua_state, leds_mono);
  lua_setglobal(lua_state, "monochromatic");
  lua_pushinteger(lua_state, leds_fwd);
  lua_setglobal(lua_state, "forward");
  lua_pushinteger(lua_state, leds_rev);
  lua_setglobal(lua_state, "reverse");        
  return 0;
}
