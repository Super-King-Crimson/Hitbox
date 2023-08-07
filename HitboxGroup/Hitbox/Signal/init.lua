--!strict

local Connection = require(script.Connection)

local SignalStatic = {}
local SignalMt = {} :: SignalMt
SignalMt.__index = SignalMt  

--STATIC METHODS
function SignalStatic.new(): Signal
	return setmetatable({
		_conns = {}::{[Connection]: boolean?},
		_destroyed = false::boolean,
	}, SignalMt)
end


--CLASS METHODS
function SignalMt.Connect(self: Signal, fn: (...any) -> ()): Connection
	if self._destroyed then error("Failed to connect: attempted to connect to destroyed signal", 2) end
	
	local newConn = Connection.new(fn)
	
	Connection._initDestroyer(newConn, function() 
		self._conns[newConn] = nil
	end)
	
	self._conns[newConn] = true
	
	return newConn
end

function SignalMt.Once(self: Signal, fn: (...any) -> ()): Connection	
	local newConn = self:Connect(function() end)
	
	newConn._fn = function(...)
		fn(...)
		newConn:Disconnect()
	end

	return newConn
end

function SignalMt.Fire(self: Signal, ...: any)
	local args = {...}
	
	for conn, _ in self._conns do
		task.spawn(function()
			conn._fn(table.unpack(args)) 
		end)
	end
end

function SignalMt.DisconnectAll(self: Signal)
	for conn in self._conns do
		conn:Disconnect()
	end
end

function SignalMt.Destroy(self: Signal)
	self:DisconnectAll()
	self._destroyed = true
end

function SignalMt.Wait(self: Signal): number
	local tracker = false
	local timePassed = 0
	
	self:Once(function()
		tracker = true
	end)
	
	while tracker == false do
		timePassed += task.wait()
	end
	
	return timePassed
end 

--DO NOT FORGET THIS
type SignalMt = {
	Connect: (Signal, (...any) -> ()) -> Connection,
	Once: (Signal, (...any) -> ()) -> Connection,
	Destroy: (Signal) -> (),
	Fire: (Signal, ...any) -> (),
	DisconnectAll: (Signal) -> (),
	Wait: (Signal) -> (number),
	
	__index: SignalMt,
}

export type Connection = Connection.Connection

export type Signal = typeof(SignalStatic.new())

export type SignalStatic = typeof(SignalStatic)

return SignalStatic :: SignalStatic