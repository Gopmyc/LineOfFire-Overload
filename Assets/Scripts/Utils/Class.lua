---@class Class : Behaviour
local Class	= {}

function Class:Clamp(nValue, nMin, nMax)
	local nClampedMin	= nValue < nMin and nMin or nValue

	return nClampedMin > nMax and nMax or nClampedMin
end

function Class:FindActorByNameRecursive(oCurrentActor, sActorName)
	if not oCurrentActor then return nil end

	if oCurrentActor:GetName() == sActorName then
		return oCurrentActor
	end

	return oCurrentActor:FindChild(sActorName, true)
end

function Class:FindSkinnedMeshRendererRecursive(oCurrentActor)
	if not oCurrentActor then return nil end

	local oSkinnedMeshRenderer	= oCurrentActor:GetSkinnedMeshRenderer()
	if oSkinnedMeshRenderer then
		return oSkinnedMeshRenderer
	end

	local tChildren	= oCurrentActor:GetChildren()

	for _, oChildActor in ipairs(tChildren) do
		local oFoundSkinnedMeshRenderer	= self:FindSkinnedMeshRendererRecursive(oChildActor)

		if oFoundSkinnedMeshRenderer then
			return oFoundSkinnedMeshRenderer
		end
	end

	return nil
end

function Class:NormalizeAngle180(nAngle)
	local nNormalizedAngle	= nAngle

	while nNormalizedAngle > 180 do
		nNormalizedAngle	= nNormalizedAngle - 360
	end

	while nNormalizedAngle < -180 do
		nNormalizedAngle	= nNormalizedAngle + 360
	end

	return nNormalizedAngle
end

function Class:LerpAngle(nFromAngle, nToAngle, nAlpha)
	local nDeltaAngle	= self:NormalizeAngle180(nToAngle - nFromAngle)

	return nFromAngle + (nDeltaAngle * nAlpha)
end

function Class:FindBehaviourInParents(oCurrentActor, sBehaviourName)
	while oCurrentActor do
		local oBehaviour	= oCurrentActor:GetBehaviour(sBehaviourName)

		if oBehaviour then
			return oBehaviour
		end

		oCurrentActor	= oCurrentActor:GetParent()
	end

	return nil
end

function Class.ResolveClassBehaviour(oActor)
	local oCurrentActor	= oActor

	while oCurrentActor do
		local oClass	= oCurrentActor:GetBehaviour("Class")

		if oClass then
			return oClass
		end

		oCurrentActor	= oCurrentActor:GetParent()
	end

	return Class
end

Class.__index	= function(self, sKey)
	local mValue	= rawget(self, sKey)
	if mValue ~= nil then return mValue end

	local tPrivate	= rawget(self, "_private")
	if tPrivate then
		local mPrivateValue	= rawget(tPrivate, sKey)
		if mPrivateValue ~= nil then return mPrivateValue end
	end

	return rawget(Class, sKey)
end

return Class
