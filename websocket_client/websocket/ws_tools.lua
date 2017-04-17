local ws_tool = {};

ws_tool.generate_key = function()
	return ws_tool.toBase64(tostring(math.random(9999999999)));
end

ws_tool.upgrade = function(host,uri,port)
  key = ws_tool.generate_key();
  req = "GET " .. uri .. " HTTP/1.1\r\n";
  req = req .. "Host: " .. host .. ":" .. port .."\r\n";
  req = req .. "Upgrade: websocket\r\n";
  req = req .. "Connection: Upgrade\r\n";
  req = req .. "Sec-WebSocket-Key: " .. key .."\r\n";
  req = req .. "Sec-WebSocket-Protocol: chat\r\n";
  req = req .. "Sec-WebSocket-Version: 13\r\n\r\n";
  
  return req, key;
end

ws_tool.verifyUpgrade = function(key,message)
  head = true;
  data = {};
  for line in message:gmatch("[^\r\n]*") do
    if head then
      if line=="HTTP/1.1 101 Switching Protocols" then
        head = false;
      else
        return false, "Wrong HTTP-Code";
      end
    else
      hkey, hval = line:match("([^%s:]*): ([^%s:]*)");
      if hkey and hval then
	    data[hkey] = hval;
	  end
    end
  end
  
  if data["Upgrade"] ~= "websocket" or data["Connection"] ~= "Upgrade" then
    return false, "Wrong Handshake. Server doesn't support Websocket";
  end
  
  if data["Sec-WebSocket-Protocol"] ~= "chat" and data["Sec-WebSocket-Protocol"] ~= nil then
    return false, "Server doesn't support \"chat\"-protocol";
  end
  
  return true;
end

ws_tool.readFrame = function(data)
  frame = {};
  
  --1. byte
  msk_fin = data[1] & 0x80;
  if msk_fin ~= 0 then
    frame.fin = 1;
  else
    frame.fin = 0;
  end
  frame.opcode = data[1] & 0x0f;
  
  --2. byte
  mmask = 0;
  msk_mask = data[2] & 0x80;
  if msk_mask ~= 0 then
     mmask = 1;
  end
  len1 = data[2] & 0x7f;
  
  offset = 2;
  
  --(extendet len) 3, 4, 5, 6, 7, 8 byte 
  if len1 <= 125 then
    frame.len = len1;
  elseif len1 == 126 then
    frame.len = 0;
    for i=1, 2 do
       frame.len = (frame.len << 8) | data[offset+i];
    end
    offset = offset + 2;
  else
    frame.len = 0;
    for i=1, 8 do
       frame.len = (frame.len << 8) | data[offset+i];
    end
    offset = offset + 8;
  end
  
  msk = {0,0,0,0}
  if mmask == 1 then
    frame.mask = 0;
    for i = 1, 4 do
      mb = data[offset+i];
      msk[i] = mb;
      frame.mask = (frame.mask<<8) | mb;
    end
    offset = offset + 4;
  end
  
  --mask bytes
  frame.dat = {};
  for i=1, frame.len do
    table.insert(frame.dat, data[offset+i] ~ msk[((i-1)%4)+1]);
  end
  
  return frame;
end

ws_tool.makeFrame = function(data)
  bytes = {};
  
  --1. byte
  m_fin = 0x00;
  if data.fin then
     m_fin = 0x80;
  end
  m_opcode = ( data.opcode or 0x00 ) & 0x0f;
  table.insert(bytes, m_fin | m_opcode);
  
  --2. byte
  m_mask = 0x00;
  if data.mask then
    m_mask = 0x80;
  end
  
  m_len1 = 0x00;
  if data.len <= 125 then
    m_len1 = data.len
  elseif data.len <= 0xffff then
    m_len1 = 126;
  else
    m_len1 = 127;
  end
  table.insert(bytes, m_mask | m_len1);
  
  --(extended len) 3, 4, 5, 6, 7, 8 byte 
  if m_len1 > 125 then
    if m_len1 == 126 then
      table.insert(bytes, (data.len >> 8) & 0xff)
      table.insert(bytes, data.len & 0xff);
    elseif m_len1 == 127 then
      table.insert(bytes, (data.len >> 56) & 0xff);
      table.insert(bytes, (data.len >> 48) & 0xff);
      table.insert(bytes, (data.len >> 40) & 0xff);
      table.insert(bytes, (data.len >> 32) & 0xff);
      table.insert(bytes, (data.len >> 24) & 0xff);
      table.insert(bytes, (data.len >> 16) & 0xff);
      table.insert(bytes, (data.len >> 8) & 0xff);
      table.insert(bytes, data.len & 0xff);
    end
  end
  
  --mask bytes
  msk = {0,0,0,0};
  if data.mask then
    msk[1] = (data.mask >> 24) & 0xff;
    msk[2] = (data.mask >> 16) & 0xff;
    msk[3] = (data.mask >> 8) & 0xff;
    msk[4] = data.mask & 0xff;
    table.insert(bytes, msk[1]);
    table.insert(bytes, msk[2]);
    table.insert(bytes, msk[3]);
    table.insert(bytes, msk[4]);
  end
  
  for i=1, data.len do
    table.insert(bytes, data.dat[i] ~ msk[((i-1)%4)+1]);
  end
  
  return bytes;
end

ws_tool.generateMask = function()
  return math.random(0xffffffff);
end

ws_tool.fromByteArray = function(bytes)
  str = '';
  for _,b in pairs(bytes) do
	str = str..string.char(b);
  end
  return str;
end

ws_tool.toByteArray = function(str)
  return { string.byte(str, 1, -1) };
end

local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

ws_tool.toBase64 = function(data)
  return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

ws_tool.parseUrl = function(url)
  prot,host,port,path = url:match("^([a-zA-Z0-9_]+://)([a-zA-Z0-9._]+):?([0-9]*)([^&%%?]*)$");

  if not prot then
    error("URL-Malformed");
  end
	
  if prot ~= "ws://" then
    error("Wrong URI-Protocol! Expected \"ws://\" and got \""..prot.."\"");
  end
  
  if port:len() == 0 then
    port = nil;
  end
  
  if path:len() == 0 then
    path = nil;
  end
  
  return host, port, path;
end

return ws_tool;
