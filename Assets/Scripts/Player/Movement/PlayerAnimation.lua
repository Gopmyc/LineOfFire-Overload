---@class PlayerAnimation : Behaviour
local PlayerAnimation	=
{
	MIN_DIRECTION_MAGNITUDE		= 0.001,
	HEAD_LOOK_PITCH_WEIGHT		= 0.7,
	HEAD_LOOK_YAW_WEIGHT		= 0.4,
	HEAD_LOOK_MAX_UP_ANGLE		= 45.0,
	HEAD_LOOK_MAX_DOWN_ANGLE	= 35.0,
	HEAD_LOOK_MAX_YAW_ANGLE		= 55.0,
	HEAD_LOOK_SMOOTH_SPEED		= 14.0,

	_private	=
	{
		sModelActorName			= "Player Model",
		sCameraActorName		= "Player Camera",
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
		tDirectionNames			=
		{
			sNone				= "None",
			sForward			= "Forward",
			sBackward			= "Backward",
			sLeft				= "Left",
			sRight				= "Right",
		},
		tOneShotTypes			=
		{
			sJump				= "Jump",
			sLand				= "Land",
		},
		tAnimationNames			=
		{
			sIdle				= "ACT_IDLE",
			sFrontWalk			= "ACT_FRONT_WALK",
			sBackWalk			= "ACT_BACK_WALK",
			sLeftStrafe			= "ACT_LEFT_STRAFE",
			sRightStrafe		= "ACT_RIGHT_STRAFE",
			sFrontRun			= "ACT_FRONT_RUN",
			sBackRun			= "ACT_BACK_RUN",
			sFall				= "ACT_FALL",
			sLand				= "ACT_LAND",
			sIdleCrouch			= "ACT_IDLE_CROUCH",
			sFrontWalkCrouch	= "ACT_FRONT_WALK_CROUCH",
			sLeftStrafeCrouch	= "ACT_LEFT_STRAFE_CROUCH",
			sRightStrafeCrouch	= "ACT_RIGHT_STRAFE_CROUCH",
			sJump				= "ACT_JUMP",
		},
		tHeadBoneNames			=
		{
			"mixamorig:Head",
			"Head",
			"mixamorig:Neck",
			"Neck",
		},
		oPlayerState			= nil,
		oController				= nil,
		oTransform				= nil,
		oPhysicalCapsule		= nil,
		oSkinnedMeshRenderer	= nil,
		oCameraTransform		= nil,
		nHeadBoneIndex			= nil,
		qHeadLookOffset			= nil,
		sObservedState			= nil,
		sActiveOneShotType		= nil,
		sCurrentLoopAnimation	= nil,
	}
}

function PlayerAnimation:OnAwake()
	self								= setmetatable(self, self.owner:GetBehaviour("Class"))

	local oSkinnedMeshRenderer			= self:ResolveSkinnedMeshRenderer()
	local oPlayerState					= self.owner:GetBehaviour("PlayerState")
	local oController					= self.owner:GetBehaviour("Controller")
	local oTransform					= self.owner:GetTransform()
	local oPhysicalCapsule				= self.owner:GetPhysicalCapsule()
	local oCameraTransform				= self:ResolveCameraTransform()
	local nHeadBoneIndex				= self:ResolveHeadBoneIndex(oSkinnedMeshRenderer)
	local tStateNames					= self._private.tStateNames
	local sCurrentState					= oPlayerState and oPlayerState:GetCurrentState() or tStateNames.sIdle

	self._private.oSkinnedMeshRenderer	= oSkinnedMeshRenderer
	self._private.oPlayerState			= oPlayerState
	self._private.oController			= oController
	self._private.oTransform			= oTransform
	self._private.oPhysicalCapsule		= oPhysicalCapsule
	self._private.oCameraTransform		= oCameraTransform
	self._private.nHeadBoneIndex		= nHeadBoneIndex
	self._private.qHeadLookOffset		= Quaternion.new(Vector3.new(0, 0, 0))
	self._private.sObservedState		= sCurrentState
	self._private.sActiveOneShotType	= nil
	self._private.sCurrentLoopAnimation	= nil

	self:ApplyLoopAnimationFromState(sCurrentState, true)
end

function PlayerAnimation:OnUpdate(nDeltaTime)
	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer
	if not oSkinnedMeshRenderer then return end

	local tStateNames		= self._private.tStateNames
	local tOneShotTypes		= self._private.tOneShotTypes
	local tAnimationNames	= self._private.tAnimationNames
	local sCurrentState		= self:GetCurrentStateName()
	local sPreviousState	= self._private.sObservedState
	local bDidStateChange	= sCurrentState ~= sPreviousState

	if bDidStateChange then
		self._private.sObservedState	= sCurrentState
	end

	self:UpdateOneShotPlaybackState(sCurrentState)
	local bShouldApplyLoopAnimation	= true

	if bDidStateChange and self:ShouldPlayLandOneShot(sPreviousState, sCurrentState) then
		local bDidPlayLand	= self:PlayOneShotAnimation(tAnimationNames.sLand, tOneShotTypes.sLand)

		if bDidPlayLand then
			bShouldApplyLoopAnimation	= false
		end
	end

	if bShouldApplyLoopAnimation and bDidStateChange and sCurrentState == tStateNames.sJumping then
		local bDidPlayJump	= self:PlayOneShotAnimation(tAnimationNames.sJump, tOneShotTypes.sJump)

		if bDidPlayJump then
			bShouldApplyLoopAnimation	= false
		end
	end

	if bShouldApplyLoopAnimation and self:IsOneShotPlaying() then
		bShouldApplyLoopAnimation	= false
	end

	if bShouldApplyLoopAnimation then
		self:ApplyLoopAnimationFromState(sCurrentState, false)
	end

	self:ApplyHeadLookFromCamera(nDeltaTime)
end

function PlayerAnimation:ResolveSkinnedMeshRenderer()
	local sModelActorName		= self._private.sModelActorName
	local oModelActor			= self:FindActorByNameRecursive(self.owner, sModelActorName)
	local oSkinnedMeshRenderer	= oModelActor and oModelActor:GetSkinnedMeshRenderer() or nil

	return oSkinnedMeshRenderer or self:FindSkinnedMeshRendererRecursive(self.owner)
end

function PlayerAnimation:ResolveCameraTransform()
	local sCameraActorName	= self._private.sCameraActorName
	local oCameraActor		= self:FindActorByNameRecursive(self.owner, sCameraActorName)

	return oCameraActor and oCameraActor:GetTransform() or nil
end

function PlayerAnimation:ResolveHeadBoneIndex(oSkinnedMeshRenderer)
	if not oSkinnedMeshRenderer then return nil end

	local tHeadBoneNames	= self._private.tHeadBoneNames

	for _, sBoneName in ipairs(tHeadBoneNames) do
		local nBoneIndex	= oSkinnedMeshRenderer:GetBoneIndex(sBoneName)

		if nBoneIndex then
			return nBoneIndex
		end
	end

	local nHeadBoneIndex	= self:FindBoneIndexByNamePattern(oSkinnedMeshRenderer, "head")

	if nHeadBoneIndex then
		return nHeadBoneIndex
	end

	return self:FindBoneIndexByNamePattern(oSkinnedMeshRenderer, "neck")
end

function PlayerAnimation:FindBoneIndexByNamePattern(oSkinnedMeshRenderer, sPattern)
	local nBoneCount	= oSkinnedMeshRenderer:GetBoneCount()

	for nBoneIndex = 0, nBoneCount - 1 do
		local sBoneName	= oSkinnedMeshRenderer:GetBoneName(nBoneIndex)

		if sBoneName then
			local sLowerBoneName	= string.lower(sBoneName)

			if string.find(sLowerBoneName, sPattern, 1, true) then
				return nBoneIndex
			end
		end
	end

	return nil
end

function PlayerAnimation:FindSkinnedMeshRendererRecursive(oActor)
	if not oActor then return nil end

	local oSkinnedMeshRenderer	= oActor:GetSkinnedMeshRenderer()
	if oSkinnedMeshRenderer then
		return oSkinnedMeshRenderer
	end

	local tChildren	= oActor:GetChildren()

	for _, oChildActor in ipairs(tChildren) do
		local oFoundRenderer	= self:FindSkinnedMeshRendererRecursive(oChildActor)

		if oFoundRenderer then
			return oFoundRenderer
		end
	end

	return nil
end

function PlayerAnimation:UpdateOneShotPlaybackState(sCurrentState)
	local sActiveOneShotType	= self._private.sActiveOneShotType

	if not sActiveOneShotType then return end

	if self:ShouldInterruptOneShot(sActiveOneShotType, sCurrentState) then
		self._private.sActiveOneShotType	= nil
		return
	end

	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer

	if not oSkinnedMeshRenderer:IsPlaying() then
		self._private.sActiveOneShotType	= nil
	end
end

function PlayerAnimation:ShouldInterruptOneShot(sActiveOneShotType, sCurrentState)
	local tStateNames	= self._private.tStateNames
	local tOneShotTypes	= self._private.tOneShotTypes

	if sActiveOneShotType == tOneShotTypes.sJump and sCurrentState == tStateNames.sFalling then
		return true
	end

	if sActiveOneShotType == tOneShotTypes.sLand and self:IsAirState(sCurrentState) then
		return true
	end

	return false
end

function PlayerAnimation:ShouldPlayLandOneShot(sPreviousState, sCurrentState)
	local bWasAirState		= self:IsAirState(sPreviousState)
	local bIsNowGrounded	= not self:IsAirState(sCurrentState)

	return bWasAirState and bIsNowGrounded
end

function PlayerAnimation:IsAirState(sState)
	local tStateNames	= self._private.tStateNames

	return sState == tStateNames.sJumping or sState == tStateNames.sFalling
end

function PlayerAnimation:IsOneShotPlaying()
	return self._private.sActiveOneShotType ~= nil
end

function PlayerAnimation:PlayOneShotAnimation(sAnimationName, sOneShotType)
	local bDidPlayAnimation	= self:PlayAnimationClip(sAnimationName, false, true)

	if not bDidPlayAnimation then
		return false
	end

	self._private.sActiveOneShotType	= sOneShotType
	self._private.sCurrentLoopAnimation	= nil

	return true
end

function PlayerAnimation:ApplyLoopAnimationFromState(sState, bForceRestart)
	local sLoopAnimationName	= self:ResolveLoopAnimationName(sState)
	local bDidPlayAnimation		= self:PlayAnimationClip(sLoopAnimationName, true, bForceRestart)

	if bDidPlayAnimation then
		self._private.sCurrentLoopAnimation	= sLoopAnimationName
	end
end

function PlayerAnimation:ResolveLoopAnimationName(sState)
	local tStateNames		= self._private.tStateNames
	local tAnimationNames	= self._private.tAnimationNames

	if sState == tStateNames.sCrouchingIdle then
		return tAnimationNames.sIdleCrouch
	end

	if sState == tStateNames.sCrouchingWalking then
		return self:ResolveDirectionalCrouchAnimation()
	end

	if sState == tStateNames.sRunning then
		return self:ResolveDirectionalRunAnimation()
	end

	if sState == tStateNames.sWalking then
		return self:ResolveDirectionalWalkAnimation()
	end

	if self:IsAirState(sState) then
		return tAnimationNames.sFall
	end

	return tAnimationNames.sIdle
end

function PlayerAnimation:ResolveDirectionalWalkAnimation()
	local tDirectionNames	= self._private.tDirectionNames
	local tAnimationNames	= self._private.tAnimationNames
	local sDirection		= self:GetMovementDirection()

	if sDirection == tDirectionNames.sBackward then
		return tAnimationNames.sBackWalk
	end

	if sDirection == tDirectionNames.sLeft then
		return tAnimationNames.sLeftStrafe
	end

	if sDirection == tDirectionNames.sRight then
		return tAnimationNames.sRightStrafe
	end

	return tAnimationNames.sFrontWalk
end

function PlayerAnimation:ResolveDirectionalRunAnimation()
	local tDirectionNames	= self._private.tDirectionNames
	local tAnimationNames	= self._private.tAnimationNames
	local sDirection		= self:GetMovementDirection()

	if sDirection == tDirectionNames.sBackward then
		return tAnimationNames.sBackRun
	end

	if sDirection == tDirectionNames.sLeft then
		return tAnimationNames.sLeftStrafe
	end

	if sDirection == tDirectionNames.sRight then
		return tAnimationNames.sRightStrafe
	end

	return tAnimationNames.sFrontRun
end

function PlayerAnimation:ResolveDirectionalCrouchAnimation()
	local tDirectionNames	= self._private.tDirectionNames
	local tAnimationNames	= self._private.tAnimationNames
	local sDirection		= self:GetMovementDirection()

	if sDirection == tDirectionNames.sLeft then
		return tAnimationNames.sLeftStrafeCrouch
	end

	if sDirection == tDirectionNames.sRight then
		return tAnimationNames.sRightStrafeCrouch
	end

	return tAnimationNames.sFrontWalkCrouch
end

function PlayerAnimation:GetMovementDirection()
	local tDirectionNames	= self._private.tDirectionNames
	local vInputDirection	= self:GetMovementDirectionSource()

	if vInputDirection:Length() <= self.MIN_DIRECTION_MAGNITUDE then
		return tDirectionNames.sNone
	end

	local oTransform	= self._private.oTransform
	local vForward		= oTransform:GetForward()
	local vRight		= oTransform:GetRight()
	local nForwardDot	= vInputDirection:Dot(vForward)
	local nRightDot		= vInputDirection:Dot(vRight)
	local nForwardAbs	= nForwardDot < 0 and -nForwardDot or nForwardDot
	local nRightAbs		= nRightDot < 0 and -nRightDot or nRightDot

	if nForwardAbs >= nRightAbs then
		return nForwardDot >= 0 and tDirectionNames.sForward or tDirectionNames.sBackward
	end

	return nRightDot >= 0 and tDirectionNames.sLeft or tDirectionNames.sRight
end

function PlayerAnimation:GetMovementDirectionSource()
	local oController		= self._private.oController
	local vInputDirection	= oController and oController:GetLastInputDirection() or Vector3.new(0, 0, 0)

	if vInputDirection:Length() > self.MIN_DIRECTION_MAGNITUDE then
		return vInputDirection
	end

	local oPhysicalCapsule	= self._private.oPhysicalCapsule
	local vVelocity			= oPhysicalCapsule and oPhysicalCapsule:GetLinearVelocity() or Vector3.new(0, 0, 0)

	return Vector3.new(vVelocity.x, 0, vVelocity.z)
end

function PlayerAnimation:PlayAnimationClip(sAnimationName, bLooping, bRestart)
	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer
	if not oSkinnedMeshRenderer or not sAnimationName then return false end

	local sActiveAnimationName	= oSkinnedMeshRenderer:GetActiveAnimationName()
	local bIsSameAnimation		= sActiveAnimationName == sAnimationName

	if bIsSameAnimation and not bRestart then
		oSkinnedMeshRenderer:SetLooping(bLooping)

		if not oSkinnedMeshRenderer:IsPlaying() then
			oSkinnedMeshRenderer:Play()
		end

		return true
	end

	local bDidSetAnimation	= self:TrySetAnimation(oSkinnedMeshRenderer, sAnimationName)

	if not bDidSetAnimation then
		return false
	end

	oSkinnedMeshRenderer:SetLooping(bLooping)
	oSkinnedMeshRenderer:SetTime(0.0)
	oSkinnedMeshRenderer:Play()

	return true
end

function PlayerAnimation:TrySetAnimation(oSkinnedMeshRenderer, sAnimationName)
	local bDidSetAnimation	= oSkinnedMeshRenderer:SetAnimation(sAnimationName)
	local sArmatureName		= "Armature|" .. sAnimationName

	return bDidSetAnimation or oSkinnedMeshRenderer:SetAnimation(sArmatureName)
end

function PlayerAnimation:GetCurrentStateName()
	local oPlayerState	= self._private.oPlayerState
	local tStateNames	= self._private.tStateNames
	local sStateName	= oPlayerState and oPlayerState:GetCurrentState() or tStateNames.sIdle

	return sStateName or tStateNames.sIdle
end

function PlayerAnimation:ApplyHeadLookFromCamera(nDeltaTime)
	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer
	local oCameraTransform		= self._private.oCameraTransform
	local nHeadBoneIndex		= self._private.nHeadBoneIndex

	if not oSkinnedMeshRenderer or not oCameraTransform or not nHeadBoneIndex then return end

	local qCurrentHeadRotation	= oSkinnedMeshRenderer:GetBoneLocalRotation(nHeadBoneIndex)
	if not qCurrentHeadRotation then return end

	local nCameraPitch, nCameraYaw	= self:GetCameraLocalAngles(oCameraTransform)
	local nHeadPitchAngle		= self:Clamp(nCameraPitch * self.HEAD_LOOK_PITCH_WEIGHT, -self.HEAD_LOOK_MAX_UP_ANGLE, self.HEAD_LOOK_MAX_DOWN_ANGLE)
	local nHeadYawAngle			= self:Clamp(nCameraYaw * self.HEAD_LOOK_YAW_WEIGHT, -self.HEAD_LOOK_MAX_YAW_ANGLE, self.HEAD_LOOK_MAX_YAW_ANGLE)
	local qCurrentHeadLookOffset	= self._private.qHeadLookOffset
	local qTargetHeadLookOffset	= Quaternion.new(Vector3.new(nHeadPitchAngle, nHeadYawAngle, 0))
	local nInterpolationAlpha	= self:Clamp(nDeltaTime * self.HEAD_LOOK_SMOOTH_SPEED, 0.0, 1.0)
	local qSmoothedHeadLookOffset	= Quaternion.Slerp(qCurrentHeadLookOffset, qTargetHeadLookOffset, nInterpolationAlpha)
	local qBaseHeadRotation		= qCurrentHeadRotation * qCurrentHeadLookOffset:Inverse()
	local qSmoothedHeadRotation	= qBaseHeadRotation * qSmoothedHeadLookOffset

	oSkinnedMeshRenderer:SetBoneLocalRotation(nHeadBoneIndex, qSmoothedHeadRotation)
	self._private.qHeadLookOffset	= qSmoothedHeadLookOffset
end

function PlayerAnimation:GetCameraLocalAngles(oCameraTransform)
	local vCameraEulerAngles	= oCameraTransform:GetLocalRotation():EulerAngles()
	local nPitchAngle			= self:NormalizeAngle180(vCameraEulerAngles.x)
	local nYawAngle				= self:NormalizeAngle180(vCameraEulerAngles.y)

	return nPitchAngle, nYawAngle
end

function PlayerAnimation:NormalizeAngle180(nAngle)
	local nNormalizedAngle	= nAngle

	while nNormalizedAngle > 180 do
		nNormalizedAngle	= nNormalizedAngle - 360
	end

	while nNormalizedAngle < -180 do
		nNormalizedAngle	= nNormalizedAngle + 360
	end

	return nNormalizedAngle
end

return PlayerAnimation
