
const char z4_index_head[] PROGMEM = R"=====(
<!DOCTYPE html>
<html>
  <head>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    html { height: 100%; width: 100%; margin: 0; padding: 0; font-size: large; font-family: monospace; background-color: black; color: white; }
    input { font-family: monospace; background-color: black; color: white; }
    body { height: 100vh; width: 100vw; margin: 0; padding: 0; }
    form { height: 100%; width: 100%; margin: 0; padding: 0; }
    #body { height: 100%; width: 100%; margin: 0; padding: 0; }
    .out { margin: 1% 0 1% 0; border-top: thin solid blue; border-bottom: thin solid blue; }
    .l { width: 100%; margin: 0; padding: 0; }
    .n { padding: 0 1% 0 1%; margin: 0 1% 0 1%; border-right: thin solid red; }
    .e { padding: 0 0 0 1%; border-left: thin solid red; }
    .b { border: thin solid white; color: white; background-color: black; margin: 1%; font-size: xx-large; }
    a { text-decoration: none; color: white; border: thin solid white; }
    #send { background-color: black; color: green; }
  </style>
</head>
<body>
<form id='form' action='/' method='post'>
<div id='ui' style='width: 100%; text-align: center; position: absolute; bottom: 0;'>
)=====";

const char z4_index_tail[] PROGMEM = R"=====(
  </form>
    <script>
    var inp = document.getElementById("input_i");
    function input() {
      if (inp.value != '') {
        var u = "/?i=" + encodeURI(inp.value);
      }      
      inp.value = "";
      fetch(u);
    }

  function ui(x) {
    fetch("/?i=" + encodeURI(x));
  }
  
  function output(s) {
    if (s != undefined) {
      if (s != "") {
        var o = '<div class="out">';
        var a = s.split('\n');
        var l = 0;
        a.forEach(function(e) {
            o += '<p class="l"><span class="n">' + l + '</span><span class="e">' + e + '<span></span></p>'; 
            l++;
        });
        o += '</div>';
        document.getElementById('output').innerHTML = o + document.getElementById('output').innerHTML;
      } else {
        console.log('[ping]');
      }
    }
  }
  var es = new EventSource('/es');
  es.onopen = function(e) { console.log('[es] open', e); output(e.data); };
  es.onmessage = function(e) { console.log('[es]', e); output(e.data); };

  var s = document.getElementById("send");
  s.addEventListener('click', function(ev) {
    ev.preventDefault();
    input(); 
  });

  var s = document.getElementsByClassName('b');
  for(var i = 0; i < s.length; i++) {
    (function(ix) {
      s[ix].addEventListener("click", function(ev) {
         ev.preventDefault();
         console.log("Clicked index: " + ix);
         console.log("Payload: " + ev.target.value);
         ui(ev.target.value);
      })
    })(i);
  }
  
 
  console.info('[Z4] RUN!');
  setTimeout(function() { var uu = "/?i=" + encodeURI("z4(0,6,'app');"); fetch(uu); },250);
  </script>
</body>
</html>
)=====";

const char z4_index_term[] PROGMEM = R"=====(
  </div>
  <div style='width: 100%; text-align: center; padding: 0%; margin: 0 1% 0 1%;'>
  <h3 style='width: 100%; text-align: center; margin: 0; padding: 0; font-size: xx-large;'>
    <input id='input_i' name='i' style='width: 80%; vertical-align: middle; border: thin solid grey; font-size: larger;' placeholder='>'>
    <button type='submit' id='send' style='vertical-align: middle; color: green; border: thin solid green; font-size: larger;'>&gt;</button>
  </h3>
 
  </div>
  <div id='output' style='width: 100%; height: 80%; overflow-y: scroll;'></div>
)=====";
