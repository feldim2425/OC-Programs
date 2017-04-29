--modular code
local application = "Websocket API"
local dlTbl = {
  {link = "https://raw.githubusercontent.com/feldim2425/OC-Programs/master/websocket_client/websocket_client.lua", file = "/usr/lib/websocket_client.lua"},
  {link = "https://raw.github.com/feldim2425/OC-Programs/master/websocket_client/websocket/ws_component_layer.lua", file = "/usr/lib/websocket/ws_component_layer.lua"},
  {link = "https://raw.github.com/feldim2425/OC-Programs/master/websocket_client/websocket/ws_tools.lua", file = "/usr/lib/websocket/ws_tools.lua"}
}

--internal

local component = require("component")
local fs = require("filesystem")
local shell = require("shell")
local term = require("term")

if not component.internet then
  error("Need a internet card!")
end
local internet = require("internet")


local function writeFile(data,name)
  if fs.exists(name) then
    fs.remove(name)
  else
    local path = fs.path(name)
    if path then
      local pSeg = fs.segments(path)
      local pCur = "/"
      for _, seg in pairs(pSeg) do
        pCur = fs.concat(pCur, seg)
        if not fs.exists(pCur) then
          fs.makeDirectory(pCur)
        end
      end
    end
   end
   
   local file = io.open(name, "wb")
   if file == nil then
     return false
   end
   file:write(data)
   file:close()
   return true
end

print("FeldM2425 software download tool")
print("Downloading "..application)


local termW, termH,_,_,_,termY = term.getViewport()
term.setCursor(1,termY)

if termY+5 >= termH then
  termY = termH-5
  for i=1,5 do
    print("")
  end
end

local step = 100 / #dlTbl
local percent = 0
local barMlen = (termW-8)
local cstep =  barMlen / 100

term.setCursor(1,termY+2)
term.write(string.format("% 5.1f%% ",percent)..string.rep("░",barMlen))

for _,pk in pairs(dlTbl) do
  term.setCursor(1,termY+3)
  term.write(pk.file)
  
  local webData = internet.request(pk.link)
  if not webData then
    term.setCursor(1,termY+5)
    print("Error while downloading "..pk.link)
    return
  end
  
  local content = ""
  for chunk in webData do
    content = content..chunk
  end
  
  if not writeFile(content, pk.file) then
    term.setCursor(1,termY+5)
    print("Error while writing "..pk.file)
    return
  end
  
  percent = percent + step

  term.setCursor(1,termY+2)
  barLen = math.floor(percent * cstep + 0.5)
  term.write(string.format("%5.1f%% ",percent)..string.rep("█",barLen)..string.rep("░",barMlen-barLen))
end

term.setCursor(1,termY+5)
print("Done")

