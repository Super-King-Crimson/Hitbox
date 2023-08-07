--!strict

local Hitbox = require(script.Hitbox)
local Signal = require(script.Hitbox.Signal)
local Filter = require(script.Hitbox.Filter)

local HitboxGroupStatic = {}

local HitboxGroupMt = {}
HitboxGroupMt.__index = HitboxGroupMt

local LOWEST_PRIORITY = 0

--STATIC METHODS:
function HitboxGroupStatic.new(): HitboxGroup
	local self = {}
	
	self._members = {} :: {HitboxMemberProps}
	self._signal = Signal.new()
	self._destroyed = false
	self._hits = {} :: {[Filter.Hit]: true?}
	self._highestPriority = -1 :: number
	
	setmetatable(self, HitboxGroupMt)
	
	return self
end

function HitboxGroupStatic.from(members: {HitboxMemberProps}): HitboxGroup
	local self = {}
	
	self._signal = Signal.new()
	self._destroyed = false
	self._members = {}
	self._hits = {}
	self._highestPriority = -1
	
	setmetatable(self, HitboxGroupMt)
	
	for _, member in members do
		self:addMember(member.hitbox)
	end
	
	return self
end

--CLASS METHODS:
local function isInGroupOrHasPriority(group: HitboxGroup, otherHitbox: Hitbox.Hitbox, priority: number?):"hitbox is already a member" | "cannot assign more than one hitbox the same priority" | nil
	for _, member in ipairs(group._members) do
		if otherHitbox == member.hitbox then
			return "hitbox is already a member"
		elseif priority and priority == member.priority then
			return "cannot assign more than one hitbox the same priority"
		end
	end
	
	return nil
end

function HitboxGroupMt.addMember(self: HitboxGroup, other: Hitbox.Hitbox, hitPriority: number?)
	local priority = hitPriority or self._highestPriority + 1
	
	if priority < LOWEST_PRIORITY then
		error(`Failed to add hitbox to group: hitbox priority must be greater than {LOWEST_PRIORITY}`)
	end
	
	if self._destroyed then
		error("Failed to add hitbox to group: cannot add members to a destroyed Hitbox Group")
	end
	
	local cannotAddAsMember = isInGroupOrHasPriority(self, other, priority)
	
	if cannotAddAsMember then 
		error(`Failed to add hitbox to group: {cannotAddAsMember}`, 2) 
	end
	
	local newMember = {
		hitbox = other,
		priority = priority,
	}
	
	newMember.hitbox:onHit(function(hit)
		task.defer(function()
			for myHit, _ in newMember.hitbox._hits do
				if self._hits[myHit] then continue end 					
				
				local hitIsOnMyPriority = true
				
				for _, otherMember in self._members do
					if otherMember == newMember then continue end
					if otherMember.hitbox._hits[myHit] and otherMember.priority > newMember.priority then
						hitIsOnMyPriority = false
						break 
					end
				end
				
				if hitIsOnMyPriority then
					self._hits[myHit] = true
					self._signal:Fire(myHit, newMember.priority)
				end
			end
		end)
	end)
	
	table.insert(self._members, newMember)
	if priority > self._highestPriority then 
		self._highestPriority = priority 
	end
end

function HitboxGroupMt.deactivateGroup(self: HitboxGroup)
	for _, member in self._members do
		member.hitbox:deactivate()
	end
end

function HitboxGroupMt.activateGroup(self: HitboxGroup)
	for _, member in self._members do
		member.hitbox:activate()
	end
end

function HitboxGroupMt.refreshGroup(self: HitboxGroup)
	for _, member in self._members do
		member.hitbox:refresh()
	end
end

function HitboxGroupMt.destroyGroup(self: HitboxGroup)
	for _, member in self._members do
		member.hitbox:destroy()
	end
	
	self._destroyed = true
end

function HitboxGroupMt.bindGroupToPart(self: HitboxGroup, part: BasePart)
	for _, member in self._members do
		member.hitbox:bindToPart(part)
	end
end

function HitboxGroupMt.onGroupHit(self: HitboxGroup, fn: (hit: Filter.Hit, priority: number) -> ()): Signal.Connection
	return self._signal:Connect(fn)
end

function HitboxGroupMt.onceGroupHit(self: HitboxGroup, fn: (hit: Filter.Hit, priority: number) -> ()): Signal.Connection
	return self._signal:Once(fn)
end

export type HitboxGroup = typeof(HitboxGroupStatic.new())
export type HitboxMemberProps = {hitbox: Hitbox.Hitbox, priority: number}


export type HitboxGroupStatic = typeof(HitboxGroupStatic)
return HitboxGroupStatic :: HitboxGroupStatic
