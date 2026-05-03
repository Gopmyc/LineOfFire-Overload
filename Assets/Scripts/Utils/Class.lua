---@class Class : Behaviour
local Class	= {
	__index	= function(self, sKey)
		local mValue	= rawget(self, sKey)
		if mValue ~= nil then return mValue end

		local tPrivate	= rawget(self, "_private")
		if tPrivate then
			local mPrivateValue	= rawget(tPrivate, sKey)
			if mPrivateValue ~= nil then return mPrivateValue end
		end

		return rawget(Class, sKey)
	end,
}

function Class:Clamp(nValue, nMin, nMax)
	local nClampedMin	= nValue < nMin and nMin or nValue

	return nClampedMin > nMax and nMax or nClampedMin
end

function Class:FindActorByNameRecursive(oCurrentActor, sActorName)
	if not oCurrentActor then return nil end

	if oCurrentActor:GetName() == sActorName then
		return oCurrentActor
	end

	local tChildren	= oCurrentActor:GetChildren()

	for _, oChildActor in ipairs(tChildren) do
		local oFoundActor	= self:FindActorByNameRecursive(oChildActor, sActorName)

		if oFoundActor then
			return oFoundActor
		end
	end

	return nil
end

return Class
