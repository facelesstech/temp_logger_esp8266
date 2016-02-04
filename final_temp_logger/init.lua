--init.lua

cnt = 0 -- Stores the connection attemps

print("Setting up WIFI...") -- Print to screen
wifi.setmode(wifi.STATION) -- Set wifi credentials mode
--modify according your wireless router settings
wifi.sta.config("SSID","PASSWORD") -- Set wifi credentials
wifi.sta.connect() -- Connects to wifi

print("Atempting connection") -- Print to screen

tmr.alarm(1, 1000, 1, function()
  if wifi.sta.getip() == nil then -- Atempts to acquire ip address
    cnt = cnt + 1 -- Increment number after each attempt
    print("(" .. cnt .. ") Waiting for IP...") -- Print to screen
      if cnt == 10 then -- After 10 atemps to connect launch set wifi script
        tmr.stop(1) -- Stop timer
        dofile("setwifi.lua") -- Launch set wifi script
      end
  else
    tmr.stop(1) -- Stop timer
    print("Loading script...") -- Print to screen
    dofile("final_temp_logger.lua") -- Launch script
  end
end)
