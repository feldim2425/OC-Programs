local layer = require("websocket/ws_component_layer");
local tools = require("websocket/ws_tools");
local event = require("event");

local Wsclient = {};
Wsclient.__index = Wsclient;

layer.init();
--INTERNAL
local function endConnection(client)
  client._con.close();
  client._con = nil;
  client._connected = false;
  
  --Cancel Timer [OpenComputers]
  if client._timer then
    event.cancel(client._timer);
    client._timer = nil
  end
end

--Create a new client
-- evF = callback function for events
function Wsclient.create(evF, autoUpdate)
  local cl  = {};
  setmetatable(cl,Wsclient);
  
  cl._autoUpdate = autoUpdate;
  
  if evF~=nil then
    cl._callback = evF;
  else
    cl._callback = function() end;
  end
  
  return cl;
end

--connect to given url
--Example URL: "ws://example.com/any/path"
function Wsclient:connectURL(url)
    host,port,path = tools.parseUrl(url);
    self:connect(host, tonumber(port), path);
end

--connect to server
function Wsclient:connect(host,port,path)
  if self:hasConnection() then
    error("Already Connected!");
  end

  self._host = host;
  self._port = port or 80;
  self._path = path or "/";

  self._con = layer.open(self._host, self._port);
  if not self._con then
    error("Unknown error while connecting. Connection = nil");
  end
  
  upgrade_req, self._key = tools.upgrade(self._host, self._path, self._port);
  self._con.write(upgrade_req);
  
  --Start Timer [OpenComputers]
  if self._autoUpdate == nil or self._autoUpdate then
    self._timer = event.timer(0.1, function() self:update() end, math.huge);
  end
  
end

--check network input
function Wsclient:update()
  if not self._con then
    return;
  end
  
  data = "";
  word = "";
  
  repeat
    word = self._con.read();
    data = data..word;
  until word==nil or word:len() < 1;
  
  if not data or data:len() < 1 then
    return;
  end
  
  fmsg = tools.toByteArray(data);
  
  if not self._connected then
    stat, err = tools.verifyUpgrade(self._key, data);
    if stat then
      self._connected = true;
      if err then
        fmsg = err;
      else
        return;
      end
    else
      endConnection(self)
      self._callback('handshake_error', err);
      return;
    end
   
  end
  
  while fmsg ~= nil do
  
    frame, fmsg = tools.readFrame(fmsg);
  
    if frame.opcode == 0x08 then -- close request
      self._callback('close_request', tools.fromByteArray(frame.dat));
      self:disconnect();
    elseif frame.opcode == 0x01 then -- text message
      self._callback('text', tools.fromByteArray(frame.dat));
    elseif frame.opcode == 0x09 then -- ping
       self._con.write(tools.fromByteArray(tools.makeFrame({fin=1, opcode=0x0a, mask=tools.generateMask(), len=frame.len, dat = frame.dat})));
    else
      if not frame.fin then
        self._callback('error', "Cannot handle continuous messages");
      else
        self._callback('msg_unknown', frame);
      end
    end
  end
  
end

--disconnect
function Wsclient:disconnect()
  if not self:hasConnection() then
    return false;
  end
  
  self._con.write(tools.fromByteArray(tools.makeFrame({fin=1, opcode=8, mask=0xffffffff, len=0, dat = {}})));
  
  layer.sleep(0.5);
  self._con.read();
  endConnection(self);
end

function Wsclient:send(message)
  if self:isConnected() then
    self._con.write(tools.fromByteArray(tools.makeFrame({fin=1, opcode=1, mask=tools.generateMask(), len=#message, dat = tools.toByteArray(message)})));
  end
end

--is connected
function Wsclient:isConnected()
	return self._con ~= nil and self._connected;
end

--has running tcp connection
function Wsclient:hasConnection()
	return self._con ~= nil;
end

return Wsclient;
