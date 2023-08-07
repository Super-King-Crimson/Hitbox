--!strict 
export type Caster = Humanoid | WorldRoot
export type Hit = BasePart | Humanoid
export type Filter = (inst: Instance, caster: Caster) -> Hit?

return {
	default = function(inst: Instance, caster: Caster?): Hit?
		if not inst:IsA("BasePart") then return nil end
		
		local hum = (inst.Parent::Instance):FindFirstChildOfClass("Humanoid")
		
		if hum and caster ~= hum then
			return hum :: Humanoid
		elseif inst.Name == "Hurtbox" then
			return inst :: BasePart
		else
			return nil
		end
	end :: Filter,
}