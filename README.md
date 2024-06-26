The Zee-Four (z4) pocket computer

![standby image](/z4pc.gif)

# the z4 platform
The z4-lua platform is an evented operating system for the ESP32 family of microcontrollers. 
It leverages the onboard EEPROM to house user defined events to be executed by interrupt.
The z4-lua scripting layer provides a user friendly interface to the z4 command.
The z4 command provides low level access to ESP32 resources.

# Capabilities:
- 128x64 oled display
- buzzer
- button
- ir input 
- web terminal
- 3x neopixel buses
- lora mesh

# Upload
I recommend using Arduino CLI to upload the pre-compiled binary from this repository as documented [here](https://arduino.github.io/arduino-cli/0.35/commands/arduino-cli_upload/).

# Why?
Files are big, have types with extensions, and with big fancy handlers for those extensions.
They may or may not be executable, contain content, or be in a binary format. And directories could keep us talking all day.
The world of embedded devices is very very small. We have less memory, storace, or processing to work with. 
An event is a small snippet of z4-lua. A vector is a collection of events associated by purpose. Simple.
All events are executable, and data is wrapped within. There is no "type" or "extension", just task and purpose.

# the z4-lua scripting layer
```
on(event,payload) -- Set event to payload.
on(event) -- Trigger event.
go(condition, command, payload) -- if condition, trigger command with payload.
at(milliseconds, payload) -- evaluate payload after milliseconds.
pipe(payload, block, [milliseconds], [times]) -- loop payload over block times delayed by milliseconds.
loop(payload, block, [milliseconds]) -- loop over block every milliseconds.
fire(event, block, [milliseconds], [times]) -- loop event over block times delayed by milliseconds.
p(something) -- print something to output.
c(event) -- print the event to output.
ls([vector]) -- list events within vector.
jump(vector) -- change the current vector.
rm(event) -- remove event.
lcd(inverted, { "line 0", "line 1" ... }) -- print the lines on the lcd.
mk(vector) -- create event vector.
roll(number, sides) -- set the number of registers to random numbers sides, and set register 0 to the total.
```
# Examples

## Blink Example

1. in the "ok" event:
1.1. load the led object.
1.2. queue the "blink" to be triggered.
2. in the "blink sketch:
2.1. turn the led on.
2.2. queue turning the led off.
2.3. queue the "blink" event to be ru-run.

```
on('ok',[[z4(16,0); on('blink');]]);
on('blink',[[z4(16,2,led,1); at(500,"z4(16,2,led,0);"); at(2000,"on('blink');");]]);
```

## Hello, World! Example

1. in the "ok" event:
1.1. Print the Hello, World! string.

```
on('ok',[[p('Hello, World');]]);
```

# Loops
Loops take on a different character in z4.  Due to it's evented nature, a loop is more genrally defined as an ordered sequence of events. These events may or may not be triggered together and because of the global scoping, conditionals may be shared across multiple events.

## Delayed Execution
The `at` command is used to specify a millisecond delay for the execution of the payload. 
This example turns the led on, the turns it off after a half second.

```
z4(16,2,led,1); at(500,"z4(16,2,led,0);");
```

## Conditional Branching
The `go(cond,cmd,payload);` command triggers the z4 0 command `cmd` with the payload.
This example triggers two different events based on a condition continuously.

```
on('choice',[[z4(16,0); z4(16,2,led,1); roll(1,2); z4(4,0,0); go(reg == 1,6,'one'); go(reg == 2,7,"z4(16,2,led,0);"); at(10000,"on('choice');");]]);
on('one',[[p("Hello, One!!!"); at(0,"on('choice');");]]);
```

# The z4 Boot Process
When the microcontroller boots, it self-initializes, then creates it's environment.
There are three steps to this process.

## events
An event is a collection of `;` separated operations to carry out a task.
All events are created the same way. The `on` command simplifies this.
The 'ok' event is used to run once within a vector to initialize a safe working enviroment.
The 'net' event is used to set the network parameters for the vector.
The 'mud' event is used by the mud function to store vector state information.
The 'hi' event is used to provide periodic information during the vector.
The following are equivilent ways to set the payload of the `hi` event:
```
-- low level
z4(0,0,"p('My Payload.');"); z4(0,5,'hi');
-- high level
on('hi',[[p('My Payload.');]]);
```

## vectors
A vector is a collection of events with a single collective purpose. The initial vector is `/`, meaning "Main".
Events contained within vectors below the current vector may be triggered from within, but not events within vectors above.
Use either of the following to change vectors:
```
-- low level
z4(32,'newVector');
-- high level
jump('newVector');
```

Returning to the main vector:
```
-- low level
z4(32,'');
-- high level
jump();
```

## event payloads
When an event is triggered, it's payload is evaluated. An event's payload can be specified in any of the following ways:

```
-- indirect
payload = [[p('My Payload.');]]; on('myEvent',payload);
-- direct
on('myEvent',[[p('My Payload.');]]);
```

### System Events
```
on('disconnected',payload) -- Wifi disconnected.
on('connecting',payload) -- wifi connecting.
on('ip',payload) -- Got ip.
on('ap',payload) -- AP up.
on('connected',payload) -- mqtt connected.
on('ntp',payload) -- got time.
on('btn/1',payload) -- Single click.
on('btn/2',payload) -- Double click.
on('btn/3',payload) -- Triple click.
on('btn/4',payload) -- Quadruple click.
on('btn/X',payload) -- Long click.
on('seq/xxxxxx',payload) -- previous ir code.
on('code/xxxxxx',payload) -- ir code.
on('zap',payload) -- ir code finalizer.
```

# Network
The `net` event establishes the network for the vector.
Access to the web terminal is provided either over a connection to an access point or the creation of one.

## public
Local networks are used to provide the web terminal and to push telemetry to the cloud server.
```
on('net',[[z4(2,1,'z4','password');]]) -- connect to access point.
on('net',[[z4(2,2,'z4','password');]]) -- private access point.
on('net',[[z4(2,0);]]) -- disconnect network.
```

# z4
The `z4` command is the interface between the ESP32, it's peripherals, and the real world.
It has many sub-commands or modes. The 0 mode has the special function of providing primitive interactions for higher level modes.

## mode 0 - Primitives
```
z4(0,0,payload) -- set buffer to payload.
z4(0,1,payload) -- set itterator to payload.
z4(0,2,payload) -- set itterator finalizer to payload.
z4(0,3,payload) -- append payload to output.
z4(0,4,payload) -- read event payload to buffer.
z4(0,5,payload) -- write payload and itterator finalizer to event payload.
z4(0,6,payload) -- execute event payload.
z4(0,7,payload) -- evaluate payload.
z4(0,8,payload) -- remove event payload.
z4(0,9,payload) -- create vector payload.
z4(0,10,payload) -- remove vector payload.
z4(0,11,payload,0) -- list events in vector payload.
```
## mode 1 - Device
```
z4(1,0,payload,0/1) -- read net to payload as global or write net from payload.
z4(1,1,payload,0/1) -- read dev to payload as global or write dev from payload.
```

## mode 2 - Network
```
z4(2,0) -- Disconnect Wifi.
z4(2,1,'ssid','password') -- connect to ssid with password.
z4(2,2,'ssid'.'password') -- create access point with ssid and password.
```

## mode 3 - Accumulator
```
z4(3,0) -- Accumulator enviroment.
z4(3,1,value) -- set the accumulator to value.
```

## mode 4 - Registers
```
z4(4,0,register) -- set 'reg' to the value of register.
z4(4,1,register,value) -- set register the to value.
```

## mode 15 -- Virtual Machine
```
z4(15,0,delay) - set loop delay.
z4(15,1,times) - set loops.
z4(15,2) - reset loop count.
z4(15,3) - set now global.
z4(15,4) - set count global.
z4(15,5) - toggle timer output.
z4(15,6) - toggle debug output.
z4(15,7) - toggle trace output.
z4(15,8,event) - output event contents.
```

## mode 16 - GPIO
```
z4(16,0) -- led builtin global enviroment.
z4(16,1,pin,mode) -- set pin mode.
z4(16,2,pin,mode) -- read/write pin.
```

## mode 17 - NTP
```
z4(17,0) -- use time global enviroment.
z4(17,1,seconds) -- expected ntp time in seconds.
```

## mode 18 - BEEP
```
z4(18,0,milliseconds) -- rest for milliseconds.
z4(18,1,milliseconds,frequency) -- play frequency for milliseconds.
z4(18,2) -- turn off buzzer.
```

## mode 20 - leds
```
z4(20,0,fps,fade) -- set fps and fade.
z4(20,1,fg,bg) -- set foreground and background.
z4(20,2,chance,bounce) -- set the glitter chance and bounce chance.
z4(20,3,glitter,color) -- set glitter color and color boolean.
z4(20,4,forward,reverse) -- set the forward and reverse pattern booleans.
```

## mode 33 - Web Terminal
```
z4(33,0) -- clear buttons
z4(33,1,value,text) -- add button
z4(33,2,link,text) -- add link
```

## Other Modes
```
z4(19,milliseconds,payload) -- evaluate payload after milliseconds.
z4(31,payload) -- set lora buffer.
z4(32,vector) -- establish vector
z4(127,x,y,inverted,text) -- oled print text at x/y. 
z4(128,box,inverted) -- oled clear, draw box.
```

## mode 255 - ESP
```
z4(255,0) - info
z4(255,255) - reboot
```
