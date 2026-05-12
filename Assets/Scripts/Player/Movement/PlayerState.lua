---@class PlayerState : Behaviour
local PlayerState	=
{
	JUMPING_MIN_Y_VELOCITY		= 0.05,

	_private	=
	{
		oPhysicalCapsule		= nil,
		oJump					= nil,
		oCrouch					= nil,
		oController				= nil,
		sCurrentState			= "Idle",
		sPreviousState			= "Idle",
		bDidStateChange			= false,
		tStateNames				=
		{
			sIdle				= "Idle",
			sWalking			= "Walking",
			sRunning			= "Running",
			sCrouchingIdle		= "CrouchingIdle",
			sCrouchingWalking	= "CrouchingWalking",
			sJumping			= "Jumping",
			sFalling			= "Falling",
		},
	}
}

function PlayerState:OnAwake()
	self								= setmetatable(self, self.owner:GetBehaviour("Class"))
	local tStateNames					= self._private.tStateNames
	local sDefaultState					= tStateNames.sIdle

	self._private.oPhysicalCapsule		= self.owner:GetPhysicalCapsule()
	self._private.oJump					= self.owner:GetBehaviour("Jump")
	self._private.oCrouch				= self.owner:GetBehaviour("Crouch")
	self._private.oController			= self.owner:GetBehaviour("Controller")
	self._private.sCurrentState			= sDefaultState
	self._private.sPreviousState		= sDefaultState
	self._private.bDidStateChange		= false
end

function PlayerState:OnFixedUpdate(nFixedDeltaTime)
	self:RefreshState()
end

function PlayerState:RefreshState()
	local sCurrentState		= self._private.sCurrentState
	local sNextState		= self:ComputeState()
	local bDidStateChange	= sCurrentState ~= sNextState

	self._private.bDidStateChange	= bDidStateChange

	if not bDidStateChange then return end

	self._private.sPreviousState	= sCurrentState
	self._private.sCurrentState		= sNextState
end

function PlayerState:ComputeState()
	local tStateNames		= self._private.tStateNames
	local bIsGrounded		= self:IsGrounded()
	local nVerticalVelocity	= self:GetVerticalVelocity()

	if not bIsGrounded then
		return nVerticalVelocity > self.JUMPING_MIN_Y_VELOCITY and tStateNames.sJumping or tStateNames.sFalling
	end

	local bIsCrouching			= self:IsCrouching()
	local bHasMovementInput		= self:HasMovementInput()
	local bIsRunningRequested	= self:IsRunningRequested()

	if bIsCrouching then
		return bHasMovementInput and tStateNames.sCrouchingWalking or tStateNames.sCrouchingIdle
	end

	if bHasMovementInput then
		return bIsRunningRequested and tStateNames.sRunning or tStateNames.sWalking
	end

	return tStateNames.sIdle
end

function PlayerState:IsGrounded()
	local oJump	= self._private.oJump

	return oJump and oJump:IsGrounded() or false
end

function PlayerState:GetVerticalVelocity()
	local oPhysicalCapsule	= self._private.oPhysicalCapsule
	local nVerticalVelocity	= oPhysicalCapsule and oPhysicalCapsule:GetLinearVelocity().y or 0.0

	return nVerticalVelocity
end

function PlayerState:IsCrouching()
	local oCrouch	= self._private.oCrouch

	return oCrouch and oCrouch:IsCrouching() or false
end

function PlayerState:HasMovementInput()
	local oController	= self._private.oController

	return oController and oController:HasMovementInput() or false
end

function PlayerState:IsRunningRequested()
	local oController	= self._private.oController

	return oController and oController:IsRunningRequested() or false
end

function PlayerState:GetCurrentState()
	return self._private.sCurrentState
end

function PlayerState:GetPreviousState()
	return self._private.sPreviousState
end

function PlayerState:DidStateChange()
	return self._private.bDidStateChange
end

function PlayerState:IsState(sState)
	return self._private.sCurrentState == sState
end

return PlayerState
