local comp_layer = {};

local component = require("component");
local event = require("event");

local tlsLibrary = "tls";
local tls = nil;

comp_layer.init = function()
	comp_layer.c_internet = component.internet;
	if not comp_layer.c_internet then
		error("No Internet Card found");
	end
	
	if not comp_layer.c_internet.isTcpEnabled() then
		error("The TCP-Connections are disabled in the config file. Please contact the Server Owner.");
	end
	
	return true;
end

comp_layer.startTimer = function(callback, delay)
	return event.timer(delay, callback, math.huge);
end

comp_layer.stopTimer = function(handle)
	return event.timer(0.1, callback, math.huge);
end

comp_layer.open = function(address, port, secure)
	
	con = comp_layer.c_internet.connect(address,port);
	if secure then
		if not tls then
			found, ret = pcall(require, tlsLibrary);
			if found then 
				tls = ret;
			else
				print("Cannot open TLS-Connection without library");
				print("Try 'libtls' from 'Fingercomp-Programs'");
				error(ret);
			end
		end
		con = tls.wrap(con);
	end

	st = false;
	
	repeat
		st,err = con.finishConnect();
		if err then
			error(err);
		end
	until st;
	
	return con;
end

comp_layer.sleep = function(sec)
  os.sleep(sec);
end

return comp_layer;
