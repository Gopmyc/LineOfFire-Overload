---@class PlayerItemMounts : Behaviour
local PlayerItemMounts	=
{
	HELMET_BONE_NAME				= "mixamorig:Head",
	JPC_BONE_NAME					= "mixamorig:Spine2",
	BELT_BONE_NAME					= "mixamorig:Hips",
	HELMET_SLOT_NAME				= "Item Slot HELMET",
	JPC_SLOT_NAME					= "Item Slot JPC",
	BELT_SLOT_NAME					= "Item Slot BELT",
	HELMET_OFFSET_X					= 0.0,
	HELMET_OFFSET_Y					= 0.0,
	HELMET_OFFSET_Z					= 0.0,
	HELMET_OFFSET_PITCH				= 0.0,
	HELMET_OFFSET_YAW				= 0.0,
	HELMET_OFFSET_ROLL				= 0.0,
	JPC_OFFSET_X					= 0.0,
	JPC_OFFSET_Y					= 0.0,
	JPC_OFFSET_Z					= 0.0,
	JPC_OFFSET_PITCH				= 0.0,
	JPC_OFFSET_YAW					= 0.0,
	JPC_OFFSET_ROLL					= 0.0,
	BELT_OFFSET_X					= 0.0,
	BELT_OFFSET_Y					= 0.0,
	BELT_OFFSET_Z					= 0.0,
	BELT_OFFSET_PITCH				= 0.0,
	BELT_OFFSET_YAW					= 0.0,
	BELT_OFFSET_ROLL					= 0.0,

	_private	=
	{
		sModelActorName				= "Player Model",
		oModelActor					= nil,
		oSkinnedMeshRenderer			= nil,
		nHelmetBoneIndex				= nil,
		nJpcBoneIndex					= nil,
		nBeltBoneIndex					= nil,
		oHelmetSlotActor				= nil,
		oJpcSlotActor					= nil,
		oBeltSlotActor					= nil,
		oHelmetSlotTransform			= nil,
		oJpcSlotTransform				= nil,
		oBeltSlotTransform				= nil,
		oEquippedHelmetItem			= nil,
		oEquippedJpcItem				= nil,
		oEquippedBeltItem				= nil,
	}
}

function PlayerItemMounts:OnAwake()
	self								= setmetatable(self, self:ResolveClassBehaviour())

	local oModelActor					= self:ResolveModelActor()
	local oSkinnedMeshRenderer			= self:ResolveSkinnedMeshRenderer(oModelActor)
	local oHelmetSlotActor				= self:FindActorByNameRecursive(oModelActor, self.HELMET_SLOT_NAME)
	local oJpcSlotActor					= self:FindActorByNameRecursive(oModelActor, self.JPC_SLOT_NAME)
	local oBeltSlotActor				= self:FindActorByNameRecursive(oModelActor, self.BELT_SLOT_NAME)

	self._private.oModelActor			= oModelActor
	self._private.oSkinnedMeshRenderer	= oSkinnedMeshRenderer
	self._private.nHelmetBoneIndex		= self:ResolveBoneIndex(oSkinnedMeshRenderer, self.HELMET_BONE_NAME)
	self._private.nJpcBoneIndex			= self:ResolveBoneIndex(oSkinnedMeshRenderer, self.JPC_BONE_NAME)
	self._private.nBeltBoneIndex			= self:ResolveBoneIndex(oSkinnedMeshRenderer, self.BELT_BONE_NAME)
	self._private.oHelmetSlotActor		= oHelmetSlotActor
	self._private.oJpcSlotActor			= oJpcSlotActor
	self._private.oBeltSlotActor			= oBeltSlotActor
	self._private.oHelmetSlotTransform	= oHelmetSlotActor and oHelmetSlotActor:GetTransform() or nil
	self._private.oJpcSlotTransform		= oJpcSlotActor and oJpcSlotActor:GetTransform() or nil
	self._private.oBeltSlotTransform		= oBeltSlotActor and oBeltSlotActor:GetTransform() or nil
	self._private.oEquippedHelmetItem	= nil
	self._private.oEquippedJpcItem		= nil
	self._private.oEquippedBeltItem		= nil
end

function PlayerItemMounts:OnLateUpdate(nDeltaTime)
	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer

	if not oSkinnedMeshRenderer then return end

	self:UpdateSlotFromItemType("HELMET")
	self:UpdateSlotFromItemType("JPC")
	self:UpdateSlotFromItemType("BELT")
end

function PlayerItemMounts:UpdateSlotFromItemType(sItemType)
	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer
	local oSlotTransform		= self:GetSlotTransformByItemType(sItemType)
	local nBoneIndex			= self:GetBoneIndexByItemType(sItemType)

	if not oSkinnedMeshRenderer or not oSlotTransform or not nBoneIndex then return end

	local vBoneLocalPosition	= oSkinnedMeshRenderer:GetBoneLocalPosition(nBoneIndex)
	local qBoneLocalRotation	= oSkinnedMeshRenderer:GetBoneLocalRotation(nBoneIndex)

	if not vBoneLocalPosition or not qBoneLocalRotation then return end

	local vPositionOffset		= self:GetPositionOffsetByItemType(sItemType)
	local vRotationOffset		= self:GetRotationOffsetByItemType(sItemType)
	local qRotationOffset		= Quaternion.new(vRotationOffset)
	local qSlotRotation			= qBoneLocalRotation * qRotationOffset
	local vSlotPosition			= vBoneLocalPosition + (qBoneLocalRotation * vPositionOffset)

	oSlotTransform:SetLocalPosition(vSlotPosition)
	oSlotTransform:SetLocalRotation(qSlotRotation)
end

function PlayerItemMounts:EquipItem(oItemBehaviour)
	if not oItemBehaviour then return false end

	local sItemType				= oItemBehaviour.GetItemType and oItemBehaviour:GetItemType() or ""
	local oSlotActor				= self:GetSlotActorByItemType(sItemType)
	local oCurrentItemBehaviour	= self:GetEquippedItemByItemType(sItemType)

	if not oSlotActor then return false end

	if oCurrentItemBehaviour and oCurrentItemBehaviour ~= oItemBehaviour then
		if oCurrentItemBehaviour.ForceUnequip then
			oCurrentItemBehaviour:ForceUnequip(true)
		end

		self:SetEquippedItemByItemType(sItemType, nil)
	end

	local oItemActor	= oItemBehaviour.owner
	oItemActor:SetParent(oSlotActor)

	local oItemTransform		= oItemActor:GetTransform()
	local vEquipLocalPosition	= oItemBehaviour.GetEquipLocalPosition and oItemBehaviour:GetEquipLocalPosition() or Vector3.new(0, 0, 0)
	local vEquipLocalRotation	= oItemBehaviour.GetEquipLocalRotation and oItemBehaviour:GetEquipLocalRotation() or Vector3.new(0, 0, 0)

	oItemTransform:SetLocalPosition(vEquipLocalPosition)
	oItemTransform:SetLocalRotation(Quaternion.new(vEquipLocalRotation))
	oItemTransform:SetLocalScale(Vector3.new(1, 1, 1))

	self:SetEquippedItemByItemType(sItemType, oItemBehaviour)

	return true
end

function PlayerItemMounts:UnequipItem(oItemBehaviour, bDetachToWorld)
	if not oItemBehaviour then return false end

	local sItemType				= oItemBehaviour.GetItemType and oItemBehaviour:GetItemType() or ""
	local oCurrentItemBehaviour	= self:GetEquippedItemByItemType(sItemType)

	if not oCurrentItemBehaviour or oCurrentItemBehaviour ~= oItemBehaviour then
		return false
	end

	self:SetEquippedItemByItemType(sItemType, nil)

	if bDetachToWorld then
		oItemBehaviour.owner:DetachFromParent()
	end

	return true
end

function PlayerItemMounts:IsSupportedItemType(sItemType)
	return sItemType == "HELMET" or sItemType == "JPC" or sItemType == "BELT"
end

function PlayerItemMounts:GetEquippedItemByItemType(sItemType)
	if sItemType == "HELMET" then
		return self._private.oEquippedHelmetItem
	end

	if sItemType == "JPC" then
		return self._private.oEquippedJpcItem
	end

	if sItemType == "BELT" then
		return self._private.oEquippedBeltItem
	end

	return nil
end

function PlayerItemMounts:SetEquippedItemByItemType(sItemType, oItemBehaviour)
	if sItemType == "HELMET" then
		self._private.oEquippedHelmetItem	= oItemBehaviour
		return
	end

	if sItemType == "JPC" then
		self._private.oEquippedJpcItem		= oItemBehaviour
		return
	end

	if sItemType == "BELT" then
		self._private.oEquippedBeltItem		= oItemBehaviour
	end
end

function PlayerItemMounts:GetSlotActorByItemType(sItemType)
	if sItemType == "HELMET" then
		return self._private.oHelmetSlotActor
	end

	if sItemType == "JPC" then
		return self._private.oJpcSlotActor
	end

	if sItemType == "BELT" then
		return self._private.oBeltSlotActor
	end

	return nil
end

function PlayerItemMounts:GetSlotTransformByItemType(sItemType)
	if sItemType == "HELMET" then
		return self._private.oHelmetSlotTransform
	end

	if sItemType == "JPC" then
		return self._private.oJpcSlotTransform
	end

	if sItemType == "BELT" then
		return self._private.oBeltSlotTransform
	end

	return nil
end

function PlayerItemMounts:GetBoneIndexByItemType(sItemType)
	if sItemType == "HELMET" then
		return self._private.nHelmetBoneIndex
	end

	if sItemType == "JPC" then
		return self._private.nJpcBoneIndex
	end

	if sItemType == "BELT" then
		return self._private.nBeltBoneIndex
	end

	return nil
end

function PlayerItemMounts:GetPositionOffsetByItemType(sItemType)
	if sItemType == "HELMET" then
		return Vector3.new(self.HELMET_OFFSET_X, self.HELMET_OFFSET_Y, self.HELMET_OFFSET_Z)
	end

	if sItemType == "JPC" then
		return Vector3.new(self.JPC_OFFSET_X, self.JPC_OFFSET_Y, self.JPC_OFFSET_Z)
	end

	if sItemType == "BELT" then
		return Vector3.new(self.BELT_OFFSET_X, self.BELT_OFFSET_Y, self.BELT_OFFSET_Z)
	end

	return Vector3.new(0, 0, 0)
end

function PlayerItemMounts:GetRotationOffsetByItemType(sItemType)
	if sItemType == "HELMET" then
		return Vector3.new(self.HELMET_OFFSET_PITCH, self.HELMET_OFFSET_YAW, self.HELMET_OFFSET_ROLL)
	end

	if sItemType == "JPC" then
		return Vector3.new(self.JPC_OFFSET_PITCH, self.JPC_OFFSET_YAW, self.JPC_OFFSET_ROLL)
	end

	if sItemType == "BELT" then
		return Vector3.new(self.BELT_OFFSET_PITCH, self.BELT_OFFSET_YAW, self.BELT_OFFSET_ROLL)
	end

	return Vector3.new(0, 0, 0)
end

function PlayerItemMounts:ResolveModelActor()
	local sModelActorName	= self._private.sModelActorName
	local oModelActor		= self:FindActorByNameRecursive(self.owner, sModelActorName)

	return oModelActor or self.owner
end

function PlayerItemMounts:ResolveSkinnedMeshRenderer(oModelActor)
	local oSkinnedMeshRenderer	= oModelActor and oModelActor:GetSkinnedMeshRenderer() or nil

	return oSkinnedMeshRenderer or self:FindSkinnedMeshRendererRecursive(oModelActor)
end

function PlayerItemMounts:ResolveBoneIndex(oSkinnedMeshRenderer, sBoneName)
	return oSkinnedMeshRenderer and oSkinnedMeshRenderer:GetBoneIndex(sBoneName) or nil
end

function PlayerItemMounts:FindSkinnedMeshRendererRecursive(oActor)
	if not oActor then return nil end

	local oSkinnedMeshRenderer	= oActor:GetSkinnedMeshRenderer()
	if oSkinnedMeshRenderer then
		return oSkinnedMeshRenderer
	end

	local tChildren	= oActor:GetChildren()

	for _, oChildActor in ipairs(tChildren) do
		local oFoundSkinnedMeshRenderer	= self:FindSkinnedMeshRendererRecursive(oChildActor)

		if oFoundSkinnedMeshRenderer then
			return oFoundSkinnedMeshRenderer
		end
	end

	return nil
end

function PlayerItemMounts:ResolveClassBehaviour()
	local oCurrentActor	= self.owner

	while oCurrentActor do
		local oClass	= oCurrentActor:GetBehaviour("Class")

		if oClass then
			return oClass
		end

		oCurrentActor	= oCurrentActor:GetParent()
	end

	return {}
end

return PlayerItemMounts
