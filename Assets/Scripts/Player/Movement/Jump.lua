---@class Jump : Behaviour
local Jump	=
{
	JUMP_VELOCITY				= 8.5,
	MAX_GROUNDED_ABS_Y_VELOCITY	= 1.0,
	oPhysicalCapsule			= nil,

	_private	=
	{
		tGroundContacts			= {},
		nGroundContactCount		= 0,
	}
}

function Jump:OnAwake()
	self					= setmetatable(self,  self.owner:GetBehaviour("Class"))
	self.oPhysicalCapsule	= self.owner:GetPhysicalCapsule()
end

function Jump:OnFixedUpdate(nFixedDeltaTime)
	self:HandleJump(nFixedDeltaTime)
end

function Jump:HandleJump(nFixedDeltaTime)
	local oPhysicalCapsule	= self.oPhysicalCapsule
	local bWantsToJump		= Inputs.GetKeyDown(Key.SPACE)
	local bCanJump			= self:IsGrounded()

	if not bWantsToJump or not bCanJump then return end

	local vVelocity	= oPhysicalCapsule:GetLinearVelocity()
	vVelocity.y		= self.JUMP_VELOCITY

	oPhysicalCapsule:SetLinearVelocity(vVelocity)
end

function Jump:IsGrounded()
	local oPhysicalCapsule		= self.oPhysicalCapsule
	local nGroundContactCount	= self._private.nGroundContactCount
	local nVerticalVelocity		= oPhysicalCapsule:GetLinearVelocity().y
	local nAbsVerticalVelocity	= nVerticalVelocity < 0 and -nVerticalVelocity or nVerticalVelocity

	return nGroundContactCount > 0 and nAbsVerticalVelocity <= self.MAX_GROUNDED_ABS_Y_VELOCITY or false
end

function Jump:OnCollisionEnter(oCollideWith)
	self:RegisterGroundContact(oCollideWith)
end

function Jump:OnCollisionStay(oCollideWith)
	self:RegisterGroundContact(oCollideWith)
end

function Jump:OnCollisionExit(oCollideWith)
	self:UnregisterGroundContact(oCollideWith)
end

function Jump:RegisterGroundContact(oCollideWith)
	local oOtherActor	= oCollideWith and oCollideWith:GetOwner() or nil
	local oSelfActor	= self.owner

	if not oOtherActor or oOtherActor == oSelfActor then return end

	local nOtherID			= oOtherActor:GetID()
	local tGroundContacts	= self._private.tGroundContacts

	if tGroundContacts[nOtherID] then return end

	tGroundContacts[nOtherID]			= true
	self._private.nGroundContactCount	= self._private.nGroundContactCount + 1
end

function Jump:UnregisterGroundContact(oCollideWith)
	local oOtherActor	= oCollideWith and oCollideWith:GetOwner() or nil

	if not oOtherActor then return end

	local nOtherID			= oOtherActor:GetID()
	local tGroundContacts	= self._private.tGroundContacts

	if not tGroundContacts[nOtherID] then return end

	tGroundContacts[nOtherID]	= nil

	local nGroundContactCount			= self._private.nGroundContactCount - 1
	self._private.nGroundContactCount	= nGroundContactCount > 0 and nGroundContactCount or 0
end

return Jump
