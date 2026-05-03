---@class Controller : Behaviour
local Controller	=
{
	GROUND_SPEED					= 8.0,
	AIR_SPEED						= 5.0,
	LEFT_KEY						= Key.A,
	ALT_LEFT_KEY					= Key.Q,
	RIGHT_KEY						= Key.D,
	FORWARD_KEY						= Key.W,
	ALT_FORWARD_KEY				= Key.Z,
	BACKWARD_KEY					= Key.S,

	_private	=
	{
		oTransform					= nil,
		oPhysicalCapsule			= nil,
		oJump						= nil,
		oCrouch						= nil,
	},
}

function Controller:OnAwake()
	self						= setmetatable(self, self.owner:GetBehaviour("Class"))
	self._private.oTransform		= self.owner:GetTransform()
	self._private.oPhysicalCapsule	= self.owner:GetPhysicalCapsule()
	self._private.oJump				= self.owner:GetBehaviour("Jump")
	self._private.oCrouch			= self.owner:GetBehaviour("Crouch")

	self.oPhysicalCapsule:SetAngularFactor(Vector3.new(0, 0, 0))
	self.oPhysicalCapsule:SetAngularVelocity(Vector3.new(0, 0, 0))
end

function Controller:OnFixedUpdate(nFixedDeltaTime)
	self:StabilizeRotation()
	self:HandleMovement()
end

function Controller:StabilizeRotation()
	self.oPhysicalCapsule:SetAngularVelocity(Vector3.new(0, 0, 0))
end

function Controller:HandleMovement()
	local oTransform		= self.oTransform
	local oPhysicalCapsule	= self.oPhysicalCapsule
	local vInputDirection	= self:GetInputDirection(oTransform)
	local nTargetSpeed		= self:GetCurrentMoveSpeed()
	local vPlanarVelocity	= self:ComputePlanarVelocity(vInputDirection, nTargetSpeed)

	self:ApplyPlanarVelocity(oPhysicalCapsule, vPlanarVelocity)
end

function Controller:GetInputDirection(oTransform)
	local vDirection	= Vector3.new(0, 0, 0)
	local vForward		= oTransform:GetForward()
	local vRight		= oTransform:GetRight()

	if Inputs.GetKey(self.LEFT_KEY) or Inputs.GetKey(self.ALT_LEFT_KEY) then vDirection		= vDirection - vRight end
	if Inputs.GetKey(self.RIGHT_KEY) then vDirection										= vDirection + vRight end
	if Inputs.GetKey(self.FORWARD_KEY) or Inputs.GetKey(self.ALT_FORWARD_KEY) then vDirection	= vDirection + vForward end
	if Inputs.GetKey(self.BACKWARD_KEY) then vDirection										= vDirection - vForward end

	return vDirection
end

function Controller:GetCurrentMoveSpeed()
	local bIsGrounded	= self:IsGrounded()
	local nBaseSpeed	= bIsGrounded and self.GROUND_SPEED or self.AIR_SPEED

	return nBaseSpeed * self:GetSpeedMultiplier()
end

function Controller:ComputePlanarVelocity(vInputDirection, nTargetSpeed)
	local bHasInput	= vInputDirection:Length() > 0

	return bHasInput and (vInputDirection:Normalize() * nTargetSpeed) or Vector3.new(0, 0, 0)
end

function Controller:ApplyPlanarVelocity(oPhysicalCapsule, vPlanarVelocity)
	local vCurrentVelocity	= oPhysicalCapsule:GetLinearVelocity()

	oPhysicalCapsule:SetLinearVelocity(Vector3.new(vPlanarVelocity.x, vCurrentVelocity.y, vPlanarVelocity.z))
end

function Controller:IsGrounded()
	local oJump	= self.oJump

	return oJump and oJump:IsGrounded() or false
end

function Controller:GetSpeedMultiplier()
	local oCrouch	= self.oCrouch

	return oCrouch and oCrouch:GetSpeedMultiplier() or 1.0
end

return Controller
