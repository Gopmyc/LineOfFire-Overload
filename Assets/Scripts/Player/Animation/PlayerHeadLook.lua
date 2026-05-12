---@class PlayerHeadLook : Behaviour
local PlayerHeadLook	=
{
	LOOK_PITCH_WEIGHT			= 0.7,
	LOOK_YAW_WEIGHT				= 0.45,
	LOOK_MAX_UP_ANGLE			= 45.0,
	LOOK_MAX_DOWN_ANGLE			= 35.0,
	LOOK_MAX_YAW_ANGLE			= 55.0,
	LOOK_SMOOTH_SPEED			= 14.0,
	LOOK_YAW_DEAD_ZONE			= 0.25,

	_private	=
	{
		sModelActorName			= "Player Model",
		sCameraActorName		= "Player Camera",
		sHeadBoneName			= "mixamorig:Head",
		oSkinnedMeshRenderer	= nil,
		oCameraTransform		= nil,
		oView					= nil,
		nHeadBoneIndex			= nil,
		qCurrentLookOffset		= nil,
	}
}

function PlayerHeadLook:OnAwake()
	self								= setmetatable(self, self.owner:GetBehaviour("Class"))

	local oSkinnedMeshRenderer			= self:ResolveSkinnedMeshRenderer()
	local oCameraTransform				= self:ResolveCameraTransform()
	local oView						= self:ResolveViewBehaviour()
	local nHeadBoneIndex				= self:ResolveHeadBoneIndex(oSkinnedMeshRenderer)

	self._private.oSkinnedMeshRenderer	= oSkinnedMeshRenderer
	self._private.oCameraTransform		= oCameraTransform
	self._private.oView				= oView
	self._private.nHeadBoneIndex		= nHeadBoneIndex
	self._private.qCurrentLookOffset	= Quaternion.new(Vector3.new(0, 0, 0))
end

function PlayerHeadLook:OnLateUpdate(nDeltaTime)
	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer
	local oCameraTransform		= self._private.oCameraTransform
	local nHeadBoneIndex		= self._private.nHeadBoneIndex
	local qCurrentLookOffset	= self._private.qCurrentLookOffset

	if not oSkinnedMeshRenderer or not oCameraTransform or not nHeadBoneIndex or not qCurrentLookOffset then return end

	local qAnimationHeadRotation	= oSkinnedMeshRenderer:GetBoneLocalRotation(nHeadBoneIndex)
	if not qAnimationHeadRotation then return end

	local nCameraPitchAngle, nCameraYawAngle	= self:GetCameraLookAngles(oCameraTransform)
	local nStableYawAngle					= nCameraYawAngle < 0 and -nCameraYawAngle or nCameraYawAngle
	local nFilteredYawAngle				= nStableYawAngle <= self.LOOK_YAW_DEAD_ZONE and 0.0 or nCameraYawAngle
	local nTargetHeadPitchAngle				= self:Clamp(nCameraPitchAngle * self.LOOK_PITCH_WEIGHT, -self.LOOK_MAX_UP_ANGLE, self.LOOK_MAX_DOWN_ANGLE)
	local nTargetHeadYawAngle				= self:Clamp(nFilteredYawAngle * self.LOOK_YAW_WEIGHT, -self.LOOK_MAX_YAW_ANGLE, self.LOOK_MAX_YAW_ANGLE)
	local qTargetLookOffset					= Quaternion.new(Vector3.new(nTargetHeadPitchAngle, nTargetHeadYawAngle, 0))
	local nInterpolationAlpha				= self:Clamp(nDeltaTime * self.LOOK_SMOOTH_SPEED, 0.0, 1.0)
	local qSmoothedLookOffset				= Quaternion.Slerp(qCurrentLookOffset, qTargetLookOffset, nInterpolationAlpha)
	local qTargetHeadRotation				= qAnimationHeadRotation * qSmoothedLookOffset

	oSkinnedMeshRenderer:SetBoneLocalRotation(nHeadBoneIndex, qTargetHeadRotation)
	self._private.qCurrentLookOffset	= qSmoothedLookOffset
end

function PlayerHeadLook:ResolveSkinnedMeshRenderer()
	local sModelActorName		= self._private.sModelActorName
	local oModelActor			= self:FindActorByNameRecursive(self.owner, sModelActorName)
	local oSkinnedMeshRenderer	= oModelActor and oModelActor:GetSkinnedMeshRenderer() or nil

	return oSkinnedMeshRenderer or self:FindSkinnedMeshRendererRecursive(self.owner)
end

function PlayerHeadLook:FindSkinnedMeshRendererRecursive(oActor)
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

function PlayerHeadLook:ResolveCameraTransform()
	local sCameraActorName	= self._private.sCameraActorName
	local oCameraActor		= self:FindActorByNameRecursive(self.owner, sCameraActorName)

	return oCameraActor and oCameraActor:GetTransform() or nil
end

function PlayerHeadLook:ResolveHeadBoneIndex(oSkinnedMeshRenderer)
	local sHeadBoneName	= self._private.sHeadBoneName

	return oSkinnedMeshRenderer and oSkinnedMeshRenderer:GetBoneIndex(sHeadBoneName) or nil
end

function PlayerHeadLook:ResolveViewBehaviour()
	local oCurrentActor	= self.owner

	while oCurrentActor do
		local oView	= oCurrentActor:GetBehaviour("View")

		if oView then
			return oView
		end

		oCurrentActor	= oCurrentActor:GetParent()
	end

	return nil
end

function PlayerHeadLook:GetCameraLookAngles(oCameraTransform)
	local nPitchAngle	= self:GetCameraPitchAngle(oCameraTransform)
	local nYawAngle		= self:GetCameraYawAngle(oCameraTransform)

	return nPitchAngle, nYawAngle
end

function PlayerHeadLook:GetCameraPitchAngle(oCameraTransform)
	local oView	= self._private.oView

	if oView and oView.GetPitchAngle then
		return oView:GetPitchAngle()
	end

	local vCameraEulerAngles	= oCameraTransform:GetLocalRotation():EulerAngles()
	local nPitchAngle			= self:NormalizeAngle180(vCameraEulerAngles.x)

	return nPitchAngle
end

function PlayerHeadLook:GetCameraYawAngle(oCameraTransform)
	local oView	= self._private.oView

	if oView and oView.GetCameraLocalYawAngle then
		return oView:GetCameraLocalYawAngle()
	end

	local vCameraEulerAngles	= oCameraTransform:GetLocalRotation():EulerAngles()
	local nYawAngle			= self:NormalizeAngle180(vCameraEulerAngles.y)

	return nYawAngle
end

function PlayerHeadLook:NormalizeAngle180(nAngle)
	local nNormalizedAngle	= nAngle

	while nNormalizedAngle > 180 do
		nNormalizedAngle	= nNormalizedAngle - 360
	end

	while nNormalizedAngle < -180 do
		nNormalizedAngle	= nNormalizedAngle + 360
	end

	return nNormalizedAngle
end

return PlayerHeadLook
