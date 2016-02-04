-- DS18B20 - Pin 4 GPIO 0
-- WS2812 - Pin 3 GPIO 2

local tempDecimal = 0 -- Temp store
local ledSet = 0  -- LED flag store

function getTemp() -- Reads to ds18b20 sensor to get temp

  t = require("ds18b20")

  t.setup(4) -- DS18B20 connected to pin 4 GPIO 0
  addrs = t.addrs()
  if (addrs ~= nil) then
    print("Total DS18B20 sensors: "..table.getn(addrs))
  end

  -- Just read temperature
  print("Temperature: "..t.read().."C")
  temp = t.read()
  -- Don't forget to release it after use
  t = nil
  ds18b20 = nil
  package.loaded["ds18b20"]=nil

end 

function colourChange() -- Handles the ws2812 led

  if (ledSet == 0) then -- If led flag 0 then turn ws2812 on and run these if statments

    if tempDecimal >= "20" and tempDecimal <= "30" then
      ws2812.writergb(3, string.char(0, 0, 255):rep(1)) -- ws2812 red
      ws2812.writergb(3, string.char(255, 0, 0):rep(1)) -- ws2812 red
      ledColour = "Red"

    elseif  "15" <= tempDecimal and tempDecimal <= "19.9" then
      ws2812.writergb(3, string.char(127, 127, 0):rep(1)) -- ws2812 orange
      ledColour = "Orange"

    elseif  "10" <= tempDecimal and tempDecimal <= "14.9" then
      ws2812.writergb(3, string.char(0, 127, 127):rep(1)) --ws2812 light blue 
      ledColour = "Light blue"

    else
      ws2812.writergb(3, string.char(0, 255, 0):rep(1)) --  ws2812 blue
      ws2812.writergb(3, string.char(0, 0, 255):rep(1)) --  ws2812 blue
      ledColour = "Blue"
    end

  else -- If ledset flag is other then 0 then turn ws2812 led off

    ws2812.writergb(3, string.char(0, 0, 0)) -- Off
    ws2812.writergb(3, string.char(0, 0, 0)) -- Off

  end

end


function readTemp()

  getTemp() -- Reads the ds18b20 sensor

  -- This is used to compensate for the first reading from the ds18b20 being 85 , Think this is because of the library in using --
  if temp == 85 then
    while temp == 85 do -- First 2 reading are normaly 85 so hence the while loop
      print("Reloading")
      getTemp()
      tempDecimal = string.format("%0.1f", temp)
      print("Decimal"..tempDecimal)
--      tempDecimal = temp
    end
  else -- If the ds18b20 sensor reads under 85 then everything is normal
    getTemp()
    -- converts to 1 decimal place
    tempDecimal = string.format("%0.1f", temp)
    print("Decimal"..tempDecimal)
  end

  colourChange() -- Sets the ws2812 colour

  -- Send data to thinkspeak start -- 
  print("Sending data to thingspeak.com")
  conn=net.createConnection(net.TCP, 0) 
  conn:on("receive", function(conn, payload) print(payload) end)
  conn:connect(80,'184.106.153.149') 

    conn:send("GET /update?key=APIKEYHERE&field1="..tempDecimal.." HTTP/1.1\r\n") 

  conn:send("Host: api.thingspeak.com\r\n") 
  conn:send("Accept: */*\r\n") 
  conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
  conn:send("\r\n")
  conn:on("sent",function(conn)
    print("Closing connection")
    conn:close()
  end)
  conn:on("disconnection", function(conn)
    print("Got disconnection...")
  end)

  -- Send data to thinkspeak end -- 
  
end

-- web server start --
srv=net.createServer(net.TCP)
srv:listen(80,function(conn)
  conn:on("receive", function(client,request)
    local buf = "";
    local _, _, method, path, vars = string.find(request, "([A-Z]+) (.+)?(.+) HTTP");
    if(method == nil)then
        _, _, method, path = string.find(request, "([A-Z]+) (.+) HTTP");
    end
    local _GET = {}
    if (vars ~= nil)then
      for k, v in string.gmatch(vars, "(%w+)=(%w+)&*") do
        _GET[k] = v
      end
    end
    buf = buf.."<h1> Beta temp logger</h1>";
    buf = buf.."<p>Temp "..tempDecimal.."C";

    buf = buf.."<p>WS2812 <a href=\"?pin=ON1\"><button>ON</button></a>&nbsp;<a href=\"?pin=OFF1\"><button>OFF</button></a></p>";
    local _on,_off = "",""
    if(_GET.pin == "ON1")then
      buf = buf.."<p>WS2812 is on";
      ledSet = 0 -- Led set flag
      colourChange()
    elseif(_GET.pin == "OFF1")then
      buf = buf.."<p>WS2812 is off";
      ws2812.writergb(3, string.char(0, 0, 0)) -- Off
      ws2812.writergb(3, string.char(0, 0, 0)) -- Off
      ledSet = 1  -- Led set flag
    end

    client:send(buf);
    client:close();
    collectgarbage();
  end)
-- web server end --

end)

--tmr.alarm(0, 10000, 1, function() readTemp() end ) -- 10 seconds
tmr.alarm(0, 900000, 1, function() readTemp() end ) -- 15 mins
--tmr.alarm(0, 300000, 1, function() readTemp() end ) -- 5 mins
