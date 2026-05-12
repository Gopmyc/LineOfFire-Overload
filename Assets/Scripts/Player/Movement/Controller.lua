---@class Controller : Behaviour
local Controller	=
{
	WALK_FORWARD_SPEED				= 8.0,
	WALK_BACKWARD_SPEED				= 7.0,
	WALK_LEFT_SPEED					= 7.5,
	WALK_RIGHT_SPEED				= 7.5,
	RUN_FORWARD_SPEED				= 12.0,
	RUN_BACKWARD_SPEED				= 9.5,
	RUN_LEFT_SPEED					= 8.5,
	RUN_RIGHT_SPEED					= 8.5,
	CROUCH_FORWARD_SPEED			= 4.4,
	CROUCH_BACKWARD_SPEED			= 3.8,
	CROUCH_LEFT_SPEED				= 4.1,
	CROUCH_RIGHT_SPEED				= 4.1,
	AIR_FORWARD_SPEED				= 5.0,
	AIR_BACKWARD_SPEED				= 4.5,
	AIR_LEFT_SPEED					= 4.75,
	AIR_RIGHT_SPEED					= 4.75,
	NORMALIZE_DIAGONAL_INPUT		= true,
	MOVE_SPEED_MULTIPLIER			= 1.0,
	LEFT_KEY						= Key.A,
	ALT_LEFT_KEY					= Key.Q,
	RIGHT_KEY						= Key.D,
	FORWARD_KEY						= Key.W,
	ALT_FORWARD_KEY					= Key.Z,
	BACKWARD_KEY					= Key.S,
	RUN_KEY							= Key.LEFT_SHIFT,
	ALT_RUN_KEY						= Key.RIGHT_SHIFT,

	_private	=
	{
		oTransform					= nil,
		oPhysicalCapsule			= nil,
		oJump						= nil,
		oCrouch						= nil,
		bHasMovementInput			= false,
		bIsRunInputPressed			= false,
		vLastInputDirection			= nil,
	}
}

function Controller:OnAwake()
	local oPhysicalCapsule	= self.owner:GetPhysicalCapsule()

	self								= setmetatable(self, self.owner:GetBehaviour("Class"))
	self._private.oTransform			= self.owner:GetTransform()
	self._private.oPhysicalCapsule		= oPhysicalCapsule
	self._private.oJump					= self.owner:GetBehaviour("Jump")
	self._private.oCrouch				= self.owner:GetBehaviour("Crouch")
	self._private.bHasMovementInput		= false
	self._private.bIsRunInputPressed	= false
	self._private.vLastInputDirection	= Vector3.new(0, 0, 0)

	oPhysicalCapsule:SetAngularFactor(Vector3.new(0, 0, 0))
	oPhysicalCapsule:SetAngularVelocity(Vector3.new(0, 0, 0))
end

function Controller:OnFixedUpdate(nFixedDeltaTime)
	self:StabilizeRotation()
	self:HandleMovement()
end

function Controller:StabilizeRotation()
	local oPhysicalCapsule	= self._private.oPhysicalCapsule

	oPhysicalCapsule:SetAngularVelocity(Vector3.new(0, 0, 0))
end

function Controller:HandleMovement()
	local oTransform				= self._private.oTransform
	local oPhysicalCapsule			= self._private.oPhysicalCapsule
	local nForwardInput, nLateralInput	= self:GetInputAxes()
	local vInputDirection			= self:GetInputDirection(oTransform, nForwardInput, nLateralInput)
	local bHasMovementInput			= nForwardInput ~= 0 or nLateralInput ~= 0
	local bIsRunInputPressed			= self:IsRunInputPressed()
	local vPlanarVelocity			= self:ComputePlanarVelocity(oTransform, nForwardInput, nLateralInput)

	self._private.bHasMovementInput		= bHasMovementInput
	self._private.bIsRunInputPressed	= bIsRunInputPressed
	self._private.vLastInputDirection	= vInputDirection

	self:ApplyPlanarVelocity(oPhysicalCapsule, vPlanarVelocity)
end

function Controller:GetInputAxes()
	local bMoveLeft		= Inputs.GetKey(self.LEFT_KEY) or Inputs.GetKey(self.ALT_LEFT_KEY)
	local bMoveRight	= Inputs.GetKey(self.RIGHT_KEY)
	local bMoveForward	= Inputs.GetKey(self.FORWARD_KEY) or Inputs.GetKey(self.ALT_FORWARD_KEY)
	local bMoveBackward	= Inputs.GetKey(self.BACKWARD_KEY)
	local nForwardInput	= (bMoveForward and 1 or 0) - (bMoveBackward and 1 or 0)
	local nLateralInput	= (bMoveLeft and 1 or 0) - (bMoveRight and 1 or 0)

	return self:NormalizeInputAxes(nForwardInput, nLateralInput)
end

function Controller:NormalizeInputAxes(nForwardInput, nLateralInput)
	local bNormalizeDiagonalInput	= self.NORMALIZE_DIAGONAL_INPUT
	local bHasDiagonalInput			= nForwardInput ~= 0 and nLateralInput ~= 0

	if not bNormalizeDiagonalInput or not bHasDiagonalInput then
		return nForwardInput, nLateralInput
	end

	local nDiagonalScale	= 0.70710678

	return nForwardInput * nDiagonalScale, nLateralInput * nDiagonalScale
end

function Controller:GetInputDirection(oTransform, nForwardInput, nLateralInput)
	local vForward	= oTransform:GetForward()
	local vRight	= oTransform:GetRight()

	return (vForward * nForwardInput) + (vRight * nLateralInput)
end

function Controller:ComputePlanarVelocity(oTransform, nForwardInput, nLateralInput)
	local bHasInput	= nForwardInput ~= 0 or nLateralInput ~= 0

	if not bHasInput then
		return Vector3.new(0, 0, 0)
	end

	local tSpeedProfile			= self:GetSpeedProfile()
	local vForward				= oTransform:GetForward()
	local vRight				= oTransform:GetRight()
	local nForwardSpeed			= nForwardInput >= 0 and tSpeedProfile.nForward or tSpeedProfile.nBackward
	local nLateralSpeed			= nLateralInput >= 0 and tSpeedProfile.nLeft or tSpeedProfile.nRight
	local nMoveSpeedMultiplier	= self.MOVE_SPEED_MULTIPLIER
	local vForwardVelocity		= vForward * (nForwardInput * nForwardSpeed)
	local vLateralVelocity		= vRight * (nLateralInput * nLateralSpeed)

	return (vForwardVelocity + vLateralVelocity) * nMoveSpeedMultiplier
end

function Controller:GetSpeedProfile()
	local bIsGrounded		= self:IsGrounded()
	local bIsCrouching		= self:IsCrouching()
	local bIsRunningRequested	= self:IsRunningRequested()

	if not bIsGrounded then
		return self:GetAirSpeedProfile()
	end

	if bIsCrouching then
		return self:GetCrouchSpeedProfile()
	end

	if bIsRunningRequested then
		return self:GetRunSpeedProfile()
	end

	return self:GetWalkSpeedProfile()
end

function Controller:GetWalkSpeedProfile()
	return
	{
		nForward	= self.WALK_FORWARD_SPEED,
		nBackward	= self.WALK_BACKWARD_SPEED,
		nLeft		= self.WALK_LEFT_SPEED,
		nRight		= self.WALK_RIGHT_SPEED,
	}
end

function Controller:GetRunSpeedProfile()
	return
	{
		nForward	= self.RUN_FORWARD_SPEED,
		nBackward	= self.RUN_BACKWARD_SPEED,
		nLeft		= self.RUN_LEFT_SPEED,
		nRight		= self.RUN_RIGHT_SPEED,
	}
end

function Controller:GetCrouchSpeedProfile()
	return
	{
		nForward	= self.CROUCH_FORWARD_SPEED,
		nBackward	= self.CROUCH_BACKWARD_SPEED,
		nLeft		= self.CROUCH_LEFT_SPEED,
		nRight		= self.CROUCH_RIGHT_SPEED,
	}
end

function Controller:GetAirSpeedProfile()
	return
	{
		nForward	= self.AIR_FORWARD_SPEED,
		nBackward	= self.AIR_BACKWARD_SPEED,
		nLeft		= self.AIR_LEFT_SPEED,
		nRight		= self.AIR_RIGHT_SPEED,
	}
end

function Controller:ApplyPlanarVelocity(oPhysicalCapsule, vPlanarVelocity)
	local vCurrentVelocity	= oPhysicalCapsule:GetLinearVelocity()

	oPhysicalCapsule:SetLinearVelocity(Vector3.new(vPlanarVelocity.x, vCurrentVelocity.y, vPlanarVelocity.z))
end

function Controller:IsGrounded()
	local oJump	= self._private.oJump

	return oJump and oJump:IsGrounded() or false
end

function Controller:HasMovementInput()
	return self._private.bHasMovementInput
end

function Controller:IsRunInputPressed()
	return Inputs.GetKey(self.RUN_KEY) or Inputs.GetKey(self.ALT_RUN_KEY)
end

function Controller:IsRunningRequested()
	local bIsGrounded		= self:IsGrounded()
	local bHasMovementInput	= self:HasMovementInput()
	local bIsCrouching		= self:IsCrouching()
	local bIsRunInputPressed	= self._private.bIsRunInputPressed

	return bIsGrounded and bHasMovementInput and bIsRunInputPressed and not bIsCrouching
end

function Controller:IsCrouching()
	local oCrouch	= self._private.oCrouch

	return oCrouch and oCrouch:IsCrouching() or false
end

function Controller:GetLastInputDirection()
	return self._private.vLastInputDirection
end

return Controller
