#ifndef Z4_c
#define Z4_c

// Built for the Heltec Lora 32
#define V2
//#define V3

// With...
// a "pretty" web serial terminal
#define Z4_TERM
// a LoRa tranceiver
#define Z4_LORA
// addressable leds
#define Z4_LEDS
// a concept of time
#define Z4_TIME
// weather station
#define Z4_TEMP
// weather station
#define Z4_BEEP
// weather station
#define Z4_GYRO
// an oled (not the builtin heltec oled)
//#define Z4_OLED

//
// OLED
//
#if defined(V2)
#define Z4_OLED_RESET 6
#define Z4_OLED_SDA 4
#define Z4_OLED_SCL 15
#elif defined(V3)
#define Z4_OLED_RESET 18
#define Z4_OLED_SDA 12
#define Z4_OLED_SCL 14
#endif

//
// LORA
//
#if defined(V2)
#define Z4_LORA_CS 18
#define Z4_LORA_RESET 14
#define Z4_LORA_IRQ 26
#elif defined(V3)
#define Z4_LORA_CS 18
#define Z4_LORA_RESET 12
#define Z4_LORA_IRQ 14
#endif

//
// LED
//
#if defined(V2)
#define LED_BUILTIN 25
#elif defined(V3)
#define LED_BUILTIN 35
#endif

//
// LEDS
//
#define Z4_LEDS_LEDS_A 22
#define Z4_LEDS_LEDS_B 64

#if defined(V2)
#define Z4_LEDS_PIN_A 0
#define Z4_LEDS_PIN_B 17
#elif defined(V3)
#define Z4_LEDS_PIN_A 5
#define Z4_LEDS_PIN_B 6
#endif

//
// IR
//
#if defined(V2)
#define PIN_IR_IN 38
#elif defined(V3)
#define PIN_IR_IN 38
#endif

//
// BUZZER
//
#if defined(V2)
#define BUZZER_PIN 13
#elif defined(V3)
#define BUZZER_PIN 13
#endif

//
// DHT
//
//#define DHTTYPE    DHT11     // DHT 11
#define DHTTYPE    DHT22     // DHT 22 (AM2302)
#if defined(V2)
#define DHTPIN 4
#elif defined(V3)
#define DHTPIN 4
#endif

#define Z4_OP_WAIT 1000

#endif
