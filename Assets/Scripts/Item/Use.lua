---@class Use : Behaviour
local Use	=
{
	INTERACT_KEY			= Key.F,
	ALT_INTERACT_KEY		= Key.E,
	MAX_INTERACT_DISTANCE	= 2.5,
	MIN_LOOK_DOT			= 0.35,
	ENABLE_USE_LOG			= true,
	DISABLE_ITEM_ON_USE		= true,

	_private	=
	{
		sPlayerCameraActorName	= "Player Camera",
		sPlayerActorName		= "Player",
		oPlayerCameraActor		= nil,
		oPlayerCameraTransform	= nil,
		bIsPlayerLookingAtItem	= false,
		bDidUseThisFrame		= false,
	}
}

function Use:OnAwake()
	self								= setmetatable(self, self:ResolveClassBehaviour())
	self._private.oPlayerCameraActor		= nil
	self._private.oPlayerCameraTransform	= nil
	self._private.bIsPlayerLookingAtItem	= false
	self._private.bDidUseThisFrame		= false
end

function Use:OnUpdate(nDeltaTime)
	self._private.bDidUseThisFrame		= false
	self._private.bIsPlayerLookingAtItem	= false

	if not self:IsInteractPressed() then return end

	local oPlayerCameraTransform	= self:ResolvePlayerCameraTransform()
	if not oPlayerCameraTransform then return end

	local bIsPlayerLookingAtItem	= self:IsPlayerLookingAtItem(oPlayerCameraTransform)
	self._private.bIsPlayerLookingAtItem	= bIsPlayerLookingAtItem

	if not bIsPlayerLookingAtItem then return end

	self._private.bDidUseThisFrame	= true

	self:OnUseByPlayer(oPlayerCameraTransform)
end

function Use:OnUseByPlayer(oPlayerCameraTransform)
	local bEnableUseLog		= self.ENABLE_USE_LOG
	local bDisableItemOnUse	= self.DISABLE_ITEM_ON_USE

	if bEnableUseLog then
		Debug.Log("Use: player used item '" .. self.owner:GetName() .. "'")
	end

	if bDisableItemOnUse then
		self.owner:SetActive(false)
	end
end

function Use:IsPlayerLookingAtItem(oPlayerCameraTransform)
	local vRayOrigin		= oPlayerCameraTransform:GetWorldPosition()
	local vRayDirection		= oPlayerCameraTransform:GetForward()
	local oRaycastHit		= Physics.Raycast(vRayOrigin, vRayDirection, self.MAX_INTERACT_DISTANCE)
	local oFirstResultObject	= oRaycastHit and oRaycastHit.FirstResultObject or nil

	if self:IsHitObjectMatchingItem(oFirstResultObject) then
		return true
	end

	local tResultObjects	= oRaycastHit and oRaycastHit.ResultObjects or nil
	local bHasRaycastHit	= oRaycastHit ~= nil

	if tResultObjects and #tResultObjects > 0 then
		for _, oHitObject in ipairs(tResultObjects) do
			if self:IsHitObjectMatchingItem(oHitObject) then
				return true
			end
		end
	end

	if bHasRaycastHit then
		return false
	end

	return self:IsItemInViewCone(oPlayerCameraTransform)
end

function Use:IsInteractPressed()
	local nPrimaryInteractKey	= self.INTERACT_KEY
	local nSecondaryInteractKey	= self.ALT_INTERACT_KEY
	local bPrimaryPressed		= nPrimaryInteractKey and Inputs.GetKeyDown(nPrimaryInteractKey) or false
	local bSecondaryPressed		= nSecondaryInteractKey and Inputs.GetKeyDown(nSecondaryInteractKey) or false

	return bPrimaryPressed or bSecondaryPressed
end

function Use:IsItemInViewCone(oPlayerCameraTransform)
	local oItemTransform		= self.owner:GetTransform()
	local vItemWorldPosition	= oItemTransform and oItemTransform:GetWorldPosition() or nil
	local vCameraWorldPosition	= oPlayerCameraTransform:GetWorldPosition()
	local vCameraForward		= oPlayerCameraTransform:GetForward()
	local vToItem				= vItemWorldPosition and (vItemWorldPosition - vCameraWorldPosition) or nil
	local nDistanceToItem		= vToItem and vToItem:Length() or 0.0
	local nMaxDistance			= self.MAX_INTERACT_DISTANCE

	if not vToItem or nDistanceToItem <= 0.0001 or nDistanceToItem > nMaxDistance then
		return false
	end

	local vDirectionToItem	= vToItem / nDistanceToItem
	local nViewDot			= vCameraForward:Dot(vDirectionToItem)

	return nViewDot >= self.MIN_LOOK_DOT
end

function Use:IsHitObjectMatchingItem(oHitObject)
	local oHitActor	= self:ResolveHitActor(oHitObject)
	if not oHitActor then return false end

	return oHitActor == self.owner or oHitActor:IsDescendantOf(self.owner)
end

function Use:ResolveHitActor(oHitObject)
	return oHitObject and (oHitObject.GetOwner and oHitObject:GetOwner() or oHitObject) or nil
end

function Use:ResolvePlayerCameraTransform()
	local oCachedPlayerCameraTransform	= self._private.oPlayerCameraTransform

	if oCachedPlayerCameraTransform then
		return oCachedPlayerCameraTransform
	end

	local oScene					= Scenes.GetCurrentScene()
	local sPlayerCameraActorName	= self._private.sPlayerCameraActorName
	local sPlayerActorName			= self._private.sPlayerActorName
	local oPlayerCameraActor		= oScene and oScene:FindActorByName(sPlayerCameraActorName) or nil
	local oPlayerActor				= oPlayerCameraActor and nil or (oScene and oScene:FindActorByName(sPlayerActorName) or nil)

	if not oPlayerCameraActor and oPlayerActor then
		local bIsPlayerCameraOwner	= oPlayerActor:GetName() == sPlayerCameraActorName

		oPlayerCameraActor	= bIsPlayerCameraOwner and oPlayerActor or oPlayerActor:FindChild(sPlayerCameraActorName, true)
	end

	local oPlayerCameraTransform	= oPlayerCameraActor and oPlayerCameraActor:GetTransform() or nil

	self._private.oPlayerCameraActor	= oPlayerCameraActor
	self._private.oPlayerCameraTransform	= oPlayerCameraTransform

	return oPlayerCameraTransform
end

function Use:IsLookedAt()
	return self._private.bIsPlayerLookingAtItem
end

function Use:DidUseThisFrame()
	return self._private.bDidUseThisFrame
end

function Use:ResolveClassBehaviour()
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

return Use
