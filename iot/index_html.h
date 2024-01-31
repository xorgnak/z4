const char z4_index_html[] PROGMEM = R"=====(
<!DOCTYPE html>
<html>
  <head>
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <style>
    html { height: 100%; width: 100%; margin: 0; padding: 0; font-size: xx-small; font-family: monospace; background-color: black; color: white; }
    input { font-family: monospace; background-color: black; color: white; }
    body { height: 100vh; width: 100vw; margin: 0; padding: 0; }
    form { height: 100%; width: 100%; margin: 0; padding: 0; }
    #body { height: 100%; width: 100%; margin: 0; padding: 0; }
    .out { margin: 1% 0 1% 0; border: thin solid grey; }
    .body { width: 100%; margin: 0; padding: 0; }
    .line { padding: 0 1% 0 1%; border-right: thin solid grey; }
    a { text-decoration: none; }
    #send { background-color: black; color: grey; }
  </style>
</head>
<body>
  <form id='form' action='/' method='post'>
  <div style='width: 100%; text-align: center; padding: 0; margin: 0;'>
  <h1 style='width: 100%; text-align: center; margin: 0; padding: 0; font-size: large;'>
    <input id='input_i' name='i' list='inputs' style='width: 80%;' placeholder='z4 v1.0.0 (c) 2023'>
    <button type='submit' id='send'>#</button>
  </h1>
 
  </div>
  <div id='output' style='width: 100%; height: 80%; overflow-y: scroll;'></div>
  </form>
    <script>
  function input() {
    var i = document.getElementById("input_i");
    if (i.value != '') {
      var u = "/eval?i=" + encodeURI(i.value);
    }      
    i.value = "";
    fetch(u);
  }
  
  function output(s) {
    if (s != undefined) {
      if (s != "") {
        var o = '<div class="out">';
        var a = s.split('\n');
        var l = 0;
        a.forEach(function(e) {
            o += '<p class="body"><span class="line">' + l + '</span>' + e + '</p>'; 
            l++;
        });
        o += '</div>';
        var i = document.getElementById('output').innerHTML;
        document.getElementById('output').innerHTML = o + i;
      } else {
        console.log('[ping]');
      }
    }
  }
  var es = new EventSource('/events');
  es.onopen = function(e) { console.log('[es] open', e); output(e.data); };
  es.onmessage = function(e) { console.log('[es]', e); output(e.data); };

  var s = document.getElementById("send");
  s.addEventListener('click', function(ev) {
    ev.preventDefault();
    input(); 
  });
  console.info('[Z4] RUN!');
  setTimeout(function() { var uu = "/eval?i=" + encodeURI("hi();"); fetch(uu); },500);
  </script>
</body>
</html>

)=====";
String index_html = String(z4_index_html);
