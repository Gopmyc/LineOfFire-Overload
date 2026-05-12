---@class Item : Behaviour
local Item	=
{
	ITEM_ID						= "ITEM_GENERIC",
	ITEM_TYPE					= "HELMET",
	ITEM_MODEL_PATH				= "Models/Equipment/HELMET.fbx",
	ITEM_PRIMARY_MATERIAL_PATH	= "Models/Equipment/HELMET.fbx:embedded_material_0.ovmat",
	PICKUP_KEY					= Key.E,
	EQUIP_KEY					= Key.F,
	DRAG_KEY					= Key.G,
	DROP_KEY					= Key.R,
	AUTO_EQUIP_ON_PICKUP		= false,
	DROP_FORWARD_DISTANCE		= 1.4,
	DROP_VERTICAL_OFFSET		= 0.35,
	DRAG_LOCAL_OFFSET_X			= 0.25,
	DRAG_LOCAL_OFFSET_Y			= -0.2,
	DRAG_LOCAL_OFFSET_Z			= 1.15,
	HELMET_EQUIP_OFFSET_X		= 0.0,
	HELMET_EQUIP_OFFSET_Y		= 0.0,
	HELMET_EQUIP_OFFSET_Z		= 0.0,
	HELMET_EQUIP_PITCH			= 0.0,
	HELMET_EQUIP_YAW			= 0.0,
	HELMET_EQUIP_ROLL			= 0.0,
	JPC_EQUIP_OFFSET_X			= 0.0,
	JPC_EQUIP_OFFSET_Y			= 0.0,
	JPC_EQUIP_OFFSET_Z			= 0.0,
	JPC_EQUIP_PITCH				= 0.0,
	JPC_EQUIP_YAW				= 0.0,
	JPC_EQUIP_ROLL				= 0.0,
	BELT_EQUIP_OFFSET_X			= 0.0,
	BELT_EQUIP_OFFSET_Y			= 0.0,
	BELT_EQUIP_OFFSET_Z			= 0.0,
	BELT_EQUIP_PITCH			= 0.0,
	BELT_EQUIP_YAW				= 0.0,
	BELT_EQUIP_ROLL				= 0.0,

	_private	=
	{
		sVisualActorName			= "Item Visual",
		oVisualActor				= nil,
		oVisualTransform			= nil,
		oModelRenderer				= nil,
		oMaterialRenderer			= nil,
		oPhysicalObject				= nil,
		oPlayerPhysicsActorCandidate	= nil,
		oHolderPlayerPhysicsActor	= nil,
		oHolderCameraTransform		= nil,
		oPlayerItemMounts			= nil,
		bIsHeld					= false,
		bIsEquipped				= false,
		bIsDragging				= false,
	}
}

function Item:OnAwake()
	self							= setmetatable(self, self:ResolveClassBehaviour())

	local oVisualActor				= self:ResolveVisualActor()
	local oVisualTransform			= oVisualActor and oVisualActor:GetTransform() or nil
	local oModelRenderer			= oVisualActor and oVisualActor:GetModelRenderer() or nil
	local oMaterialRenderer			= oVisualActor and oVisualActor:GetMaterialRenderer() or nil
	local oPhysicalObject			= self.owner:GetPhysicalObject()

	self._private.oVisualActor		= oVisualActor
	self._private.oVisualTransform		= oVisualTransform
	self._private.oModelRenderer		= oModelRenderer
	self._private.oMaterialRenderer		= oMaterialRenderer
	self._private.oPhysicalObject		= oPhysicalObject
	self._private.oPlayerPhysicsActorCandidate	= nil
	self._private.oHolderPlayerPhysicsActor		= nil
	self._private.oHolderCameraTransform			= nil
	self._private.oPlayerItemMounts				= nil
	self._private.bIsHeld						= false
	self._private.bIsEquipped					= false
	self._private.bIsDragging					= false

	self:SetItemModelPath(self.ITEM_MODEL_PATH, self.ITEM_PRIMARY_MATERIAL_PATH)

	if self.owner:GetTag() == "" then
		self.owner:SetTag("Item")
	end
end

function Item:OnUpdate(nDeltaTime)
	if not self._private.bIsHeld then
		local oPlayerPhysicsActorCandidate	= self._private.oPlayerPhysicsActorCandidate
		if oPlayerPhysicsActorCandidate and Inputs.GetKeyDown(self.PICKUP_KEY) then
			self:Pickup(oPlayerPhysicsActorCandidate)
		end

		return
	end

	if Inputs.GetKeyDown(self.DRAG_KEY) then
		self:ToggleDrag()
	end

	if Inputs.GetKeyDown(self.EQUIP_KEY) then
		self:ToggleEquip()
	end

	if Inputs.GetKeyDown(self.DROP_KEY) then
		self:Drop()
		return
	end

	if self._private.bIsDragging then
		self:UpdateDraggedTransform()
	end
end

function Item:OnTriggerEnter(oTriggeredBy)
	if self._private.bIsHeld then return end

	local oPlayerPhysicsActor	= self:ResolvePlayerPhysicsActor(oTriggeredBy)

	if not oPlayerPhysicsActor then return end

	self._private.oPlayerPhysicsActorCandidate	= oPlayerPhysicsActor
end

function Item:OnTriggerExit(oTriggeredBy)
	local oPlayerPhysicsActor			= self:ResolvePlayerPhysicsActor(oTriggeredBy)
	local oPlayerPhysicsActorCandidate	= self._private.oPlayerPhysicsActorCandidate

	if not oPlayerPhysicsActor or oPlayerPhysicsActorCandidate ~= oPlayerPhysicsActor then return end

	self._private.oPlayerPhysicsActorCandidate	= nil
end

function Item:Pickup(oPlayerPhysicsActor)
	if self._private.bIsHeld then return true end
	if not oPlayerPhysicsActor then return false end

	local oPlayerItemMounts				= self:ResolvePlayerItemMounts(oPlayerPhysicsActor)
	local oHolderCameraTransform		= self:ResolvePlayerCameraTransform(oPlayerPhysicsActor)

	self._private.oHolderPlayerPhysicsActor		= oPlayerPhysicsActor
	self._private.oHolderCameraTransform			= oHolderCameraTransform
	self._private.oPlayerItemMounts				= oPlayerItemMounts
	self._private.oPlayerPhysicsActorCandidate	= nil
	self._private.bIsHeld						= true
	self._private.bIsDragging					= false

	self.owner:SetParent(oPlayerPhysicsActor)
	self.owner:GetTransform():SetLocalPosition(Vector3.new(0, 0, 0))
	self.owner:GetTransform():SetLocalRotation(Quaternion.new(Vector3.new(0, 0, 0)))

	self:SetWorldInteractionEnabled(false)

	local bCanAutoEquip	= self.AUTO_EQUIP_ON_PICKUP and self:IsEquippableType()
	if bCanAutoEquip then
		self:Equip()
	end

	return true
end

function Item:Drop()
	if not self._private.bIsHeld then return false end

	if self._private.bIsDragging then
		self:StopDrag()
	end

	if self._private.bIsEquipped then
		self:Unequip(true)
	end

	local oHolderPlayerPhysicsActor	= self._private.oHolderPlayerPhysicsActor
	local oHolderTransform			= oHolderPlayerPhysicsActor and oHolderPlayerPhysicsActor:GetTransform() or nil

	self.owner:DetachFromParent()

	if oHolderTransform then
		local vDropPosition	= oHolderTransform:GetWorldPosition() + (oHolderTransform:GetForward() * self.DROP_FORWARD_DISTANCE) + (Vector3.new(0, self.DROP_VERTICAL_OFFSET, 0))

		self.owner:GetTransform():SetWorldPosition(vDropPosition)
		self.owner:GetTransform():SetWorldRotation(Quaternion.new(Vector3.new(0, oHolderTransform:GetWorldRotation():EulerAngles().y, 0)))
	end

	self._private.oHolderPlayerPhysicsActor		= nil
	self._private.oHolderCameraTransform			= nil
	self._private.oPlayerItemMounts				= nil
	self._private.bIsHeld						= false
	self._private.bIsDragging					= false
	self._private.bIsEquipped					= false
	self._private.oPlayerPhysicsActorCandidate	= nil

	self:SetWorldInteractionEnabled(true)

	return true
end

function Item:ToggleEquip()
	if not self._private.bIsHeld then return false end

	if self._private.bIsEquipped then
		return self:Unequip(true)
	end

	return self:Equip()
end

function Item:Equip()
	if not self._private.bIsHeld or self._private.bIsEquipped then return false end
	if not self:IsEquippableType() then return false end

	if self._private.bIsDragging then
		self:StopDrag()
	end

	local oPlayerItemMounts	= self._private.oPlayerItemMounts
	if not oPlayerItemMounts then return false end

	local bDidEquip	= oPlayerItemMounts:EquipItem(self)
	if not bDidEquip then return false end

	self._private.bIsEquipped	= true

	return true
end

function Item:Unequip(bKeepItemParentedToHolder)
	if not self._private.bIsEquipped then return true end

	local oPlayerItemMounts	= self._private.oPlayerItemMounts
	if oPlayerItemMounts then
		oPlayerItemMounts:UnequipItem(self, false)
	end

	self._private.bIsEquipped	= false

	local bShouldKeepParented		= bKeepItemParentedToHolder == nil and true or bKeepItemParentedToHolder
	local oHolderPlayerPhysicsActor	= self._private.oHolderPlayerPhysicsActor

	if bShouldKeepParented and oHolderPlayerPhysicsActor then
		self.owner:SetParent(oHolderPlayerPhysicsActor)
		self.owner:GetTransform():SetLocalPosition(Vector3.new(0, 0, 0))
		self.owner:GetTransform():SetLocalRotation(Quaternion.new(Vector3.new(0, 0, 0)))
	end

	return true
end

function Item:ForceUnequip(bKeepItemParentedToHolder)
	local bShouldKeepParented	= bKeepItemParentedToHolder == nil and true or bKeepItemParentedToHolder

	self:Unequip(bShouldKeepParented)
end

function Item:ToggleDrag()
	if not self._private.bIsHeld or self._private.bIsEquipped then return false end

	local bIsDragging	= self._private.bIsDragging

	return bIsDragging and self:StopDrag() or self:StartDrag()
end

function Item:StartDrag()
	if self._private.bIsDragging then return true end

	local oHolderCameraTransform	= self._private.oHolderCameraTransform
	local oHolderCameraActor		= oHolderCameraTransform and oHolderCameraTransform:GetOwner() or nil

	if not oHolderCameraActor then return false end

	self.owner:SetParent(oHolderCameraActor)

	local oItemTransform	= self.owner:GetTransform()

	oItemTransform:SetLocalPosition(Vector3.new(self.DRAG_LOCAL_OFFSET_X, self.DRAG_LOCAL_OFFSET_Y, self.DRAG_LOCAL_OFFSET_Z))
	oItemTransform:SetLocalRotation(Quaternion.new(Vector3.new(0, 180, 0)))
	oItemTransform:SetLocalScale(Vector3.new(1, 1, 1))

	self._private.bIsDragging	= true

	return true
end

function Item:StopDrag()
	if not self._private.bIsDragging then return true end

	local oHolderPlayerPhysicsActor	= self._private.oHolderPlayerPhysicsActor

	if oHolderPlayerPhysicsActor then
		self.owner:SetParent(oHolderPlayerPhysicsActor)
		self.owner:GetTransform():SetLocalPosition(Vector3.new(0, 0, 0))
		self.owner:GetTransform():SetLocalRotation(Quaternion.new(Vector3.new(0, 0, 0)))
	end

	self._private.bIsDragging	= false

	return true
end

function Item:UpdateDraggedTransform()
	local oHolderCameraTransform	= self._private.oHolderCameraTransform
	if not oHolderCameraTransform then return end

	local oItemTransform	= self.owner:GetTransform()
	oItemTransform:SetLocalPosition(Vector3.new(self.DRAG_LOCAL_OFFSET_X, self.DRAG_LOCAL_OFFSET_Y, self.DRAG_LOCAL_OFFSET_Z))
end

function Item:SetItemModelPath(sModelPath, sPrimaryMaterialPath)
	local oModelRenderer	= self._private.oModelRenderer
	if not oModelRenderer or not sModelPath or sModelPath == "" then return false end

	local oModel	= Resources.GetModel(sModelPath)
	if not oModel then return false end

	oModelRenderer:SetModel(oModel)

	local sResolvedMaterialPath	= (sPrimaryMaterialPath and sPrimaryMaterialPath ~= "") and sPrimaryMaterialPath or (sModelPath .. ":embedded_material_0.ovmat")
	local oMaterialRenderer		= self._private.oMaterialRenderer
	local oMaterial				= oMaterialRenderer and Resources.GetMaterial(sResolvedMaterialPath) or nil

	if oMaterialRenderer and oMaterial then
		oMaterialRenderer:SetMaterial(0, oMaterial)
	end

	self.ITEM_MODEL_PATH				= sModelPath
	self.ITEM_PRIMARY_MATERIAL_PATH	= sPrimaryMaterialPath or ""

	return true
end

function Item:GetItemType()
	return self.ITEM_TYPE
end

function Item:GetEquipLocalPosition()
	local sItemType	= self.ITEM_TYPE

	if sItemType == "HELMET" then
		return Vector3.new(self.HELMET_EQUIP_OFFSET_X, self.HELMET_EQUIP_OFFSET_Y, self.HELMET_EQUIP_OFFSET_Z)
	end

	if sItemType == "JPC" then
		return Vector3.new(self.JPC_EQUIP_OFFSET_X, self.JPC_EQUIP_OFFSET_Y, self.JPC_EQUIP_OFFSET_Z)
	end

	if sItemType == "BELT" then
		return Vector3.new(self.BELT_EQUIP_OFFSET_X, self.BELT_EQUIP_OFFSET_Y, self.BELT_EQUIP_OFFSET_Z)
	end

	return Vector3.new(0, 0, 0)
end

function Item:GetEquipLocalRotation()
	local sItemType	= self.ITEM_TYPE

	if sItemType == "HELMET" then
		return Vector3.new(self.HELMET_EQUIP_PITCH, self.HELMET_EQUIP_YAW, self.HELMET_EQUIP_ROLL)
	end

	if sItemType == "JPC" then
		return Vector3.new(self.JPC_EQUIP_PITCH, self.JPC_EQUIP_YAW, self.JPC_EQUIP_ROLL)
	end

	if sItemType == "BELT" then
		return Vector3.new(self.BELT_EQUIP_PITCH, self.BELT_EQUIP_YAW, self.BELT_EQUIP_ROLL)
	end

	return Vector3.new(0, 0, 0)
end

function Item:IsEquippableType()
	local sItemType	= self.ITEM_TYPE

	return sItemType == "HELMET" or sItemType == "JPC" or sItemType == "BELT"
end

function Item:SetWorldInteractionEnabled(bIsEnabled)
	local oPhysicalObject	= self._private.oPhysicalObject
	if not oPhysicalObject then return end

	oPhysicalObject:SetTrigger(bIsEnabled)
end

function Item:ResolveVisualActor()
	local sVisualActorName	= self._private.sVisualActorName
	local oVisualActor		= self:FindActorByNameRecursive(self.owner, sVisualActorName)

	return oVisualActor or self.owner
end

function Item:ResolvePlayerPhysicsActor(oTriggeredBy)
	local oTriggeredActor	= oTriggeredBy and oTriggeredBy:GetOwner() or nil

	while oTriggeredActor do
		local oController	= oTriggeredActor:GetBehaviour("Controller")

		if oController then
			return oTriggeredActor
		end

		oTriggeredActor	= oTriggeredActor:GetParent()
	end

	return nil
end

function Item:ResolvePlayerItemMounts(oPlayerPhysicsActor)
	local oPlayerActor	= oPlayerPhysicsActor and oPlayerPhysicsActor:GetParent() or nil
	if not oPlayerActor then return nil end

	local oModelActor		= self:FindActorByNameRecursive(oPlayerActor, "Player Model")
	local oPlayerItemMounts	= oModelActor and oModelActor:GetBehaviour("PlayerItemMounts") or nil

	return oPlayerItemMounts
end

function Item:ResolvePlayerCameraTransform(oPlayerPhysicsActor)
	local oPlayerActor	= oPlayerPhysicsActor and oPlayerPhysicsActor:GetParent() or nil
	if not oPlayerActor then return nil end

	local oCameraActor	= self:FindActorByNameRecursive(oPlayerActor, "Player Camera")

	return oCameraActor and oCameraActor:GetTransform() or nil
end

function Item:ResolveClassBehaviour()
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

return Item
