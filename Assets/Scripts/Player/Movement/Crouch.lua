---@class Crouch : Behaviour
local Crouch	=
{
	CROUCH_HEIGHT_MULTIPLIER	= 0.55,
	CROUCH_SPEED_MULTIPLIER		= 0.55,
	CROUCH_CHECK_SKIN			= 0.01,
	CROUCH_CHECK_MARGIN			= 0.02,
	oPhysicalCapsule			= nil,

	_private	=
	{
		bIsCrouching			= false,
		nStandingHeight			= 0.0,
		nCrouchingHeight		= 0.0,
		nCurrentSpeedMultiplier	= 1.0
	}
}

function Crouch:OnAwake()
	local oPhysicalCapsule			= self.owner:GetPhysicalCapsule()

	self							= setmetatable(self,  self.owner:GetBehaviour("Class"))
	self.oPhysicalCapsule			= oPhysicalCapsule
	self.nStandingHeight			= oPhysicalCapsule:GetHeight()
	self.nCrouchingHeight			= self.nStandingHeight * self.CROUCH_HEIGHT_MULTIPLIER
	self.nCurrentSpeedMultiplier	= 1.0
end

function Crouch:OnFixedUpdate(nFixedDeltaTime)
	self:HandleCrouch(nFixedDeltaTime)
end

function Crouch:HandleCrouch(nFixedDeltaTime)
	local bWantsCrouch	= Inputs.GetKey(Key.LEFT_CONTROL)
	local bIsCrouching	= self.bIsCrouching

	if bWantsCrouch and not bIsCrouching then
		self:EnterCrouch()
	end

	if not bWantsCrouch and bIsCrouching and self:CanExitCrouch() then
		self:ExitCrouch()
	end
end

function Crouch:CanExitCrouch()
	local oPhysicalCapsule		= self.oPhysicalCapsule
	local oTransform			= self.owner:GetTransform()
	local nStandingHeight		= self.nStandingHeight
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
	self:SetCapsuleHeight(self.nCrouchingHeight)

	self.bIsCrouching				= true
	self.nCurrentSpeedMultiplier	= self.CROUCH_SPEED_MULTIPLIER
end

function Crouch:ExitCrouch()
	self:SetCapsuleHeight(self.nStandingHeight)

	self.bIsCrouching				= false
	self.nCurrentSpeedMultiplier	= 1.0
end

function Crouch:SetCapsuleHeight(nTargetHeight)
	local oPhysicalCapsule	= self.oPhysicalCapsule
	local oTransform		= self.owner:GetTransform()

	local nCurrentHeight	= oPhysicalCapsule:GetHeight()
	local nHeightDelta		= nTargetHeight - nCurrentHeight

	if nHeightDelta == 0 then return end

	oPhysicalCapsule:SetHeight(nTargetHeight)

	local vPosition	= oTransform:GetPosition()
	vPosition.y		= vPosition.y + (nHeightDelta * 0.5)

	oTransform:SetWorldPosition(vPosition)
end

function Crouch:GetSpeedMultiplier()
	return self.nCurrentSpeedMultiplier
end

function Crouch:IsCrouching()
	return self.bIsCrouching
end

return Crouch
