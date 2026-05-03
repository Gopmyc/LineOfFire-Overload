---@class View : Behaviour
local View	=
{
	PHYSICS_ACTOR_NAME		= "Player Physics",
	CAMERA_ACTOR_NAME		= "Player Camera",
	MOUSE_SENSITIVITY_X		= 0.12,
	MOUSE_SENSITIVITY_Y		= 0.12,
	MIN_PITCH_ANGLE			= -85.0,
	MAX_PITCH_ANGLE			= 85.0,
	INVERT_Y_AXIS			= false,
	LOCK_MOUSE_ON_START		= true,

	_private	=
	{
		oYawTransform		= nil,
		oCameraTransform	= nil,
		vLastMousePosition	= Vector2.new(0, 0),
		nYawAngle			= 0.0,
		nPitchAngle			= 0.0,
		bHasMousePosition	= false,
		bIsMouseLocked		= false,
	}
}

function View:OnAwake()
	self						= setmetatable(self, self.owner:GetBehaviour("Class"))

	local oPhysicsActor				= self:FindActorByNameRecursive(self.owner, self.PHYSICS_ACTOR_NAME)
	local oYawTransform				= oPhysicsActor and oPhysicsActor:GetTransform() or self.owner:GetTransform()
	local oCameraActor				= self:FindActorByNameRecursive(self.owner, self.CAMERA_ACTOR_NAME)
	local oCameraTransform			= oCameraActor and oCameraActor:GetTransform() or nil
	local nCurrentYaw				= oYawTransform:GetLocalRotation():EulerAngles().y
	local nCurrentPitch				= oCameraTransform and oCameraTransform:GetLocalRotation():EulerAngles().x or 0.0

	self._private.oYawTransform		= oYawTransform
	self._private.oCameraTransform		= oCameraTransform
	self._private.nYawAngle				= nCurrentYaw
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
	local oYawTransform	= self._private.oYawTransform

	if not oYawTransform then return end

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

	if nYawDelta == 0 and nPitchDelta == 0 then return end

	local nYawAngle			= self._private.nYawAngle + nYawDelta
	local nPitchAngle		= self:Clamp(self._private.nPitchAngle + nPitchDelta, self.MIN_PITCH_ANGLE, self.MAX_PITCH_ANGLE)
	local qYawRotation		= Quaternion.new(Vector3.new(0, nYawAngle, 0))
	local oCameraTransform	= self._private.oCameraTransform

	self._private.nYawAngle	= nYawAngle
	self._private.nPitchAngle	= nPitchAngle

	oYawTransform:SetLocalRotation(qYawRotation)

	if oCameraTransform then
		oCameraTransform:SetLocalRotation(Quaternion.new(Vector3.new(nPitchAngle, 0, 0)))
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

return View
