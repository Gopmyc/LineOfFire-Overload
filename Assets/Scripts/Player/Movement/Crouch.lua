---@class Crouch : Behaviour
local Crouch	=
{
	CROUCH_HEIGHT_MULTIPLIER	= 0.55,
	CROUCH_SPEED_MULTIPLIER		= 0.55,
	CROUCH_CHECK_SKIN			= 0.01,
	CROUCH_CHECK_MARGIN			= 0.02,

	_private	=
	{
		oTransform				= nil,
		oPhysicalCapsule		= nil,
		bIsCrouching			= false,
		nStandingHeight			= 0.0,
		nCrouchingHeight		= 0.0,
		nCurrentSpeedMultiplier	= 1.0,
	}
}

function Crouch:OnAwake()
	local oPhysicalCapsule			= self.owner:GetPhysicalCapsule()

	self								= setmetatable(self,  self.owner:GetBehaviour("Class"))
	self._private.oTransform			= self.owner:GetTransform()
	self._private.oPhysicalCapsule		= oPhysicalCapsule
	self._private.nStandingHeight		= oPhysicalCapsule:GetHeight()
	self._private.nCrouchingHeight		= self._private.nStandingHeight * self.CROUCH_HEIGHT_MULTIPLIER
	self._private.nCurrentSpeedMultiplier	= 1.0
end

function Crouch:OnFixedUpdate(nFixedDeltaTime)
	self:HandleCrouch()
end

function Crouch:HandleCrouch()
	local bWantsCrouch	= Inputs.GetKey(Key.LEFT_CONTROL)
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

	self._private.bIsCrouching			= true
	self._private.nCurrentSpeedMultiplier	= self.CROUCH_SPEED_MULTIPLIER
end

function Crouch:ExitCrouch()
	self:SetCapsuleHeight(self._private.nStandingHeight)

	self._private.bIsCrouching			= false
	self._private.nCurrentSpeedMultiplier	= 1.0
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
end

function Crouch:GetSpeedMultiplier()
	return self._private.nCurrentSpeedMultiplier
end

function Crouch:IsCrouching()
	return self._private.bIsCrouching
end

return Crouch
