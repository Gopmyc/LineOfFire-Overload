---@class Crouch : Behaviour
local Crouch	=
{
	CROUCH_HEIGHT_MULTIPLIER	= 0.55,
	CROUCH_CHECK_SKIN			= 0.01,
	CROUCH_CHECK_MARGIN			= 0.02,
	CROUCH_KEY					= Key.LEFT_CONTROL,

	_private	=
	{
		oTransform					= nil,
		oPhysicalCapsule			= nil,
		oVisualRootTransform		= nil,
		vVisualStandingLocalPosition	= nil,
		bIsCrouching				= false,
		nStandingHeight				= 0.0,
		nCrouchingHeight			= 0.0,
		sVisualRootActorName		= "Player Visual Root",
		sModelActorName				= "Player Model",
	}
}

function Crouch:OnAwake()
	local oPhysicalCapsule				= self.owner:GetPhysicalCapsule()

	self									= setmetatable(self,  self.owner:GetBehaviour("Class"))

	local oVisualRootTransform, vVisualStandingLocalPosition	= self:ResolveVisualRootTransform()

	self._private.oTransform				= self.owner:GetTransform()
	self._private.oPhysicalCapsule			= oPhysicalCapsule
	self._private.oVisualRootTransform		= oVisualRootTransform
	self._private.vVisualStandingLocalPosition	= vVisualStandingLocalPosition
	self._private.nStandingHeight			= oPhysicalCapsule:GetHeight()
	self._private.nCrouchingHeight			= self._private.nStandingHeight * self.CROUCH_HEIGHT_MULTIPLIER

	self:UpdateVisualVerticalOffset(self._private.nStandingHeight)
end

function Crouch:OnFixedUpdate(nFixedDeltaTime)
	self:HandleCrouch()
end

function Crouch:HandleCrouch()
	local bWantsCrouch	= Inputs.GetKey(self.CROUCH_KEY)
	local bIsCrouching	= self._private.bIsCrouching

	if bWantsCrouch and not bIsCrouching then
		self:EnterCrouch()
	end

	if not bWantsCrouch and bIsCrouching and self:CanExitCrouch() then
		self:ExitCrouch()
	end
end

function Crouch:CanExitCrouch()
	local oPhysicalCapsule		= self._private.oPhysicalCapsule
	local oTransform			= self._private.oTransform
	local nStandingHeight		= self._private.nStandingHeight
	local nCurrentHeight		= oPhysicalCapsule:GetHeight()
	local nRadius				= oPhysicalCapsule:GetRadius()
	local nCurrentTopOffset		= (nCurrentHeight * 0.5) + nRadius
	local nStandingTopOffset	= (nStandingHeight * 0.5) + nRadius
	local nRequiredClearance	= nStandingTopOffset - nCurrentTopOffset

	if nRequiredClearance <= 0 then return true end

	local vCheckOrigin		= oTransform:GetPosition() + (Vector3.Up() * (nCurrentTopOffset + self.CROUCH_CHECK_SKIN))
	local nCheckDistance	= nRequiredClearance + self.CROUCH_CHECK_MARGIN
	local oHit				= Physics.Raycast(vCheckOrigin, Vector3.Up(), nCheckDistance)

	return not self:HasBlockingHit(oHit)
end

function Crouch:HasBlockingHit(oHit)
	if not oHit then return false end

	local tHitObjects	= oHit.ResultObjects
	if tHitObjects and #tHitObjects > 0 then
		for _, oHitObject in ipairs(tHitObjects) do
			if self:IsBlockingHitObject(oHitObject) then
				return true
			end
		end

		return false
	end

	return self:IsBlockingHitObject(oHit.FirstResultObject)
end

function Crouch:IsBlockingHitObject(oHitObject)
	local oHitActor		= self:ResolveHitActor(oHitObject)
	local oOwnerActor	= self.owner
	local bIsSelfActor	= oHitActor == oOwnerActor
	local bIsChildActor	= oHitActor and oHitActor:IsDescendantOf(oOwnerActor) or false

	return not bIsSelfActor and not bIsChildActor
end

function Crouch:ResolveHitActor(oHitObject)
	return oHitObject and (oHitObject.GetOwner and oHitObject:GetOwner() or oHitObject) or nil
end

function Crouch:EnterCrouch()
	self:SetCapsuleHeight(self._private.nCrouchingHeight)

	self._private.bIsCrouching	= true
end

function Crouch:ExitCrouch()
	self:SetCapsuleHeight(self._private.nStandingHeight)

	self._private.bIsCrouching	= false
end

function Crouch:SetCapsuleHeight(nTargetHeight)
	local oPhysicalCapsule	= self._private.oPhysicalCapsule
	local oTransform		= self._private.oTransform

	local nCurrentHeight	= oPhysicalCapsule:GetHeight()
	local nHeightDelta		= nTargetHeight - nCurrentHeight

	if nHeightDelta == 0 then return end

	oPhysicalCapsule:SetHeight(nTargetHeight)

	local vPosition	= oTransform:GetPosition()
	vPosition.y		= vPosition.y + (nHeightDelta * 0.5)

	oTransform:SetWorldPosition(vPosition)
	self:UpdateVisualVerticalOffset(nTargetHeight)
end

function Crouch:ResolveVisualRootTransform()
	local sVisualRootActorName	= self._private.sVisualRootActorName
	local sModelActorName		= self._private.sModelActorName
	local oVisualRootActor		= self:FindActorByNameRecursive(self.owner, sVisualRootActorName)
	local oModelActor			= self:FindActorByNameRecursive(self.owner, sModelActorName)
	local oVisualRootTransform	= oVisualRootActor and oVisualRootActor:GetTransform() or (oModelActor and oModelActor:GetTransform() or nil)
	local vVisualStandingLocalPosition	= oVisualRootTransform and oVisualRootTransform:GetLocalPosition() or nil

	return oVisualRootTransform, vVisualStandingLocalPosition
end

function Crouch:UpdateVisualVerticalOffset(nCurrentHeight)
	local oVisualRootTransform			= self._private.oVisualRootTransform
	local vVisualStandingLocalPosition	= self._private.vVisualStandingLocalPosition

	if not oVisualRootTransform or not vVisualStandingLocalPosition then return end

	local nStandingHeight		= self._private.nStandingHeight
	local nHalfHeightReduction	= (nStandingHeight - nCurrentHeight) * 0.5
	local vTargetLocalPosition	= Vector3.new(
		vVisualStandingLocalPosition.x,
		vVisualStandingLocalPosition.y + nHalfHeightReduction,
		vVisualStandingLocalPosition.z
	)

	oVisualRootTransform:SetLocalPosition(vTargetLocalPosition)
end

function Crouch:IsCrouching()
	return self._private.bIsCrouching
end

return Crouch
