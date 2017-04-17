# Websocket Client API

### API-Methods/Functions
* ``` websocket.create(function: callback, [boolean: autoTick]):client ``` -- Creates and returns a new client instance. ```callback``` will get called whenever a event accures. If ```autoTick``` is set to false you will have to call the ```update()``` method manually in order to recieve messages (default: true)
* ``` client:connectURL(string: url) ``` -- Connects to a specific server. Error when it can't connect. Example URL: "ws://example.com/path/to/endoint"
* ``` client:connect(host,port,path) ``` -- Connects to a specific server. Error when it can't connect. The base path is "/" and can't be a empty string!
* ``` client:disconnect()``` -- Disconnects the current connection. Error when there is no connection.
* ``` client:update()``` -- Check the input buffer. Will get called automatically by a timer when ```autoTick``` was set to true.
* ``` client:send(string: message) ``` -- Send a messege to the connected server
* ``` client:hasConnection():boolean ``` -- Returns true if there is a open TCP Socket connection to the server.
* ``` client:isConnected():boolean ``` -- Returns true if the Client has a connection to the server and has successfully completed the handshake.


### Callback Events
#### Example callback function 
```
local callback = function(event, var1)
    print("Event "..event.." fired. Var1 = "..var1);
end
local client = websocket.create(callback, true);
```

#### Events
* ```handshake_error(string: error_message)``` -- Handshake with Server failed. The connection gets closed before this event gets fired
* ```close_request()``` -- Server has requested to close the connection. The connection gets closed after this event gets fired
* ```text(string: message) ``` -- String message recieved
* ```error(string: error_message) ``` -- Error occurred while reading message.
* ```msg_unknown(frame: frame) ``` -- Unknown Frame recieved
