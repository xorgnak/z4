class LLLL {
  public:
    LLLL() {}
    int idxA = 0;
    int idxB = 0;
    int idxC = 0;
    bool dir = false;
    bool fwd = true;
    bool rev = true;
    bool clr = false;

    int chance = 10;
    int bounce = 20;

    int fg = 0;
    int bg = 20;
    int gl = 150;

    int fps = 15;
    int fade = 180;

    long last = 0;
    long beat = 0;

    void loop();
} eyes;

void LLLL::loop() {
  if (z4.now - eyes.last >= (1000 / eyes.fps)) {
    eyes.last = z4.now;
    fadeToBlackBy( ledsA, NUM_LEDS_A, eyes.fade);
    fadeToBlackBy( ledsB, NUM_LEDS_B, eyes.fade);
    fadeToBlackBy( ledsC, NUM_LEDS_C, eyes.fade);

    if (eyes.fwd == true) {
      if (eyes.dir == true) {
        ledsA[eyes.idxA] += CHSV(eyes.fg, 255, 255);
        ledsB[eyes.idxB] += CHSV(eyes.fg, 255, 255);
        ledsC[eyes.idxC] += CHSV(eyes.fg, 255, 255);
      } else {
        ledsA[eyes.idxA] += CHSV(eyes.bg, 255, 255);
        ledsB[eyes.idxB] += CHSV(eyes.bg, 255, 255);
        ledsC[eyes.idxC] += CHSV(eyes.bg, 255, 255);
      }
    }

    if (eyes.rev == true) {
      if (eyes.dir == true) {
        ledsA[(NUM_LEDS_A - 1) - eyes.idxA] += CHSV(eyes.bg, 255, 255);
        ledsB[(NUM_LEDS_B - 1) - eyes.idxB] += CHSV(eyes.bg, 255, 255);
        ledsC[(NUM_LEDS_C - 1) - eyes.idxC] += CHSV(eyes.bg, 255, 255);
      } else {
        ledsA[(NUM_LEDS_A - 1) - eyes.idxA] += CHSV(eyes.fg, 255, 255);
        ledsB[(NUM_LEDS_B - 1) - eyes.idxB] += CHSV(eyes.fg, 255, 255);
        ledsC[(NUM_LEDS_C - 1) - eyes.idxC] += CHSV(eyes.fg, 255, 255);
      }
    }

    if (eyes.chance < 256) {
      if (random(0, eyes.chance) == 0) {
        if (eyes.clr == true) {
          ledsA[random(0, (NUM_LEDS_A - 1))] = CHSV(eyes.gl, 255, 255);
          ledsB[random(0, (NUM_LEDS_B - 1))] = CHSV(eyes.gl, 255, 255);
          ledsC[random(0, (NUM_LEDS_C - 1))] = CHSV(eyes.gl, 255, 255);
        } else {
          ledsA[random(0, (NUM_LEDS_A - 1))] = CRGB::White;
          ledsB[random(0, (NUM_LEDS_B - 1))] = CRGB::White;
          ledsC[random(0, (NUM_LEDS_C - 1))] = CRGB::White;
        }
      }
    }

    FastLED.show();

    if (eyes.bounce < 256) {
      if (random(0, eyes.bounce) == 0) {
        eyes.dir = !eyes.dir;
      }
    }

    if (eyes.idxA + 1 > NUM_LEDS_A - 1) {
      eyes.idxA = 0;
      eyes.dir = !eyes.dir;
    } else {
      eyes.idxA++;
    }

    if (eyes.idxB + 1 > NUM_LEDS_B - 1) {
      eyes.idxB = 0;
      eyes.dir = !eyes.dir;
    } else {
      eyes.idxB++;
    }

    if (eyes.idxC + 1 > NUM_LEDS_C - 1) {
      eyes.idxC = 0;
      eyes.dir = !eyes.dir;
    } else {
      eyes.idxC++;
    }

  }

}
