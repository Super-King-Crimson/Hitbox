--!strict 
local ConnectionStatic = {}
local ConnectionMt = {} :: ConnectionMt
ConnectionMt.__index = ConnectionMt


--STATIC METHODS
function ConnectionStatic.new(fn: (...any) -> ()): Connection
	return setmetatable({
		_fn = fn,
		_connected = true,
		_destroyer = function() end,
	}, ConnectionMt)
end

function ConnectionStatic._initDestroyer(self: Connection, destroyerFn: () -> ())
	self._destroyer = destroyerFn
end 

--CLASS METHODS
function ConnectionMt.IsConnected(self: Connection)
	return self._connected
end

function ConnectionMt.Disconnect(self: Connection)
	if self._connected then
		self._connected = false
		self._destroyer()
	end
end


--DO NOT FORGET THIS MAKE SURE THE CLASS HAVE THESE IF THEY'RE CHANGED
type ConnectionMt = {
	Disconnect: (Connection) -> (),
	IsConnected: (Connection) -> (boolean),
	__index: ConnectionMt,
}

 
export type Connection = typeof(ConnectionStatic.new(function() end))
export type ConnectionStatic = typeof(ConnectionStatic)

return ConnectionStatic :: ConnectionStatic
