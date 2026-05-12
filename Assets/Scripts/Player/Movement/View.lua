---@class View : Behaviour
local View	=
{
	MOUSE_UNLOCK_KEY		= Key.F3,
	MOUSE_RELOCK_BUTTON		= MouseButton.BUTTON_LEFT,
	MOUSE_SENSITIVITY_X		= 0.12,
	MOUSE_SENSITIVITY_Y		= 0.12,
	MODEL_FOLLOW_THRESHOLD_ANGLE	= 95.0,
	MODEL_FOLLOW_MAX_SPEED	= 420.0,
	MODEL_FOLLOW_ACCELERATION	= 2600.0,
	MAX_FREELOOK_YAW_ANGLE	= 170.0,
	MIN_PITCH_ANGLE			= -85.0,
	MAX_PITCH_ANGLE			= 85.0,
	INVERT_Y_AXIS			= false,
	LOCK_MOUSE_ON_START		= true,

	_private	=
	{
		oYawTransform		= nil,
		oCameraTransform	= nil,
		vLastMousePosition	= Vector2.new(0, 0),
		nBodyYawAngle		= 0.0,
		nCameraLocalYawAngle	= 0.0,
		nLastBodyYawDelta	= 0.0,
		nLastBodyYawSpeed	= 0.0,
		nPitchAngle			= 0.0,
		bHasMousePosition	= false,
		bIsMouseLocked		= false,
		sPhysicsActorName	= "Player Physics",
		sCameraActorName	= "Player Camera",
	}
}

function View:OnAwake()
	self						= setmetatable(self, self.owner:GetBehaviour("Class"))

	local sPhysicsActorName			= self._private.sPhysicsActorName
	local sCameraActorName			= self._private.sCameraActorName
	local oPhysicsActor				= self:FindActorByNameRecursive(self.owner, sPhysicsActorName)
	local oYawTransform				= oPhysicsActor and oPhysicsActor:GetTransform() or self.owner:GetTransform()
	local oCameraActor				= self:FindActorByNameRecursive(self.owner, sCameraActorName)
	local oCameraTransform			= oCameraActor and oCameraActor:GetTransform() or nil
	local nCurrentBodyYaw			= oYawTransform:GetLocalRotation():EulerAngles().y
	local nCurrentCameraLocalYawRaw	= oCameraTransform and oCameraTransform:GetLocalRotation():EulerAngles().y or 0.0
	local nCurrentCameraLocalYaw	= self:Clamp(self:NormalizeAngle180(nCurrentCameraLocalYawRaw), -self.MAX_FREELOOK_YAW_ANGLE, self.MAX_FREELOOK_YAW_ANGLE)
	local nCurrentPitch				= oCameraTransform and oCameraTransform:GetLocalRotation():EulerAngles().x or 0.0

	self._private.oYawTransform		= oYawTransform
	self._private.oCameraTransform		= oCameraTransform
	self._private.nBodyYawAngle		= nCurrentBodyYaw
	self._private.nCameraLocalYawAngle	= nCurrentCameraLocalYaw
	self._private.nLastBodyYawDelta		= 0.0
	self._private.nLastBodyYawSpeed		= 0.0
	self._private.nPitchAngle			= nCurrentPitch
end

function View:OnStart()
	if self.LOCK_MOUSE_ON_START then
		self:LockMouse()
	else
		self:ResetMouseReference()
	end
end

function View:OnDisable()
	self:UnlockMouse()
end

function View:OnDestroy()
	self:UnlockMouse()
end

function View:OnUpdate(nDeltaTime)
	self:HandleMouseTrackingState()

	local bIsMouseLocked	= self._private.bIsMouseLocked
	local oYawTransform	= self._private.oYawTransform

	if not bIsMouseLocked or not oYawTransform then return end

	local vCurrentMousePosition	= Inputs.GetMousePos()
	local bHasMousePosition		= self._private.bHasMousePosition

	if not bHasMousePosition then
		self._private.vLastMousePosition	= vCurrentMousePosition
		self._private.bHasMousePosition	= true
		return
	end

	local vLastMousePosition	= self._private.vLastMousePosition
	local vMouseDelta			= vCurrentMousePosition - vLastMousePosition
	local nYawDelta				= -vMouseDelta.x * self.MOUSE_SENSITIVITY_X
	local nPitchBaseDelta		= vMouseDelta.y * self.MOUSE_SENSITIVITY_Y
	local nPitchDelta			= self.INVERT_Y_AXIS and -nPitchBaseDelta or nPitchBaseDelta

	self._private.vLastMousePosition	= vCurrentMousePosition

	local bNeedsBodyFollowUpdate	= self:NeedsBodyFollowUpdate()
	if nYawDelta == 0 and nPitchDelta == 0 and not bNeedsBodyFollowUpdate then
		self._private.nLastBodyYawDelta	= 0.0
		self._private.nLastBodyYawSpeed	= 0.0
		return
	end

	local nBodyYawAngle			= self._private.nBodyYawAngle
	local nCameraLocalYawAngle	= self._private.nCameraLocalYawAngle
	local nPitchAngle			= self:Clamp(self._private.nPitchAngle + nPitchDelta, self.MIN_PITCH_ANGLE, self.MAX_PITCH_ANGLE)
	local nFreelookYawAngle		= nCameraLocalYawAngle + nYawDelta
	local nFreelookYawClamped	= self:Clamp(nFreelookYawAngle, -self.MAX_FREELOOK_YAW_ANGLE, self.MAX_FREELOOK_YAW_ANGLE)
	local nBodyYawDeltaTarget	= self:ComputeBodyYawDelta(nFreelookYawClamped, nDeltaTime)
	local bHasYawFollowTarget	= nBodyYawDeltaTarget ~= 0.0
	local nBodyYawDelta			= bHasYawFollowTarget and self:ComputeSmoothedBodyYawDelta(nBodyYawDeltaTarget, nDeltaTime) or 0.0
	local nBodyYawSpeed			= nDeltaTime > 0 and (nBodyYawDelta / nDeltaTime) or 0.0
	local nUpdatedBodyYawAngle	= self:NormalizeAngle180(nBodyYawAngle + nBodyYawDelta)
	local nUpdatedFreelookYaw	= self:Clamp(nFreelookYawClamped - nBodyYawDelta, -self.MAX_FREELOOK_YAW_ANGLE, self.MAX_FREELOOK_YAW_ANGLE)
	local qYawRotation			= Quaternion.new(Vector3.new(0, nUpdatedBodyYawAngle, 0))
	local oCameraTransform	= self._private.oCameraTransform

	self._private.nBodyYawAngle	= nUpdatedBodyYawAngle
	self._private.nCameraLocalYawAngle	= nUpdatedFreelookYaw
	self._private.nLastBodyYawDelta	= nBodyYawDelta
	self._private.nLastBodyYawSpeed	= nBodyYawSpeed
	self._private.nPitchAngle	= nPitchAngle

	oYawTransform:SetLocalRotation(qYawRotation)

	if oCameraTransform then
		oCameraTransform:SetLocalRotation(Quaternion.new(Vector3.new(nPitchAngle, nUpdatedFreelookYaw, 0)))
	end
end

function View:ComputeBodyYawDelta(nCameraLocalYawAngle, nDeltaTime)
	local nThreshold			= self.MODEL_FOLLOW_THRESHOLD_ANGLE
	local nCameraLocalYawAbs	= nCameraLocalYawAngle < 0 and -nCameraLocalYawAngle or nCameraLocalYawAngle

	if nCameraLocalYawAbs <= nThreshold then
		return 0.0
	end

	local nTargetYaw			= nCameraLocalYawAngle >= 0 and nThreshold or -nThreshold
	local nOverflowYaw			= nCameraLocalYawAngle - nTargetYaw
	local nMaxYawDelta			= self.MODEL_FOLLOW_MAX_SPEED * nDeltaTime
	local nClampedYawDelta		= self:Clamp(nOverflowYaw, -nMaxYawDelta, nMaxYawDelta)

	return nClampedYawDelta
end

function View:ComputeSmoothedBodyYawDelta(nBodyYawDeltaTarget, nDeltaTime)
	if nDeltaTime <= 0 then
		return nBodyYawDeltaTarget
	end

	local nCurrentBodyYawDelta	= self._private.nLastBodyYawDelta
	local nYawDeltaDifference	= nBodyYawDeltaTarget - nCurrentBodyYawDelta
	local nMaxDeltaVariation	= self.MODEL_FOLLOW_ACCELERATION * nDeltaTime
	local nDeltaVariation		= self:Clamp(nYawDeltaDifference, -nMaxDeltaVariation, nMaxDeltaVariation)

	return nCurrentBodyYawDelta + nDeltaVariation
end

function View:NeedsBodyFollowUpdate()
	local nCameraLocalYawAngle	= self._private.nCameraLocalYawAngle
	local nThreshold			= self.MODEL_FOLLOW_THRESHOLD_ANGLE
	local nCameraLocalYawAbs	= nCameraLocalYawAngle < 0 and -nCameraLocalYawAngle or nCameraLocalYawAngle

	return nCameraLocalYawAbs > nThreshold
end

function View:NormalizeAngle180(nAngle)
	local nNormalizedAngle	= nAngle

	while nNormalizedAngle > 180 do
		nNormalizedAngle	= nNormalizedAngle - 360
	end

	while nNormalizedAngle < -180 do
		nNormalizedAngle	= nNormalizedAngle + 360
	end

	return nNormalizedAngle
end

function View:HandleMouseTrackingState()
	local bIsMouseLocked	= self._private.bIsMouseLocked
	local bWantsUnlock		= Inputs.GetKeyDown(self.MOUSE_UNLOCK_KEY)
	local bWantsRelock		= Inputs.GetMouseButtonDown(self.MOUSE_RELOCK_BUTTON)

	if bIsMouseLocked and bWantsUnlock then
		self:UnlockMouse()
		return
	end

	if not bIsMouseLocked and bWantsRelock then
		self:LockMouse()
	end
end

function View:LockMouse()
	Inputs.LockMouse()

	self._private.bIsMouseLocked	= true
	self._private.bHasMousePosition	= false
end

function View:UnlockMouse()
	local bIsMouseLocked	= self._private.bIsMouseLocked

	if not bIsMouseLocked then return end

	Inputs.UnlockMouse()

	self._private.bIsMouseLocked	= false
	self._private.bHasMousePosition	= false
end

function View:ResetMouseReference()
	self._private.vLastMousePosition	= Inputs.GetMousePos()
	self._private.bHasMousePosition	= true
end

function View:GetPitchAngle()
	return self._private.nPitchAngle
end

function View:GetCameraLocalYawAngle()
	return self._private.nCameraLocalYawAngle
end

function View:GetBodyYawDelta()
	return self._private.nLastBodyYawDelta
end

function View:GetBodyYawSpeed()
	return self._private.nLastBodyYawSpeed
end

return View
