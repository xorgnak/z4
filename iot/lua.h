const char lua_z4[] PROGMEM = R"=====(
get = function(f); io(0, ''); ev(0, f); end;

ls = function(p);
  if p == nil then
    ev(256, '/');
  else;
    ev(256, p);
  end;
end;

print = function(...);
  local ee = { ... };
  for i,e in ipairs(ee) do
    io(1, tostring(e) .. "\n");
  end
end;

on = function(f, c);
  if c then;
    io(0, c);
    ev(1, f);
  else;
    ev(5, f);
  end;
end;

hi = function(); ev(5, '/hi'); end;
cat = function(f); get(f); io(255,f); return(pipe); end;
run = function(e); at(1, 'on("' .. e .. '");'); end;
rm = function(f); ev(6,f); end;

cue = function(x);
  ev(3,"/cues");
  if x then; ev(5, '/cues/' .. tostring(x)); end;
  ev(5, '/cue');
end;
)=====";

const char lua_morse[] PROGMEM = R"=====(
dit = 50;
dot = 100;
dash = 500;
space = 1000;
attn = 5000;

morse = function(...);
  local ee = { ... };
  local tt = 0;
  for i,e in ipairs(ee) do;
    tt = tt + dot;
    if e == space then;
      tt = tt + dit;
    else;
      at(tt, "me(34);"); 
      at(tt + e,"me(35);");  
      tt = tt + e + dit;
    end;
  end;
end;
)=====";

const char lua_fun[] PROGMEM = R"=====(
meow = function(s); print("..(=^.^=) <( " .. tostring(s) .. " )"); end;
slug = function(s); print("..o0O' <( " .. tostring(s) .. " )"); end;
worm = function(s); print("..o0o0o0O' <( " .. tostring(s) .. " )"); end;
)=====";

const char lua_mud[] PROGMEM = R"=====(
status = 0;
who = '';
where = '';
what = '';
why = '';
xp = 0;
gp = 0;
hp = 0;
ac = 0;
lvl = 0;

mud = function();
  statue = 16;
  on('/mud',"who = '" .. who .. "'; where = '" .. where ..  "'; what = '" .. what .. "'; why = '" .. why .. "'; xp = " .. xp .. "; lvl = " .. lvl .. "; hp = " .. hp .. "; ac = " .. ac .. ";");
end

vs = function(op);
  local r = ac - tonumber(op);
  if r >= 0 then;
    ev(5,"/live");
  else;
    ev(5,"/dead");
  end;
  return(r);
end;

)=====";

const char lua_notes[] PROGMEM = R"=====(
  whole = 1000;
  notes = { whole, whole / 2, whole / 4, whole / 8, whole / 16, whole / 32 };
  note = {
    { 16, 17, 18, 19, 20, 21, 23, 24, 26, 27, 29, 31 },
    { 32, 34, 37, 39, 41, 43, 46, 49, 52, 55, 59, 61 },
    { 65, 70, 73, 78, 82, 87, 92, 98, 103, 110, 116, 123 },
    { 131, 138, 146, 155, 165, 175, 185, 196, 207, 220, 223, 247 },
    { 261, 277, 293, 311, 329, 349, 370, 392, 415, 440, 466, 494 },
    { 523, 554, 587, 622, 659, 698, 740, 784, 831, 880, 932, 988 },
    { 1046, 1109, 1175, 1245, 1319, 1397, 1480, 1568, 1661, 1760, 1865, 1975 },
    { 2093, 2217, 2349, 2489, 2637, 2784, 2960, 3136, 3322, 3520, 3729, 3951 },
    { 4186, 4435, 4699, 4978, 5274, 5588, 5920, 6272, 6645, 7040, 7459, 7902 }
  };
  rest = function(d);
    beep(0, notes[d]);
  end;
  
  play = function(o, n, d);
    beep(note[o][n], notes[d]);
  end;
)=====";

const char lua_time[] PROGMEM = R"=====(
t = function(mms, sss, ms, hs);
  local ss = (sss * 1000);
  local mm = (ms * (60 * 1000));
  local hh = (hs * (60 * (60 * 1000)));
  return(mms + ss + mm + hh); 
end;
)=====";

const char lua_random[] PROGMEM = R"=====(
die = function(sides);
  return(math.random(1, sides));
end;
dice = function(n, s);
  local a = 0;
  for i = n,1,-1 do local d = die(s); io(1,"[d" .. s .. "][" .. i .. "] " .. d .. "\n\r"); a = a + d; end;
  io(-1,"[" .. n .. "d" .. s .. "]: " .. a .. "\n\r");
  return(a);
end;

roll = function(t);
  local a = 0;
  for i = #t, 1, -1 do a = a + dice(t[i][1], t[i][2]); end;
  io(-1,"[roll] " .. a .. "\n\r");
  return(a);
end;
)=====";

const char lua_pallet[] PROGMEM = R"=====(
red = 0;
blue = 180;
green = 360;
brown = 260;
yellow = 30;
orange = 280;
indigo = 120;
pink = 250;
violet = 210;
purple = 190;
gold = 290;
colors = { red; orange; yellow; green; blue; indigo; violet };
)=====";

const char lua_man[] PROGMEM = R"=====(
Man = {};

table.insert(Man,"-- get('/event');\t\t\t=> load the contents of the event into the pipe.");
table.insert(Man,"-- ls('/collection');\t\t\t=> list the events in the collection given.");
table.insert(Man,"-- on('/event');\t\t\t=> trigger event.");
table.insert(Man,"-- on('/ok',\"me(255);\");\t\t=> set the payload of the '/ok' event to 'me(255);'.");
table.insert(Man,"-- hi();\t\t\t\t=> trigger the '/hi' event.");
table.insert(Man,"-- cat('/event');\t\t\t=> display the payload of the event.");
table.insert(Man,"-- run('/event');\t\t\t=> trigger event NOW!");
table.insert(Man,"-- rm('/event');\t\t\t=> remove event.");
table.insert(Man,"-- cue();\t\t\t\t=> trigger the '/cue' event.");
table.insert(Man,"-- cue(0);\t\t\t\t=> trigger the '/cues/0' event, then the '/cue' event.");
table.insert(Man,"-- cue('/home');\t\t\t=> trigger the '/cues/home' event, then the '/cue' event.");
table.insert(Man,"-- morse(dit,dot,dash,space,attn);\t=> blink the given pattern.");
table.insert(Man,"-- meow('Meow!');\t\t\t=> output the given text with a cat.");
table.insert(Man,"-- slug('squish..');\t\t\t=> output the given text with a slug.");
table.insert(Man,"-- worm('squish..');\t\t\t=> output the given text with a worm.");
table.insert(Man,"-- vs(OpponentHP);\t\t\t=> trigger event according to raw hp against ac.");
table.insert(Man,"-- play(4,3,2);\t\t\t\t=> play note 3 in octave 4, for a quarter note.");
table.insert(Man,"-- rest(3);\t\t\t\t=> rest for a note duration.");
table.insert(Man,"-- t(1,2,3,4);\t\t\t\t=> generate ms offset for four hours, three minutes, two secons and one milisecond.");
table.insert(Man,"-- die(17);\t\t\t\t=> toss a 17 sided die.");
table.insert(Man,"-- dice(3,11);\t\t\t\t=> toss 3 eleven sided dice.");
table.insert(Man,"-- roll({{2,6},{3,4}});\t\t\t=> toss 2 six sided dice and 3 four sided dice.");
table.insert(Man,"-- colors[4];\t\t\t\t=> the 4th color of the rainbow.");

man = function();
  for i,e in ipairs(Man) do;
    print(e);
  end;
end;
)=====";
