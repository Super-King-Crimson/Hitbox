--!strict

local DetectionStatic = {}

type PartsInBoxPattern = "Detection::PartsInBox"
type PartsInPartPattern = "Detection::PartsInPart"
type PartsInRadiusPattern = "Detection::PartsInRadius"
type BlockcastPattern = "Detection::Blockcast"
type SpherecastPattern = "Detection::Spherecast"

DetectionStatic.Enum = {
	PartsInBox = "Detection::PartsInBox",
	PartsInPart = "Detection::PartsInPart",
	PartsInRadius = "Detection::PartsInRadius",
	Blockcast = "Detection::Blockcast",
	Spherecast = "Detection::Spherecast",
} :: {
	PartsInBox: PartsInBoxPattern,
	PartsInPart: PartsInPartPattern,
	PartsInRadius: PartsInRadiusPattern,
	Blockcast: BlockcastPattern,
	Spherecast: SpherecastPattern,
}

local PartsInBox = {}
function PartsInBox.new(): PartsInBox
	return {
		_pattern = DetectionStatic.Enum.PartsInBox :: PartsInBoxPattern,
		cframe = CFrame.identity :: CFrame,
		size = Vector3.zero :: Vector3,
		params = nil :: OverlapParams?,	
	}
end

function PartsInBox.from(cframe: CFrame, size: Vector3, params: OverlapParams?): PartsInBox
	return {
		_pattern = DetectionStatic.Enum.PartsInBox,
		cframe = cframe,
		size = size,
		params = params,	
	}
end


local PartsInPart = {}
function PartsInPart.new(): PartsInPart
	return {
		_pattern = DetectionStatic.Enum.PartsInPart :: PartsInPartPattern,
		part = Instance.new("Part") :: BasePart,
		params = nil :: OverlapParams?,	
	}
end

function PartsInPart.from(part: BasePart, params: OverlapParams?): PartsInPart
	return {
		_pattern = DetectionStatic.Enum.PartsInPart :: PartsInPartPattern,
		part = part,
		params = params,	
	}
end

local PartsInRadius = {}
function PartsInRadius.new(): PartsInRadius
	return {
		_pattern = DetectionStatic.Enum.PartsInRadius :: PartsInRadiusPattern,
		position = Vector3.zero :: Vector3,
		radius = 0 :: number,
		params = nil :: OverlapParams?,	
	}
end

function PartsInRadius.from(position: Vector3, radius: number, params: OverlapParams?): PartsInRadius
	return {
		_pattern = DetectionStatic.Enum.PartsInRadius :: PartsInRadiusPattern,
		position = position,
		radius = radius,
		params = params,
	}
end

local Blockcast = {}
function Blockcast.new(): Blockcast
	return {
		_pattern = DetectionStatic.Enum.Blockcast :: BlockcastPattern,
		cframe = CFrame.identity :: CFrame,
		size = Vector3.zero :: Vector3,
		direction = Vector3.zero :: Vector3,
		params = nil :: RaycastParams?,	
	}
end

function Blockcast.from(cframe: CFrame, size: Vector3, direction:Vector3, params: RaycastParams?): Blockcast
	return {
		_pattern = DetectionStatic.Enum.Blockcast,
		cframe = cframe,
		size = size,
		direction = direction,
		params = params,	
	}
end

local Spherecast = {}
function Spherecast.new(): Spherecast
	return {
		_pattern = DetectionStatic.Enum.Spherecast :: SpherecastPattern,
		position = Vector3.zero :: Vector3,
		radius = 0 :: number,
		direction = Vector3.zero :: Vector3,
		params = nil :: RaycastParams?,	
	} 
end

function Spherecast.from(position: Vector3, radius: number, direction: Vector3, params: RaycastParams?): Spherecast
	return {
		_pattern = DetectionStatic.Enum.Spherecast :: SpherecastPattern,
		position = position,
		radius = radius,
		direction = direction,
		params = params,
	}
end

DetectionStatic.Spherecast = Spherecast
DetectionStatic.Blockcast = Blockcast
DetectionStatic.PartsInBox = PartsInBox
DetectionStatic.PartsInPart = PartsInPart
DetectionStatic.PartsInRadius = PartsInRadius

export type Spherecast = typeof(Spherecast.new())
export type Blockcast = typeof(Blockcast.new())
export type PartsInBox = typeof(PartsInBox.new())
export type PartsInPart = typeof(PartsInPart.new())
export type PartsInRadius = typeof(PartsInRadius.new())

export type Detection = Spherecast | Blockcast | PartsInBox | PartsInPart | PartsInRadius

export type DetectionStatic = typeof(DetectionStatic)
return DetectionStatic :: DetectionStatic