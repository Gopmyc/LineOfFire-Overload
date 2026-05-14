---@class WeaponHolder : Behaviour
local WeaponHolder	=
{
	oDefaultWeaponActor			= Actor(),
	sDefaultWeaponActorName		= "Sopmod_Block3",
	sWeaponSocketActorName		= "WeaponSocket",
	sWeaponSocketParentActorName	= "Player Model",
	bOverrideSocketLocalPose	= true,
	nSocketLocalPositionX		= 0,
	nSocketLocalPositionY		= 4.3,
	nSocketLocalPositionZ		= 1.2,
	nSocketLocalRotationX		= 0.0,
	nSocketLocalRotationY		= 0.0,
	nSocketLocalRotationZ		= 0.0,
	bFollowUpperBodyYawYOnly	= true,
	bUseTorsoAimDirectSocketRotation	= true,
	bEnableUpperBodySocketSync	= false,
	nUpperBodySocketYawWeight	= 1.0,
	nUpperBodySocketPitchWeight	= 0.0,
	nUpperBodySocketSmoothSpeed	= 14.0,
	nUpperBodySocketMaxYawAngle	= 0.0,
	nUpperBodySocketMaxPitchAngle	= 0.0,
	bEquipOnStart				= true,
	bEnableWeaponLogs			= true,

	_private	=
	{
		oPlayerActor				= nil,
		oSocketActor				= nil,
		oSocketTransform			= nil,
		oEquippedWeaponActor		= nil,
		oEquippedWeapon				= nil,
		oHeadLook					= nil,
		qSocketBaseLocalRotation	= nil,
		nSocketUpperBodyPitchAngle	= 0.0,
		nSocketUpperBodyYawAngle	= 0.0,
		bDidLogMissingSocket		= false,
	}
}

function WeaponHolder:OnAwake()
	self									= setmetatable(self, self.owner:GetBehaviour("Class"))
	self._private.oPlayerActor				= self.owner:GetParent() or self.owner
	self._private.oSocketActor				= self:ResolveActor(self.sWeaponSocketActorName)
	self._private.oSocketTransform			= self._private.oSocketActor and self._private.oSocketActor:GetTransform() or nil
	self._private.oHeadLook					= self.owner:GetBehaviour("PlayerHeadLook") or self:FindBehaviourInParents(self.owner, "PlayerHeadLook")

	self:EnsureSocketParent()
	self:ApplySocketLocalPose()
	self:CacheSocketBaseLocalRotation()
	self:ValidateRequiredActors()
end

function WeaponHolder:OnStart()
	if self.bEquipOnStart then
		self:TryEquipDefaultWeapon()
	end
end

function WeaponHolder:OnLateUpdate(nDeltaTime)
	self:UpdateSocketUpperBodySync(nDeltaTime)
	self:UpdateEquippedWeaponPose(nDeltaTime)
end

function WeaponHolder:ResolveActor(sActorName)
	if not sActorName or sActorName == "" then
		return nil
	end

	local oPlayerActor	= self._private.oPlayerActor
	local oActor		= oPlayerActor and self:FindActorByNameRecursive(oPlayerActor, sActorName) or nil

	if oActor then
		return oActor
	end

	local oScene	= Scenes.GetCurrentScene()

	return oScene and oScene:FindActorByName(sActorName) or nil
end

function WeaponHolder:ValidateRequiredActors()
	if not self._private.oSocketTransform and not self._private.bDidLogMissingSocket then
		Debug.LogError("WeaponHolder: missing weapon socket '" .. self.sWeaponSocketActorName .. "'")
		self._private.bDidLogMissingSocket	= true
	end
end

function WeaponHolder:ApplySocketLocalPose()
	if not self.bOverrideSocketLocalPose then
		return false
	end

	local oSocketTransform	= self._private.oSocketTransform

	if not oSocketTransform then
		return false
	end

	local vSocketLocalPosition	= Vector3.new(self.nSocketLocalPositionX, self.nSocketLocalPositionY, self.nSocketLocalPositionZ)
	local qSocketLocalRotation	= Quaternion.new(Vector3.new(self.nSocketLocalRotationX, self.nSocketLocalRotationY, self.nSocketLocalRotationZ))

	oSocketTransform:SetLocalPosition(vSocketLocalPosition)
	oSocketTransform:SetLocalRotation(qSocketLocalRotation)

	return true
end

function WeaponHolder:CacheSocketBaseLocalRotation()
	local oSocketTransform	= self._private.oSocketTransform

	if not oSocketTransform then
		self._private.qSocketBaseLocalRotation	= nil
		return nil
	end

	local qSocketBaseLocalRotation	= oSocketTransform:GetLocalRotation()

	self._private.qSocketBaseLocalRotation	= qSocketBaseLocalRotation

	return qSocketBaseLocalRotation
end

function WeaponHolder:UpdateSocketUpperBodySync(nDeltaTime)
	local oSocketTransform	= self._private.oSocketTransform

	if not oSocketTransform then
		return false
	end

	if not self.bEnableUpperBodySocketSync then
		local qSocketBaseLocalRotation	= self._private.qSocketBaseLocalRotation or self:CacheSocketBaseLocalRotation()

		self._private.nSocketUpperBodyPitchAngle	= 0.0
		self._private.nSocketUpperBodyYawAngle		= 0.0

		if qSocketBaseLocalRotation then
			oSocketTransform:SetLocalRotation(qSocketBaseLocalRotation)
		end

		return true
	end

	local oHeadLook	= self._private.oHeadLook

	if not oHeadLook then
		oHeadLook					= self.owner:GetBehaviour("PlayerHeadLook") or self:FindBehaviourInParents(self.owner, "PlayerHeadLook")
		self._private.oHeadLook		= oHeadLook
	end

	local nSocketTargetPitchAngle	= 0.0
	local nSocketTargetYawAngle		= 0.0
	local bCanSyncSocketWithHeadLook	= self.bEnableUpperBodySocketSync and oHeadLook and oHeadLook.GetUpperBodyAimOffsetAngles

	if bCanSyncSocketWithHeadLook then
		local nUpperBodyPitchAngle, nUpperBodyYawAngle	= oHeadLook:GetUpperBodyAimOffsetAngles()
		local bFollowUpperBodyYawYOnly	= self.bFollowUpperBodyYawYOnly
		local nProfileSocketPitchWeight	= self:ResolveSocketUpperBodyPitchProfileWeight()
		local nProfileSocketYawWeight	= self:ResolveSocketUpperBodyYawProfileWeight()
		local nSocketPitchWeight	= (self.nUpperBodySocketPitchWeight or 0.0) * nProfileSocketPitchWeight
		local nSocketYawWeight		= (self.nUpperBodySocketYawWeight or 0.0) * nProfileSocketYawWeight
		local nWeightedPitchAngle	= bFollowUpperBodyYawYOnly and 0.0 or (nUpperBodyPitchAngle * nSocketPitchWeight)
		local nWeightedYawAngle		= nUpperBodyYawAngle * nSocketYawWeight
		local nMaxPitchAngle		= self.nUpperBodySocketMaxPitchAngle or 0.0
		local nMaxYawAngle			= self.nUpperBodySocketMaxYawAngle or 0.0

		nSocketTargetPitchAngle	= nMaxPitchAngle > 0.0 and self:Clamp(nWeightedPitchAngle, -nMaxPitchAngle, nMaxPitchAngle) or nWeightedPitchAngle
		nSocketTargetYawAngle	= nMaxYawAngle > 0.0 and self:Clamp(nWeightedYawAngle, -nMaxYawAngle, nMaxYawAngle) or nWeightedYawAngle
	end

	local bUseDirectSocketRotation	= self.bUseTorsoAimDirectSocketRotation
	local nSocketBlendAlpha			= bUseDirectSocketRotation and 1.0 or self:Clamp(nDeltaTime * (self.nUpperBodySocketSmoothSpeed or 0.0), 0.0, 1.0)
	local nCurrentSocketPitchAngle	= self._private.nSocketUpperBodyPitchAngle or 0.0
	local nCurrentSocketYawAngle	= self._private.nSocketUpperBodyYawAngle or 0.0
	local nUpdatedSocketPitchAngle	= self:LerpAngle(nCurrentSocketPitchAngle, nSocketTargetPitchAngle, nSocketBlendAlpha)
	local nUpdatedSocketYawAngle	= self:LerpAngle(nCurrentSocketYawAngle, nSocketTargetYawAngle, nSocketBlendAlpha)
	local qSocketBaseLocalRotation	= self._private.qSocketBaseLocalRotation or self:CacheSocketBaseLocalRotation()

	self._private.nSocketUpperBodyPitchAngle	= nUpdatedSocketPitchAngle
	self._private.nSocketUpperBodyYawAngle		= nUpdatedSocketYawAngle

	if not qSocketBaseLocalRotation then
		return false
	end

	local qUpperBodySocketOffsetRotation	= Quaternion.new(Vector3.new(nUpdatedSocketPitchAngle, nUpdatedSocketYawAngle, 0.0))
	local qSocketTargetLocalRotation		= qSocketBaseLocalRotation * qUpperBodySocketOffsetRotation

	oSocketTransform:SetLocalRotation(qSocketTargetLocalRotation)

	return true
end

function WeaponHolder:EnsureSocketParent()
	local oSocketActor		= self._private.oSocketActor
	local sSocketParentActorName	= self.sWeaponSocketParentActorName

	if not oSocketActor or not sSocketParentActorName or sSocketParentActorName == "" then
		return false
	end

	local oExpectedParentActor	= self:ResolveActor(sSocketParentActorName)
	local oCurrentParentActor	= oSocketActor:GetParent()

	if not oExpectedParentActor then
		Debug.LogWarning("WeaponHolder: missing socket parent '" .. sSocketParentActorName .. "'")
		return false
	end

	if oCurrentParentActor == oExpectedParentActor then
		return true
	end

	oSocketActor:SetParent(oExpectedParentActor)
	self._private.oSocketTransform	= oSocketActor:GetTransform()

	return true
end

function WeaponHolder:TryEquipDefaultWeapon()
	if self._private.oEquippedWeapon then
		return true
	end

	local oWeaponActor	= self:ResolveDefaultWeaponActor()

	if not oWeaponActor then
		Debug.LogWarning("WeaponHolder: no weapon actor found to equip")
		return false
	end

	return self:EquipWeaponActor(oWeaponActor)
end

function WeaponHolder:ResolveDefaultWeaponActor()
	local oDefaultWeaponActor	= self.oDefaultWeaponActor

	if oDefaultWeaponActor then
		return oDefaultWeaponActor
	end

	return self:ResolveActor(self.sDefaultWeaponActorName)
end

function WeaponHolder:EquipWeaponActor(oWeaponActor)
	local oSocketActor	= self._private.oSocketActor

	if not oSocketActor then
		Debug.LogError("WeaponHolder: cannot equip weapon without socket actor")
		return false
	end

	local oWeapon	= oWeaponActor and oWeaponActor:GetBehaviour("Weapon") or nil

	if not oWeapon or not oWeapon.EquipToSocket then
		Debug.LogError("WeaponHolder: actor '" .. (oWeaponActor and oWeaponActor:GetName() or "<nil>") .. "' has no compatible Weapon behaviour")
		return false
	end

	local bDidEquip	= oWeapon:EquipToSocket(oSocketActor)

	if not bDidEquip then
		return false
	end

	self._private.oEquippedWeaponActor	= oWeaponActor
	self._private.oEquippedWeapon		= oWeapon

	if self.bEnableWeaponLogs then
		Debug.Log("WeaponHolder: equipped '" .. oWeaponActor:GetName() .. "'")
	end

	return true
end

function WeaponHolder:UnequipCurrentWeapon()
	local oWeapon	= self._private.oEquippedWeapon

	if oWeapon and oWeapon.Unequip then
		oWeapon:Unequip()
	end

	self._private.oEquippedWeaponActor	= nil
	self._private.oEquippedWeapon		= nil
end

function WeaponHolder:UpdateEquippedWeaponPose(nDeltaTime)
	local oWeapon	= self._private.oEquippedWeapon

	if oWeapon and oWeapon.ApplyEquipOffset then
		oWeapon:ApplyEquipOffset()
	end
end

function WeaponHolder:GetEquippedWeaponActor()
	return self._private.oEquippedWeaponActor
end

function WeaponHolder:GetEquippedWeapon()
	return self._private.oEquippedWeapon
end

function WeaponHolder:ResolveSocketUpperBodyYawProfileWeight()
	local oWeapon		= self._private.oEquippedWeapon
	local oGripProfile	= oWeapon and oWeapon.GetGripProfile and oWeapon:GetGripProfile() or nil
	local nWeight		= oGripProfile and oGripProfile.GetSocketUpperBodyYawWeight and oGripProfile:GetSocketUpperBodyYawWeight() or 1.0

	return nWeight or 1.0
end

function WeaponHolder:ResolveSocketUpperBodyPitchProfileWeight()
	local oWeapon		= self._private.oEquippedWeapon
	local oGripProfile	= oWeapon and oWeapon.GetGripProfile and oWeapon:GetGripProfile() or nil
	local nWeight		= oGripProfile and oGripProfile.GetSocketUpperBodyPitchWeight and oGripProfile:GetSocketUpperBodyPitchWeight() or 1.0

	return nWeight or 1.0
end

function WeaponHolder:GetWeaponSocketActor()
	return self._private.oSocketActor
end

return WeaponHolder
