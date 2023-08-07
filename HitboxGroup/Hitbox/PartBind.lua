local PartBindStatic = {}

function PartBindStatic.new(part: BasePart, onDestroy: () -> ()): PartBind
	local _onDestroyConn = part.Destroying:Once(onDestroy)
	
	return {
		part = part,
		_onDestroy = _onDestroyConn,
	}
end

export type PartBind = typeof(PartBindStatic.new(Instance.new("Part"), function() end))

export type PartBindStatic = typeof(PartBindStatic)
return PartBindStatic :: PartBindStatic