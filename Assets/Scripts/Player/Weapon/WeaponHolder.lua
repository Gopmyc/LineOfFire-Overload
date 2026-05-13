---@class WeaponHolder : Behaviour
local WeaponHolder	=
{
	oDefaultWeaponActor			= Actor(),
	sDefaultWeaponActorName		= "Sopmod_Block3",
	sWeaponSocketActorName		= "WeaponSocket",
	sWeaponSocketParentActorName	= "Player Model",
	bOverrideSocketLocalPose	= true,
	nSocketLocalPositionX		= -0.42,
	nSocketLocalPositionY		= 4.3,
	nSocketLocalPositionZ		= 1.2,
	nSocketLocalRotationX		= 0.0,
	nSocketLocalRotationY		= 0.0,
	nSocketLocalRotationZ		= 0.0,
	bEquipOnStart				= true,
	bEnableWeaponLogs			= true,

	_private	=
	{
		oPlayerActor				= nil,
		oSocketActor				= nil,
		oSocketTransform			= nil,
		oEquippedWeaponActor		= nil,
		oEquippedWeapon				= nil,
		bDidLogMissingSocket		= false,
	}
}

function WeaponHolder:OnAwake()
	self									= setmetatable(self, self.owner:GetBehaviour("Class"))
	self._private.oPlayerActor				= self.owner:GetParent() or self.owner
	self._private.oSocketActor				= self:ResolveActor(self.sWeaponSocketActorName)
	self._private.oSocketTransform			= self._private.oSocketActor and self._private.oSocketActor:GetTransform() or nil

	self:EnsureSocketParent()
	self:ApplySocketLocalPose()
	self:ValidateRequiredActors()
end

function WeaponHolder:OnStart()
	if self.bEquipOnStart then
		self:TryEquipDefaultWeapon()
	end
end

function WeaponHolder:OnLateUpdate(nDeltaTime)
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

function WeaponHolder:GetWeaponSocketActor()
	return self._private.oSocketActor
end

return WeaponHolder
