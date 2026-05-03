---@class CharacterMotor : Behaviour
local CharacterMotor	=
{
	GROUND_MAX_SPEED				= 8.0,
	AIR_MAX_SPEED					= 5.0,
	GROUND_ACCELERATION				= 50.0,
	GROUND_BRAKE_ACCELERATION		= 60.0,
	AIR_ACCELERATION				= 10.0,
	AIR_BRAKE_ACCELERATION			= 1.25,
	MIN_FORCE_DELTA_SPEED			= 0.005,
	MIN_MASS						= 0.0001,

	_private	= {
		oPhysicalCapsule	= nil,
		oJump				= nil,
		oCrouch				= nil,
	},
}

function CharacterMotor:OnAwake()
	self					= setmetatable(self,  self.owner:GetBehaviour("Class"))

	self.oPhysicalCapsule	= self.owner:GetPhysicalCapsule()
	self.oJump				= self.owner:GetBehaviour("Jump")
	self.oCrouch			= self.owner:GetBehaviour("Crouch")

	self.oPhysicalCapsule:SetAngularFactor(Vector3.new(0, 1, 0))
	self.oPhysicalCapsule:SetAngularVelocity(Vector3.new(0, 0, 0))
end

function CharacterMotor:OnFixedUpdate(nFixedDeltaTime)
	self:HandleMovement(nFixedDeltaTime)
end

function CharacterMotor:HandleMovement(nFixedDeltaTime)
	local oPhysicalCapsule	= self.oPhysicalCapsule
	local oTransform		= self.owner:GetTransform()
	local vInputDirection	= self:GetInputDirection(oTransform)
	local bHasInput			= vInputDirection:Length() > 0
	local bIsGrounded		= self:IsGrounded()
	local nSpeedMultiplier	= self:GetSpeedMultiplier()
	local nBaseSpeed		= bIsGrounded and self.GROUND_MAX_SPEED or self.AIR_MAX_SPEED
	local nTargetSpeed		= nBaseSpeed * nSpeedMultiplier
	local vCurrentVelocity	= oPhysicalCapsule:GetLinearVelocity()
	local vCurrentPlanar	= Vector3.new(vCurrentVelocity.x, 0, vCurrentVelocity.z)
	local vTargetPlanar		= bHasInput and (vInputDirection:Normalize() * nTargetSpeed) or Vector3.new(0, 0, 0)
	local nAcceleration		= bHasInput and (bIsGrounded and self.GROUND_ACCELERATION or self.AIR_ACCELERATION) or (bIsGrounded and self.GROUND_BRAKE_ACCELERATION or self.AIR_BRAKE_ACCELERATION)

	vTargetPlanar			= (not bIsGrounded and not bHasInput) and vCurrentPlanar or vTargetPlanar

	self:ApplyPlanarForce(oPhysicalCapsule, vCurrentPlanar, vTargetPlanar, nAcceleration, nFixedDeltaTime)
end

function CharacterMotor:GetInputDirection(oTransform)
	local vDirection	= Vector3.new(0, 0, 0)
	local vForward		= oTransform:GetForward()
	local vRight		= oTransform:GetRight()

	if Inputs.GetKey(Key.A) then vDirection	= vDirection - vRight end
	if Inputs.GetKey(Key.D) then vDirection	= vDirection + vRight end
	if Inputs.GetKey(Key.W) then vDirection	= vDirection + vForward end
	if Inputs.GetKey(Key.S) then vDirection	= vDirection - vForward end

	return vDirection
end

function CharacterMotor:IsGrounded()
	return self.oJump:IsGrounded()
end

function CharacterMotor:GetSpeedMultiplier()
	return self.oCrouch:GetSpeedMultiplier()
end

function CharacterMotor:ApplyPlanarForce(oPhysicalCapsule, vCurrentPlanar, vTargetPlanar, nAcceleration, nFixedDeltaTime)
	local vDeltaPlanar	= vTargetPlanar - vCurrentPlanar
	local nDeltaSpeed	= vDeltaPlanar:Length()

	if nDeltaSpeed <= self.MIN_FORCE_DELTA_SPEED then
		return
	end

	local nMaxDeltaSpeed	= nAcceleration * nFixedDeltaTime
	local vAppliedDelta		= nDeltaSpeed > nMaxDeltaSpeed and (vDeltaPlanar:Normalize() * nMaxDeltaSpeed) or vDeltaPlanar
	local nMass				= oPhysicalCapsule:GetMass()
	local nValidMass		= nMass > self.MIN_MASS and nMass or self.MIN_MASS
	local vForce			= (vAppliedDelta / nFixedDeltaTime) * nValidMass

	oPhysicalCapsule:AddForce(Vector3.new(vForce.x, 0, vForce.z))
end

return CharacterMotor
