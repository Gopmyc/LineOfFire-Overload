---@class Weapon : Behaviour
local Weapon	=
{
	sHandRightActorName		= "Hand_R",
	sHandLeftActorName		= "Hand_L",
	bAlignForwardToHands	= true,
	bAnchorRightHandToSocket	= true,
	nDynamicYawOffsetLimit		= 35.0,
	nEquipOffsetX			= 0.0,
	nEquipOffsetY			= 0.0,
	nEquipOffsetZ			= 0.0,
	nEquipRotationX			= 0.0,
	nEquipRotationY			= 0.0,
	nEquipRotationZ			= 0.0,
	bDisableWhenUnequipped	= false,

	_private	=
	{
		oRootTransform		= nil,
		oSocketActor		= nil,
		oSocketTransform	= nil,
		oHandRightActor		= nil,
		oHandLeftActor		= nil,
		oHandRightTransform	= nil,
		oHandLeftTransform	= nil,
		oGripProfile		= nil,
		bIsEquipped			= false,
		bDidLogMissingHandR	= false,
		bDidLogMissingHandL	= false,
		bDidLogMissingGripProfile	= false,
		nDynamicYawOffsetY	= 0.0,
		nAimAlpha			= 0.0,
	}
}

function Weapon:OnAwake()
	self						= setmetatable(self, self:ResolveClassBehaviour())
	self._private.oRootTransform	= self.owner:GetTransform()
	self._private.oGripProfile		= self.owner:GetBehaviour("WeaponGripProfile")

	self:RefreshGripActors()

	if self.bDisableWhenUnequipped then
		self.owner:SetActive(false)
	end
end

function Weapon:ResolveClassBehaviour()
	local oCurrentActor	= self.owner

	while oCurrentActor do
		local oClass	= oCurrentActor:GetBehaviour("Class")

		if oClass then
			return oClass.ResolveClassBehaviour and oClass.ResolveClassBehaviour(self.owner) or oClass
		end

		oCurrentActor	= oCurrentActor:GetParent()
	end

	return {}
end

function Weapon:RefreshGripActors()
	local sHandRightActorName	= self.sHandRightActorName
	local sHandLeftActorName	= self.sHandLeftActorName
	local oHandRightActor		= self.owner:FindChild(sHandRightActorName, true)
	local oHandLeftActor		= self.owner:FindChild(sHandLeftActorName, true)

	self._private.oHandRightActor		= oHandRightActor
	self._private.oHandLeftActor		= oHandLeftActor
	self._private.oHandRightTransform	= oHandRightActor and oHandRightActor:GetTransform() or nil
	self._private.oHandLeftTransform	= oHandLeftActor and oHandLeftActor:GetTransform() or nil

	if not self._private.oHandRightTransform and not self._private.bDidLogMissingHandR then
		Debug.LogError("Weapon: missing grip point '" .. sHandRightActorName .. "' on '" .. self.owner:GetName() .. "'")
		self._private.bDidLogMissingHandR	= true
	end

	if not self._private.oHandLeftTransform and not self._private.bDidLogMissingHandL then
		Debug.LogError("Weapon: missing grip point '" .. sHandLeftActorName .. "' on '" .. self.owner:GetName() .. "'")
		self._private.bDidLogMissingHandL	= true
	end
end

function Weapon:EquipToSocket(oSocketActor)
	local oRootTransform	= self._private.oRootTransform or self.owner:GetTransform()
	local oSocketTransform	= oSocketActor and oSocketActor:GetTransform() or nil

	self._private.oRootTransform	= oRootTransform

	if not oSocketActor or not oSocketTransform then
		Debug.LogError("Weapon: invalid socket actor for '" .. self.owner:GetName() .. "'")
		return false
	end

	if not oRootTransform then
		Debug.LogError("Weapon: missing root transform on '" .. self.owner:GetName() .. "'")
		return false
	end

	self.owner:SetParent(oSocketActor)
	self._private.oSocketActor		= oSocketActor
	self._private.oSocketTransform	= oSocketTransform
	self._private.bIsEquipped		= true

	self:ApplyEquipOffset()
	self:RefreshGripActors()

	if self.bDisableWhenUnequipped then
		self.owner:SetActive(true)
	end

	return true
end

function Weapon:Unequip()
	if not self._private.bIsEquipped then return end

	self.owner:DetachFromParent()

	self._private.oSocketActor		= nil
	self._private.oSocketTransform	= nil
	self._private.bIsEquipped		= false

	if self.bDisableWhenUnequipped then
		self.owner:SetActive(false)
	end
end

function Weapon:ApplyEquipOffset()
	local oRootTransform	= self._private.oRootTransform

	if not oRootTransform then return end

	local oGripProfile		= self:GetGripProfile()
	local nAutoYaw			= self:ResolveAutoGripYawAngle()
	local nDynamicYawOffsetY	= self._private.nDynamicYawOffsetY or 0.0
	local nEquipYaw			= self.nEquipRotationY + nAutoYaw + nDynamicYawOffsetY
	local qEquipBaseRotation	= Quaternion.new(Vector3.new(self.nEquipRotationX, nEquipYaw, self.nEquipRotationZ))
	local qMountRotation		= oGripProfile and oGripProfile.GetMountRotation and oGripProfile:GetMountRotation() or Quaternion.new(Vector3.new(0, 0, 0))
	local qEquipRotation		= qEquipBaseRotation * qMountRotation
	local vMountOffset		= oGripProfile and oGripProfile.GetMountOffset and oGripProfile:GetMountOffset() or Vector3.new(0, 0, 0)
	local vEquipOffset		= Vector3.new(self.nEquipOffsetX, self.nEquipOffsetY, self.nEquipOffsetZ) + vMountOffset

	if self.bAnchorRightHandToSocket then
		local oHandRightTransform	= self._private.oHandRightTransform
		local vHandRightLocalPosition	= oHandRightTransform and oHandRightTransform:GetLocalPosition() or nil

		if vHandRightLocalPosition then
			vEquipOffset	= vEquipOffset - (qEquipRotation * vHandRightLocalPosition)
		end
	end

	local vFinalEquipOffset		= vEquipOffset
	local qFinalEquipRotation	= qEquipRotation
	local nAimAlphaRaw			= self._private.nAimAlpha or 0.0
	local nAimBlendWeight		= oGripProfile and oGripProfile.GetAimBlendWeight and oGripProfile:GetAimBlendWeight() or 1.0
	local nAimAlpha			= self:Clamp(nAimAlphaRaw * nAimBlendWeight, 0.0, 1.0)

	if nAimAlpha > 0.0001 then
		local vAimOffsetLocal		= oGripProfile and oGripProfile.GetAimOffset and oGripProfile:GetAimOffset() or Vector3.new(0, 0, 0)
		local qAimOffsetRotation	= oGripProfile and oGripProfile.GetAimRotation and oGripProfile:GetAimRotation() or Quaternion.new(Vector3.new(0, 0, 0))
		local nAimOffsetWeight		= oGripProfile and oGripProfile.GetAimOffsetWeight and oGripProfile:GetAimOffsetWeight() or 1.0
		local nAimRotationWeight	= oGripProfile and oGripProfile.GetAimRotationWeight and oGripProfile:GetAimRotationWeight() or 1.0
		local qIdentityRotation		= Quaternion.new(Vector3.new(0, 0, 0))
		local qWeightedAimRotation	= self:BlendQuaternion(qIdentityRotation, qAimOffsetRotation, self:Clamp(nAimRotationWeight, 0.0, 1.0))
		local qAimEquipRotation		= qEquipRotation * qWeightedAimRotation
		local vAimEquipOffset		= vEquipOffset + (qEquipRotation * (vAimOffsetLocal * nAimOffsetWeight))

		vFinalEquipOffset		= self:LerpVector3(vEquipOffset, vAimEquipOffset, nAimAlpha)
		qFinalEquipRotation		= self:BlendQuaternion(qEquipRotation, qAimEquipRotation, nAimAlpha)
	end

	oRootTransform:SetLocalPosition(vFinalEquipOffset)
	oRootTransform:SetLocalRotation(qFinalEquipRotation)
end

function Weapon:SetDynamicYawOffsetY(nYawOffset)
	local nOffset	= nYawOffset or 0.0
	local nLimit	= math.abs(self.nDynamicYawOffsetLimit or 0.0)

	if nLimit > 0.0 then
		nOffset	= nOffset < -nLimit and -nLimit or (nOffset > nLimit and nLimit or nOffset)
	end

	self._private.nDynamicYawOffsetY	= nOffset
end

function Weapon:GetDynamicYawOffsetY()
	return self._private.nDynamicYawOffsetY or 0.0
end

function Weapon:ResetDynamicYawOffsetY()
	self._private.nDynamicYawOffsetY	= 0.0
end

function Weapon:SetAimAlpha(nAimAlpha)
	self._private.nAimAlpha	= self:Clamp(nAimAlpha or 0.0, 0.0, 1.0)
end

function Weapon:GetAimAlpha()
	return self._private.nAimAlpha or 0.0
end

function Weapon:ResetAimAlpha()
	self._private.nAimAlpha	= 0.0
end

function Weapon:ResolveAutoGripYawAngle()
	if not self.bAlignForwardToHands then
		return 0.0
	end

	local oHandRightTransform	= self._private.oHandRightTransform
	local oHandLeftTransform	= self._private.oHandLeftTransform
	local vHandRightLocalPosition	= oHandRightTransform and oHandRightTransform:GetLocalPosition() or nil
	local vHandLeftLocalPosition	= oHandLeftTransform and oHandLeftTransform:GetLocalPosition() or nil

	if not vHandRightLocalPosition or not vHandLeftLocalPosition then
		return 0.0
	end

	local vGripAxis		= vHandLeftLocalPosition - vHandRightLocalPosition
	local nGripAxisXZSq	= (vGripAxis.x * vGripAxis.x) + (vGripAxis.z * vGripAxis.z)

	if nGripAxisXZSq <= 0.000001 then
		return 0.0
	end

	local fAtan2	= math.atan2
	local nYawAngle	= 0.0

	if fAtan2 then
		nYawAngle	= fAtan2(vGripAxis.x, vGripAxis.z)
	elseif vGripAxis.z == 0 then
		nYawAngle	= vGripAxis.x >= 0 and 1.57079632679 or -1.57079632679
	else
		nYawAngle	= math.atan(vGripAxis.x / vGripAxis.z)
		nYawAngle	= vGripAxis.z < 0 and (nYawAngle + (vGripAxis.x >= 0 and 3.14159265359 or -3.14159265359)) or nYawAngle
	end

	return -math.deg(nYawAngle)
end

function Weapon:IsEquipped()
	return self._private.bIsEquipped
end

function Weapon:GetRootTransform()
	return self._private.oRootTransform
end

function Weapon:GetHandRightActor()
	return self._private.oHandRightActor
end

function Weapon:GetHandLeftActor()
	return self._private.oHandLeftActor
end

function Weapon:GetHandRightTransform()
	return self._private.oHandRightTransform
end

function Weapon:GetHandLeftTransform()
	return self._private.oHandLeftTransform
end

function Weapon:GetSocketActor()
	return self._private.oSocketActor
end

function Weapon:GetGripProfile()
	local oGripProfile	= self._private.oGripProfile

	if oGripProfile then
		return oGripProfile
	end

	oGripProfile	= self.owner:GetBehaviour("WeaponGripProfile")
	self._private.oGripProfile	= oGripProfile

	if not oGripProfile and not self._private.bDidLogMissingGripProfile then
		Debug.LogWarning("Weapon: missing WeaponGripProfile on '" .. self.owner:GetName() .. "'")
		self._private.bDidLogMissingGripProfile	= true
	end

	return oGripProfile
end

function Weapon:HasValidGripPoints()
	return self._private.oHandRightTransform ~= nil and self._private.oHandLeftTransform ~= nil
end

function Weapon:LerpVector3(vFrom, vTo, nAlpha)
	local nClampedAlpha	= self:Clamp(nAlpha or 0.0, 0.0, 1.0)

	return vFrom + ((vTo - vFrom) * nClampedAlpha)
end

function Weapon:NormalizeQuaternion(qValue)
	if not qValue then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	local nLengthSq	= (qValue.x * qValue.x) + (qValue.y * qValue.y) + (qValue.z * qValue.z) + (qValue.w * qValue.w)

	if nLengthSq <= 0.0001 then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	local nInvLength	= 1.0 / math.sqrt(nLengthSq)

	return Quaternion.new(qValue.x * nInvLength, qValue.y * nInvLength, qValue.z * nInvLength, qValue.w * nInvLength)
end

function Weapon:BlendQuaternion(qFrom, qTo, nAlpha)
	local nClampedAlpha	= self:Clamp(nAlpha or 0.0, 0.0, 1.0)
	local qSafeFrom		= self:NormalizeQuaternion(qFrom)
	local qSafeTo		= self:NormalizeQuaternion(qTo)
	local nDot			= (qSafeFrom.x * qSafeTo.x) + (qSafeFrom.y * qSafeTo.y) + (qSafeFrom.z * qSafeTo.z) + (qSafeFrom.w * qSafeTo.w)
	local qAdjustedTo	= nDot < 0.0 and Quaternion.new(-qSafeTo.x, -qSafeTo.y, -qSafeTo.z, -qSafeTo.w) or qSafeTo
	local nFromWeight	= 1.0 - nClampedAlpha
	local nToWeight		= nClampedAlpha
	local qBlended		= Quaternion.new(
		(qSafeFrom.x * nFromWeight) + (qAdjustedTo.x * nToWeight),
		(qSafeFrom.y * nFromWeight) + (qAdjustedTo.y * nToWeight),
		(qSafeFrom.z * nFromWeight) + (qAdjustedTo.z * nToWeight),
		(qSafeFrom.w * nFromWeight) + (qAdjustedTo.w * nToWeight)
	)

	return self:NormalizeQuaternion(qBlended)
end

return Weapon
