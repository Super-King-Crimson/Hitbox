--!strict 

local HitboxMt = {}
HitboxMt.__index = HitboxMt

local HitboxStatic = {}

local VISUALIZER = true
local VISUALIZER_COLOR = {
	ACTIVE = Color3.fromRGB(255, 0, 0),
	NOT_ACTIVE = Color3.fromRGB(255, 255, 255),
	HIT_VALID_PART = Color3.fromRGB(47, 132, 142),
	HIT_INVALID_PART = Color3.fromRGB(255, 255, 0)
}
local VISUAL_BLOCKCAST_TWEEN_PART_COUNT = 2
local VISUAL_HIT_INVALID_NAME = "HIT_INVALID"

local VISUALS = {} :: {[Hitbox]: Model?}
local VISUALIZER_PARENT = Instance.new("Folder")
VISUALIZER_PARENT.Name = "HITBOX_VISUALS"
VISUALIZER_PARENT.Parent = workspace


local Detection = require(script.Detection)
local Signal = require(script.Signal)
local Filter = require(script.Filter)
local PartBind = require(script.PartBind)

local Heartbeat = game:GetService("RunService").Heartbeat

local Hitboxes = {} :: {[Hitbox]: true?}

--STATIC METHODS
function HitboxStatic.new(): Hitbox
	local self = {}
	
	self.caster = workspace :: Filter.Caster 
	self.detection = Detection.PartsInPart.new() :: Detection.Detection
	self.filter = Filter.default :: Filter
	
	self._partBind = nil :: PartBind.PartBind?
	self._hits = {} :: {[Filter.Hit]: true?}
	self._signal = Signal.new() :: Signal.Signal
	self._active = false :: boolean
	self._destroyed = false
	
	setmetatable(self, HitboxMt)
	
	Hitboxes[self] = true
	
	return self
end

function HitboxStatic.from(caster: Filter.Caster, detection: Detection.Detection, filter: Filter): Hitbox
	local self = {}
	
	self.caster = caster
	self.detection = detection
	self.filter = filter or Filter.default
	
	self._partBind = nil :: PartBind.PartBind?
	self._hits = {}
	self._signal = Signal.new() :: Signal.Signal
	self._active = false
	self._destroyed = false
	
	setmetatable(self, HitboxMt)
	Hitboxes[self] = true
	
	return self
end

local function getWorldCFrame(hitbox: Hitbox): CFrame
	local detection = hitbox.detection
	local boundPartOffset: CFrame = if hitbox._partBind then hitbox._partBind.part.CFrame else CFrame.identity 
	
	if detection._pattern == "Detection::PartsInBox" or detection._pattern == "Detection::Blockcast" then
		return boundPartOffset * detection.cframe 
	elseif detection._pattern == "Detection::Spherecast" or detection._pattern == "Detection::PartsInRadius" then
		return boundPartOffset * CFrame.new(detection.position)
	else
		error("Cannot get World CFrame of a Detection type without a cframe or position property", 2)
	end
end

local function getBoundingBox(part: BasePart): Vector3
	local model = Instance.new("Model")
	part:Clone().Parent = model 
	
	model.PrimaryPart = model:GetChildren()[1] :: BasePart
	local boundingBox = model:GetExtentsSize()

	model:Destroy()

	return boundingBox
end


--CLASS METHODS
function HitboxMt.isActive(self: Hitbox): boolean
	return self._active
end

function HitboxMt.activate(self: Hitbox)
	self._active = true
end

function HitboxMt.deactivate(self: Hitbox)
	self._active = false
end

function HitboxMt.destroy(self: Hitbox)
	self:deactivate()
	self:unbindFromPart()
	self._signal:Destroy()
	Hitboxes[self] = nil

	self._destroyed = true
end

function HitboxMt.refresh(self: Hitbox)
	self._hits = {}
end

function HitboxMt.onHit(self: Hitbox, fn: (hit: Filter.Hit) -> ()): Signal.Connection
	return self._signal:Connect(fn)
end

function HitboxMt.onceHit(self: Hitbox, fn: (hit: Filter.Hit) -> ()): Signal.Connection
	return self._signal:Once(fn)
end

function HitboxMt.clone(self: Hitbox): Hitbox
	return HitboxStatic.from(self.caster, self.detection, self.filter)
end

function HitboxMt.unbindFromPart(self: Hitbox)
	if self._partBind then
		self._partBind._onDestroy:Disconnect()
		self._partBind = nil
	end
end

function HitboxMt.bindToPart(self: Hitbox, part: BasePart)
	self:unbindFromPart()
	self._partBind = PartBind.new(part, function()
		self:destroy()
	end)
end

function HitboxMt.query(self: Hitbox): {Instance}?
	if self._destroyed then error("Cannot query a destroyed Hitbox", 2) end
	
	local detection = self.detection :: Detection.Detection

	if detection._pattern == "Detection::PartsInBox" then
		return workspace:GetPartBoundsInBox(getWorldCFrame(self), detection.size, detection.params)
	elseif detection._pattern == "Detection::Blockcast" then
		local result = workspace:Blockcast(getWorldCFrame(self), detection.size, detection.direction, detection.params)
		return if result then {result.Instance} else nil
	elseif detection._pattern == "Detection::PartsInRadius" then
		return workspace:GetPartBoundsInRadius(getWorldCFrame(self).Position, detection.radius, detection.params)
	elseif detection._pattern == "Detection::Spherecast" then
		local result = workspace:Spherecast(getWorldCFrame(self).Position, detection.radius, detection.direction, detection.params) 
		return if result then {result.Instance} else nil
	elseif detection._pattern == "Detection::PartsInPart" then
		return workspace:GetPartsInPart(detection.part, detection.params)
	else
		error("Failed to query: Hitbox did not have a valid Detection type", 2)
	end
end

local function displayHitbox(hitbox: Hitbox): Model
	local detection = hitbox.detection

	local model = Instance.new("Model") :: Model  
	
	if detection._pattern == "Detection::Spherecast" then
		local diameter = detection.radius * 2
		
		local start = Instance.new("Part")
		start.Shape = Enum.PartType.Ball
		start.Position = getWorldCFrame(hitbox).Position
		start.Size = Vector3.one * diameter 
		
		local endPart = start:Clone()
		endPart.Position = start.Position + detection.direction
		
		local endPos, startPos = endPart.Position, start.Position
		local mag = (endPos - startPos).Magnitude
		
		local connector = Instance.new("Part") 
		connector.Shape = Enum.PartType.Cylinder
		
		local midpoint = startPos:Lerp(endPos, 0.5)
		
		connector.CFrame = CFrame.new(midpoint, endPos) * CFrame.Angles(0, math.pi/2, 0) 
		connector.Size = Vector3.new(mag, diameter, diameter)
		
		start.Name = VISUAL_HIT_INVALID_NAME
		
		start.Parent = model
		endPart.Parent = model
		connector.Parent = model
	elseif detection._pattern == "Detection::PartsInPart" then
		detection.part:Clone().Parent = model
	elseif detection._pattern == "Detection::PartsInRadius" then
		local display = Instance.new("Part")
		display.Shape = Enum.PartType.Ball
		display.Position = getWorldCFrame(hitbox).Position
		display.Size = Vector3.one * detection.radius * 2
		display.Parent = model
	elseif detection._pattern == "Detection::PartsInBox" then
		local display = Instance.new("Part")
		display.CFrame = getWorldCFrame(hitbox)
		display.Size = detection.size
		display.Parent = model
	elseif detection._pattern == "Detection::Blockcast" then
		local start = Instance.new("Part")
		
		start.CFrame = getWorldCFrame(hitbox)
		start.Size = detection.size
		
		local endPart = start:Clone()
		endPart.CFrame += detection.direction
		
		local startPos, endPos = start.Position, endPart.Position
		
		for i = 1, VISUAL_BLOCKCAST_TWEEN_PART_COUNT do
			local lerpPercentage = i / (VISUAL_BLOCKCAST_TWEEN_PART_COUNT + 1)
			local lerpPos = startPos:Lerp(endPos, lerpPercentage)

			local tweenPart = start:Clone()
			tweenPart.Position = lerpPos
			tweenPart.Parent = model
		end
		
		local connector = Instance.new("Part")
		connector.CFrame = CFrame.new(startPos:Lerp(endPos, 0.5), endPos) * CFrame.Angles(0, math.pi/2, 0)
		connector.Size = Vector3.new((endPos-startPos).Magnitude, 1, 1)
		connector.Parent = model
		
		start.Name = VISUAL_HIT_INVALID_NAME
		
		start.Parent = model
		endPart.Parent = model
	end
	
	 
	for _, child in model:GetChildren() do
		if child:IsA("Part") then
			child.Transparency = 0.5
			child.Color = if hitbox:isActive() then VISUALIZER_COLOR.ACTIVE else VISUALIZER_COLOR.NOT_ACTIVE
			
			if child.Name == VISUAL_HIT_INVALID_NAME then
				child.Color = VISUALIZER_COLOR.HIT_INVALID_PART
			end
			
			child.Anchored = true
			child.CanCollide = false
			child.CanQuery = false
			child.CanTouch = false
			child.CastShadow = false
			child.Material = Enum.Material.SmoothPlastic
		end
	end
	
	model.Name = `{hitbox.caster.Name}Hitbox`
	model.Parent = VISUALIZER_PARENT
	
	return model
end

local function updateHitboxes(deltaTime: number?)
	if VISUALIZER then
		for hitbox, model in VISUALS do
			(VISUALS[hitbox]::Model):Destroy() 
			VISUALS[hitbox] = if Hitboxes[hitbox] then displayHitbox(hitbox) else nil
		end
	end
	
	for hitbox, _ in Hitboxes do
		if VISUALIZER then
			if not VISUALS[hitbox] then
				VISUALS[hitbox] = displayHitbox(hitbox)
			end
		end
		
		if not hitbox:isActive() then continue end
		
		local hits = hitbox:query()
		if hits then
			for _, hit in hits do
				local filteredHit = hitbox.filter(hit, hitbox.caster)

				if not filteredHit then 
					continue 
				elseif hitbox._hits[filteredHit] then
					if VISUALIZER then
						for _, child in (VISUALS[hitbox]::Model):GetChildren() do
							if child:IsA("BasePart") then
								child.Color = VISUALIZER_COLOR.HIT_VALID_PART
							end
						end
					end
					continue
				else
					hitbox._hits[filteredHit] = true
					hitbox._signal:Fire(filteredHit)
				end 
			end
		end
	end
end 
Heartbeat:Connect(function(dt)
	updateHitboxes(dt)
end)


HitboxStatic.Detection = Detection
HitboxStatic.Filter = Filter

export type Filter = Filter.Filter
export type Caster = Filter.Caster
export type Hit = Filter.Hit
export type Detection = Detection.Detection

export type HitboxStatic = typeof(HitboxStatic)

export type Hitbox = typeof(HitboxStatic.new()) 

return HitboxStatic :: HitboxStatic