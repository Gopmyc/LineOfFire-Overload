---@class PhysicsRootStabilizer : Behaviour
local PhysicsRootStabilizer	=
{
	nPositionEpsilon			= 0.0001,
	nRotationEpsilon			= 0.0001,
	nScaleEpsilon				= 0.0001,
	bEnableStabilizerLogs		= true,

	_private	=
	{
		sPhysicsActorName		= "Player Physics",
		oRootTransform			= nil,
		oPhysicsActor			= nil,
		oPhysicsTransform		= nil,
		bDidLogMissingPhysics	= false,
	}
}

function PhysicsRootStabilizer:OnAwake()
	self							= setmetatable(self, self.owner:GetBehaviour("Class"))
	self._private.oRootTransform	= self.owner:GetTransform()
	self._private.oPhysicsActor		= self:FindActorByNameRecursive(self.owner, self._private.sPhysicsActorName)
	self._private.oPhysicsTransform	= self._private.oPhysicsActor and self._private.oPhysicsActor:GetTransform() or nil

	self:StabilizeHierarchy()
end

function PhysicsRootStabilizer:StabilizeHierarchy()
	local oRootTransform	= self._private.oRootTransform
	local oPhysicsTransform	= self._private.oPhysicsTransform

	if not oRootTransform or not oPhysicsTransform then
		if not self._private.bDidLogMissingPhysics then
			Debug.LogError("PhysicsRootStabilizer: missing physics actor '" .. self._private.sPhysicsActorName .. "'")
			self._private.bDidLogMissingPhysics	= true
		end

		return false
	end

	local vPhysicsWorldPosition	= oPhysicsTransform:GetWorldPosition()
	local qPhysicsWorldRotation	= oPhysicsTransform:GetWorldRotation()
	local vPhysicsWorldScale	= oPhysicsTransform:GetWorldScale()
	local oRootParentActor		= self.owner:GetParent()
	local bDidDetachRootParent	= false

	if oRootParentActor then
		local vRootWorldPosition	= oRootTransform:GetWorldPosition()
		local qRootWorldRotation	= oRootTransform:GetWorldRotation()
		local vRootWorldScale		= oRootTransform:GetWorldScale()

		self.owner:DetachFromParent()

		oRootTransform:SetWorldPosition(vRootWorldPosition)
		oRootTransform:SetWorldRotation(qRootWorldRotation)
		oRootTransform:SetWorldScale(vRootWorldScale)

		bDidDetachRootParent	= true
	end

	local bIsRootLocalNeutral	= self:IsRootLocalTransformNeutral(oRootTransform)
	local bMustStabilizeRoot	= bDidDetachRootParent or not bIsRootLocalNeutral

	if not bMustStabilizeRoot then
		return false
	end

	oRootTransform:SetLocalPosition(Vector3.new(0, 0, 0))
	oRootTransform:SetLocalRotation(Quaternion.new(Vector3.new(0, 0, 0)))
	oRootTransform:SetLocalScale(Vector3.new(1, 1, 1))

	oPhysicsTransform:SetWorldPosition(vPhysicsWorldPosition)
	oPhysicsTransform:SetWorldRotation(qPhysicsWorldRotation)
	oPhysicsTransform:SetWorldScale(vPhysicsWorldScale)

	if self.bEnableStabilizerLogs then
		Debug.LogWarning("PhysicsRootStabilizer: stabilized root transform to protect physics hierarchy")
	end

	return true
end

function PhysicsRootStabilizer:IsRootLocalTransformNeutral(oRootTransform)
	local vRootLocalPosition	= oRootTransform:GetLocalPosition()
	local qRootLocalRotation	= oRootTransform:GetLocalRotation()
	local vRootLocalScale		= oRootTransform:GetLocalScale()
	local bIsPositionNeutral	= self:IsNearlyZeroVector3(vRootLocalPosition, self.nPositionEpsilon)
	local bIsRotationNeutral	= self:IsNearlyIdentityQuaternion(qRootLocalRotation, self.nRotationEpsilon)
	local bIsScaleNeutral		= self:IsNearlyOneVector3(vRootLocalScale, self.nScaleEpsilon)

	return bIsPositionNeutral and bIsRotationNeutral and bIsScaleNeutral
end

function PhysicsRootStabilizer:IsNearlyZeroVector3(vValue, nEpsilon)
	if not vValue then
		return false
	end

	local fAbs	= math.abs

	return fAbs(vValue.x) <= nEpsilon and fAbs(vValue.y) <= nEpsilon and fAbs(vValue.z) <= nEpsilon
end

function PhysicsRootStabilizer:IsNearlyOneVector3(vValue, nEpsilon)
	if not vValue then
		return false
	end

	local fAbs	= math.abs

	return fAbs(vValue.x - 1.0) <= nEpsilon and fAbs(vValue.y - 1.0) <= nEpsilon and fAbs(vValue.z - 1.0) <= nEpsilon
end

function PhysicsRootStabilizer:IsNearlyIdentityQuaternion(qValue, nEpsilon)
	if not qValue then
		return false
	end

	local fAbs				= math.abs
	local nIdentityWDelta	= fAbs(fAbs(qValue.w) - 1.0)

	return fAbs(qValue.x) <= nEpsilon and fAbs(qValue.y) <= nEpsilon and fAbs(qValue.z) <= nEpsilon and nIdentityWDelta <= nEpsilon
end

return PhysicsRootStabilizer
