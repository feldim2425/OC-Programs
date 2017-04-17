local comp_layer = {};

local component = require("component");

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


comp_layer.open = function(address, port)
	con = comp_layer.c_internet.connect(address,port);
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
