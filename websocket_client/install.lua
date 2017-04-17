print("Start downloading Websocket-Client ....");
os.execute("mkdir /usr/lib/websocket");
os.execute("wget https://raw.githubusercontent.com/feldim2425/OC-Programs/master/websocket_client/websocket_client.lua /usr/lib/websocket_client.lua -f");
os.execute("wget https://raw.github.com/feldim2425/OC-Programs/master/websocket_client/websocket/ws_component_layer.lua /usr/lib/websocket/ws_component_layer.lua -f");
os.execute("wget https://raw.github.com/feldim2425/OC-Programs/master/websocket_client/websocket/ws_tools.lua /usr/lib/websocket/ws_tools.lua -f");
print("Done");
