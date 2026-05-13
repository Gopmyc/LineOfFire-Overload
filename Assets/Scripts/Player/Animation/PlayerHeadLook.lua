---@class PlayerHeadLook : Behaviour
local PlayerHeadLook	=
{
	LOOK_YAW_DEAD_ZONE				= 0.25,
	UPPER_BODY_SMOOTH_SPEED			= 14.0,
	TURN_SWAY_SMOOTH_SPEED			= 12.0,
	HEAD_NECK_MAX_YAW_ANGLE			= 55.0,
	HEAD_NECK_MAX_UP_ANGLE			= 30.0,
	HEAD_NECK_MAX_DOWN_ANGLE		= 45.0,
	TORSO_MAX_YAW_ANGLE				= 35.0,
	TORSO_MAX_UP_ANGLE				= 12.0,
	TORSO_MAX_DOWN_ANGLE			= 18.0,
	HEAD_YAW_RATIO					= 0.75,
	NECK_YAW_RATIO					= 0.25,
	HEAD_PITCH_RATIO				= 0.80,
	NECK_PITCH_RATIO				= 0.20,
	SPINE2_YAW_RATIO				= 0.50,
	SPINE1_YAW_RATIO				= 0.35,
	SPINE_YAW_RATIO					= 0.15,
	SPINE2_PITCH_RATIO				= 0.50,
	SPINE1_PITCH_RATIO				= 0.35,
	SPINE_PITCH_RATIO				= 0.15,
	TURN_IN_PLACE_SPEED_THRESHOLD	= 24.0,
	TURN_IN_PLACE_FULL_SPEED		= 260.0,
	HIPS_YAW_MAX_ANGLE				= 6.5,
	HIPS_ROLL_MAX_ANGLE				= 3.5,
	HIPS_PITCH_MAX_ANGLE			= 2.8,
	UPLEG_YAW_MAX_ANGLE				= 4.5,
	UPLEG_ROLL_MAX_ANGLE			= 5.5,
	UPLEG_PITCH_MAX_ANGLE			= 4.5,
	LOWER_LEG_PITCH_MAX_ANGLE		= 6.5,
	FOOT_YAW_MAX_ANGLE				= 7.5,
	FOOT_ROLL_MAX_ANGLE				= 4.0,
	FOOT_PITCH_MAX_ANGLE			= 3.5,
	TURN_STEP_BASE_CYCLE_SPEED		= 5.5,
	TURN_STEP_CYCLE_SPEED_FACTOR	= 4.5,
	TURN_STEP_WEIGHT				= 0.45,
	TACTICAL_LEG_ASYMMETRY			= 0.22,
	TACTICAL_FOOT_OPENING			= 0.30,
	TACTICAL_KNEE_FLEX_BIAS			= 0.18,
	CAMERA_HEAD_OFFSET_X			= 0.0,
	CAMERA_HEAD_OFFSET_Y			= 0.45,
	CAMERA_HEAD_OFFSET_Z			= 0.35,

	_private	=
	{
		sModelActorName			= "Player Model",
		sCameraActorName		= "Player Camera",
		oSkinnedMeshRenderer	= nil,
		oCameraTransform		= nil,
		oView					= nil,
		oController				= nil,
		tBoneIndices			= {},
		tBoneAngles				= {},
		nTurnStepPhase			= 0.0,
	}
}

local tBoneNameByKey	= {
	sHead = "mixamorig:Head", sNeck = "mixamorig:Neck", sSpine2 = "mixamorig:Spine2", sSpine1 = "mixamorig:Spine1", sSpine = "mixamorig:Spine", sHips = "mixamorig:Hips",
	sLeftUpLeg = "mixamorig:LeftUpLeg", sRightUpLeg = "mixamorig:RightUpLeg", sLeftLeg = "mixamorig:LeftLeg", sRightLeg = "mixamorig:RightLeg", sLeftFoot = "mixamorig:LeftFoot", sRightFoot = "mixamorig:RightFoot",
}

local tBoneOffsetConfigs	=
{
	{ sBoneKey = "sHead",			sPitchKey = "nHeadPitch",		sYawKey = "nHeadYaw" },
	{ sBoneKey = "sNeck",			sPitchKey = "nNeckPitch",		sYawKey = "nNeckYaw" },
	{ sBoneKey = "sSpine2",			sPitchKey = "nSpine2Pitch",		sYawKey = "nSpine2Yaw" },
	{ sBoneKey = "sSpine1",			sPitchKey = "nSpine1Pitch",		sYawKey = "nSpine1Yaw" },
	{ sBoneKey = "sSpine",			sPitchKey = "nSpinePitch",		sYawKey = "nSpineYaw" },
	{ sBoneKey = "sHips",			sPitchKey = "nHipsPitch",		sYawKey = "nHipsYaw",		sRollKey = "nHipsRoll" },
	{ sBoneKey = "sLeftUpLeg",		sPitchKey = "nLeftUpLegPitch",	sYawKey = "nLeftUpLegYaw",	sRollKey = "nLeftUpLegRoll" },
	{ sBoneKey = "sRightUpLeg",		sPitchKey = "nRightUpLegPitch",	sYawKey = "nRightUpLegYaw",	sRollKey = "nRightUpLegRoll" },
	{ sBoneKey = "sLeftLeg",		sPitchKey = "nLeftLegPitch" },
	{ sBoneKey = "sRightLeg",		sPitchKey = "nRightLegPitch" },
	{ sBoneKey = "sLeftFoot",		sPitchKey = "nLeftFootPitch",	sYawKey = "nLeftFootYaw",	sRollKey = "nLeftFootRoll" },
	{ sBoneKey = "sRightFoot",		sPitchKey = "nRightFootPitch",	sYawKey = "nRightFootYaw",	sRollKey = "nRightFootRoll" },
}

local tCameraAttachmentBoneChain	= { "sHips", "sSpine", "sSpine1", "sSpine2", "sNeck", "sHead" }

function PlayerHeadLook:OnAwake()
	self								= setmetatable(self, self.owner:GetBehaviour("Class"))
	local oSkinnedMeshRenderer			= self:ResolveSkinnedMeshRenderer()
	local oCameraTransform				= self:ResolveCameraTransform()

	self._private.oSkinnedMeshRenderer	= oSkinnedMeshRenderer
	self._private.oCameraTransform		= oCameraTransform
	self._private.oView					= self:FindBehaviourInParents(self.owner, "View")
	self._private.oController			= self.owner:GetBehaviour("Controller")
	self._private.tBoneIndices			= self:ResolveBoneIndices(oSkinnedMeshRenderer)
	self._private.tBoneAngles			= {}
	self._private.nTurnStepPhase		= 0.0
end

function PlayerHeadLook:OnLateUpdate(nDeltaTime)
	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer
	local oCameraTransform		= self._private.oCameraTransform
	if not oSkinnedMeshRenderer or not oCameraTransform then return end
	local nCameraPitchAngle, nCameraYawAngle	= self:GetCameraLookAngles(oCameraTransform)
	local nCameraYawAbs						= nCameraYawAngle < 0 and -nCameraYawAngle or nCameraYawAngle
	local nFilteredYawAngle					= nCameraYawAbs <= self.LOOK_YAW_DEAD_ZONE and 0.0 or nCameraYawAngle

	self:UpdateUpperBodyAngles(nDeltaTime, nCameraPitchAngle, nFilteredYawAngle)
	self:UpdateTurnInPlaceSway(nDeltaTime)
	self:ApplyProceduralOffsets(oSkinnedMeshRenderer)
	self:UpdateCameraHeadAttachment()
end

function PlayerHeadLook:ResolveSkinnedMeshRenderer()
	local oModelActor			= self:FindActorByNameRecursive(self.owner, self._private.sModelActorName)
	local oSkinnedMeshRenderer	= oModelActor and oModelActor:GetSkinnedMeshRenderer() or self:FindSkinnedMeshRendererRecursive(self.owner)
	return oSkinnedMeshRenderer
end

function PlayerHeadLook:ResolveCameraTransform()
	local oCameraActor		= self:FindActorByNameRecursive(self.owner, self._private.sCameraActorName)
	return oCameraActor and oCameraActor:GetTransform() or nil
end

function PlayerHeadLook:ResolveBoneIndices(oSkinnedMeshRenderer)
	local tBoneIndices	= {}
	if not oSkinnedMeshRenderer then return tBoneIndices end
	for sBoneKey, sBoneName in pairs(tBoneNameByKey) do tBoneIndices[sBoneKey] = oSkinnedMeshRenderer:GetBoneIndex(sBoneName) end
	return tBoneIndices
end

function PlayerHeadLook:GetCameraLookAngles(oCameraTransform)
	return self:GetCameraPitchAngle(oCameraTransform), self:GetCameraYawAngle(oCameraTransform)
end

function PlayerHeadLook:GetCameraPitchAngle(oCameraTransform)
	local oView	= self._private.oView
	if oView and oView.GetPitchAngle then
		return oView:GetPitchAngle()
	end
	return self:NormalizeAngle180(oCameraTransform:GetLocalRotation():EulerAngles().x)
end

function PlayerHeadLook:GetCameraYawAngle(oCameraTransform)
	local oView	= self._private.oView

	if oView and oView.GetCameraLocalYawAngle then
		return oView:GetCameraLocalYawAngle()
	end

	return self:NormalizeAngle180(oCameraTransform:GetLocalRotation():EulerAngles().y)
end

function PlayerHeadLook:UpdateUpperBodyAngles(nDeltaTime, nCameraPitchAngle, nCameraYawAngle)
	local nHeadNeckYawAngle		= self:Clamp(nCameraYawAngle, -self.HEAD_NECK_MAX_YAW_ANGLE, self.HEAD_NECK_MAX_YAW_ANGLE)
	local nHeadNeckPitchAngle	= self:Clamp(nCameraPitchAngle, -self.HEAD_NECK_MAX_UP_ANGLE, self.HEAD_NECK_MAX_DOWN_ANGLE)
	local nTorsoYawInput		= self:Clamp(nCameraYawAngle - nHeadNeckYawAngle, -self.TORSO_MAX_YAW_ANGLE, self.TORSO_MAX_YAW_ANGLE)
	local nTorsoPitchInput		= self:Clamp(nCameraPitchAngle - nHeadNeckPitchAngle, -self.TORSO_MAX_UP_ANGLE, self.TORSO_MAX_DOWN_ANGLE)
	local nUpperBodyAlpha		= self:Clamp(nDeltaTime * self.UPPER_BODY_SMOOTH_SPEED, 0.0, 1.0)

	self:SetSmoothedBoneAngle("nHeadYaw", nHeadNeckYawAngle * self.HEAD_YAW_RATIO, nUpperBodyAlpha)
	self:SetSmoothedBoneAngle("nHeadPitch", nHeadNeckPitchAngle * self.HEAD_PITCH_RATIO, nUpperBodyAlpha)
	self:SetSmoothedBoneAngle("nNeckYaw", nHeadNeckYawAngle * self.NECK_YAW_RATIO, nUpperBodyAlpha)
	self:SetSmoothedBoneAngle("nNeckPitch", nHeadNeckPitchAngle * self.NECK_PITCH_RATIO, nUpperBodyAlpha)
	self:SetSmoothedBoneAngle("nSpine2Yaw", nTorsoYawInput * self.SPINE2_YAW_RATIO, nUpperBodyAlpha)
	self:SetSmoothedBoneAngle("nSpine2Pitch", nTorsoPitchInput * self.SPINE2_PITCH_RATIO, nUpperBodyAlpha)
	self:SetSmoothedBoneAngle("nSpine1Yaw", nTorsoYawInput * self.SPINE1_YAW_RATIO, nUpperBodyAlpha)
	self:SetSmoothedBoneAngle("nSpine1Pitch", nTorsoPitchInput * self.SPINE1_PITCH_RATIO, nUpperBodyAlpha)
	self:SetSmoothedBoneAngle("nSpineYaw", nTorsoYawInput * self.SPINE_YAW_RATIO, nUpperBodyAlpha)
	self:SetSmoothedBoneAngle("nSpinePitch", nTorsoPitchInput * self.SPINE_PITCH_RATIO, nUpperBodyAlpha)
end

function PlayerHeadLook:UpdateTurnInPlaceSway(nDeltaTime)
	local oView				= self._private.oView
	local oController		= self._private.oController
	local nBodyYawSpeed		= oView and oView.GetBodyYawSpeed and oView:GetBodyYawSpeed() or 0.0
	local nBodyYawSpeedAbs	= nBodyYawSpeed < 0 and -nBodyYawSpeed or nBodyYawSpeed
	local bHasMovementInput	= oController and oController:HasMovementInput() or false
	local bIsTurningInPlace	= not bHasMovementInput and nBodyYawSpeedAbs > self.TURN_IN_PLACE_SPEED_THRESHOLD
	local nTurnSign			= nBodyYawSpeed >= 0 and 1 or -1
	local nTurnAlphaRaw		= self.TURN_IN_PLACE_FULL_SPEED - self.TURN_IN_PLACE_SPEED_THRESHOLD
	local nTurnNormalized	= nTurnAlphaRaw > 0 and ((nBodyYawSpeedAbs - self.TURN_IN_PLACE_SPEED_THRESHOLD) / nTurnAlphaRaw) or 0.0
	local nTurnAlpha		= bIsTurningInPlace and self:Clamp(nTurnNormalized, 0.0, 1.0) or 0.0
	local nSwayAlpha		= self:Clamp(nDeltaTime * self.TURN_SWAY_SMOOTH_SPEED, 0.0, 1.0)

	local nStepCycleSpeed		= self.TURN_STEP_BASE_CYCLE_SPEED + (self.TURN_STEP_CYCLE_SPEED_FACTOR * nTurnAlpha)
	local nTwoPi				= 6.28318530718
	local nStepPhase			= self._private.nTurnStepPhase + (nStepCycleSpeed * nDeltaTime * nTwoPi * nTurnAlpha)
	local nWrappedStepPhase		= nStepPhase > nTwoPi and (nStepPhase - nTwoPi) or nStepPhase
	local nStepWaveRaw			= math.sin(nWrappedStepPhase)
	local nStepWave				= nStepWaveRaw * self.TURN_STEP_WEIGHT
	local nStepWaveAbs			= nStepWaveRaw < 0 and -nStepWaveRaw or nStepWaveRaw
	local nDirectionalAsymmetry	= nTurnSign * self.TACTICAL_LEG_ASYMMETRY * nTurnAlpha
	local nLeftLegAsymmetry		= -nDirectionalAsymmetry
	local nRightLegAsymmetry	= nDirectionalAsymmetry
	local nFootOpening			= nTurnSign * self.TACTICAL_FOOT_OPENING * nTurnAlpha
	local nKneeFlexBias			= self.TACTICAL_KNEE_FLEX_BIAS * nTurnAlpha

	self._private.nTurnStepPhase	= nWrappedStepPhase

	self:SetSmoothedBoneAngle("nHipsYaw", nTurnSign * self.HIPS_YAW_MAX_ANGLE * nTurnAlpha, nSwayAlpha)
	self:SetSmoothedBoneAngle("nHipsRoll", (nTurnSign * self.HIPS_ROLL_MAX_ANGLE * nTurnAlpha) + (nStepWave * self.HIPS_ROLL_MAX_ANGLE * 0.30 * nTurnAlpha), nSwayAlpha)
	self:SetSmoothedBoneAngle("nHipsPitch", -nStepWaveAbs * self.HIPS_PITCH_MAX_ANGLE * nTurnAlpha, nSwayAlpha)
	self:SetSmoothedBoneAngle("nLeftUpLegYaw", (nTurnSign * self.UPLEG_YAW_MAX_ANGLE * nTurnAlpha) - (nStepWave * self.UPLEG_YAW_MAX_ANGLE * 0.35 * nTurnSign * nTurnAlpha) + (self.UPLEG_YAW_MAX_ANGLE * nLeftLegAsymmetry), nSwayAlpha)
	self:SetSmoothedBoneAngle("nRightUpLegYaw", (nTurnSign * self.UPLEG_YAW_MAX_ANGLE * nTurnAlpha) + (nStepWave * self.UPLEG_YAW_MAX_ANGLE * 0.35 * nTurnSign * nTurnAlpha) + (self.UPLEG_YAW_MAX_ANGLE * nRightLegAsymmetry), nSwayAlpha)
	self:SetSmoothedBoneAngle("nLeftUpLegRoll", (-nTurnSign * self.UPLEG_ROLL_MAX_ANGLE * nTurnAlpha) + (nStepWave * self.UPLEG_ROLL_MAX_ANGLE * 0.25 * nTurnAlpha), nSwayAlpha)
	self:SetSmoothedBoneAngle("nRightUpLegRoll", (nTurnSign * self.UPLEG_ROLL_MAX_ANGLE * nTurnAlpha) - (nStepWave * self.UPLEG_ROLL_MAX_ANGLE * 0.25 * nTurnAlpha), nSwayAlpha)
	self:SetSmoothedBoneAngle("nLeftUpLegPitch", (-nStepWave * self.UPLEG_PITCH_MAX_ANGLE * nTurnAlpha) + (self.UPLEG_PITCH_MAX_ANGLE * nLeftLegAsymmetry * 0.40), nSwayAlpha)
	self:SetSmoothedBoneAngle("nRightUpLegPitch", (nStepWave * self.UPLEG_PITCH_MAX_ANGLE * nTurnAlpha) + (self.UPLEG_PITCH_MAX_ANGLE * nRightLegAsymmetry * 0.40), nSwayAlpha)
	self:SetSmoothedBoneAngle("nLeftLegPitch", (nStepWave * self.LOWER_LEG_PITCH_MAX_ANGLE * nTurnAlpha) + (self.LOWER_LEG_PITCH_MAX_ANGLE * (nKneeFlexBias + (nLeftLegAsymmetry * 0.20))), nSwayAlpha)
	self:SetSmoothedBoneAngle("nRightLegPitch", (-nStepWave * self.LOWER_LEG_PITCH_MAX_ANGLE * nTurnAlpha) + (self.LOWER_LEG_PITCH_MAX_ANGLE * (nKneeFlexBias + (nRightLegAsymmetry * 0.20))), nSwayAlpha)
	self:SetSmoothedBoneAngle("nLeftFootYaw", (nTurnSign * self.FOOT_YAW_MAX_ANGLE * nTurnAlpha) - (nStepWave * self.FOOT_YAW_MAX_ANGLE * 0.40 * nTurnSign * nTurnAlpha) + (self.FOOT_YAW_MAX_ANGLE * nFootOpening), nSwayAlpha)
	self:SetSmoothedBoneAngle("nRightFootYaw", (nTurnSign * self.FOOT_YAW_MAX_ANGLE * nTurnAlpha) + (nStepWave * self.FOOT_YAW_MAX_ANGLE * 0.40 * nTurnSign * nTurnAlpha) - (self.FOOT_YAW_MAX_ANGLE * nFootOpening), nSwayAlpha)
	self:SetSmoothedBoneAngle("nLeftFootRoll", (-nTurnSign * self.FOOT_ROLL_MAX_ANGLE * nTurnAlpha) + (nStepWave * self.FOOT_ROLL_MAX_ANGLE * 0.20 * nTurnAlpha), nSwayAlpha)
	self:SetSmoothedBoneAngle("nRightFootRoll", (nTurnSign * self.FOOT_ROLL_MAX_ANGLE * nTurnAlpha) - (nStepWave * self.FOOT_ROLL_MAX_ANGLE * 0.20 * nTurnAlpha), nSwayAlpha)
	self:SetSmoothedBoneAngle("nLeftFootPitch", (-nStepWave * self.FOOT_PITCH_MAX_ANGLE * nTurnAlpha) + (self.FOOT_PITCH_MAX_ANGLE * nLeftLegAsymmetry * 0.25), nSwayAlpha)
	self:SetSmoothedBoneAngle("nRightFootPitch", (nStepWave * self.FOOT_PITCH_MAX_ANGLE * nTurnAlpha) + (self.FOOT_PITCH_MAX_ANGLE * nRightLegAsymmetry * 0.25), nSwayAlpha)
end

function PlayerHeadLook:SetSmoothedBoneAngle(sAngleKey, nTargetAngle, nAlpha)
	local tBoneAngles	= self._private.tBoneAngles
	local nCurrentAngle	= tBoneAngles[sAngleKey] or 0.0

	tBoneAngles[sAngleKey]	= self:LerpAngle(nCurrentAngle, nTargetAngle, nAlpha)
end

function PlayerHeadLook:ApplyProceduralOffsets(oSkinnedMeshRenderer)
	local tBoneIndices	= self._private.tBoneIndices
	local tBoneAngles	= self._private.tBoneAngles

	for _, tOffsetConfig in ipairs(tBoneOffsetConfigs) do
		local nBoneIndex	= tBoneIndices[tOffsetConfig.sBoneKey]
		local nPitchAngle	= tOffsetConfig.sPitchKey and (tBoneAngles[tOffsetConfig.sPitchKey] or 0.0) or 0.0
		local nYawAngle		= tOffsetConfig.sYawKey and (tBoneAngles[tOffsetConfig.sYawKey] or 0.0) or 0.0
		local nRollAngle	= tOffsetConfig.sRollKey and (tBoneAngles[tOffsetConfig.sRollKey] or 0.0) or 0.0
		self:ApplyBoneOffset(oSkinnedMeshRenderer, nBoneIndex, nPitchAngle, nYawAngle, nRollAngle)
	end
end

function PlayerHeadLook:UpdateCameraHeadAttachment()
	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer
	local oCameraTransform		= self._private.oCameraTransform

	if not oSkinnedMeshRenderer or not oCameraTransform then return end

	local tBoneIndices			= self._private.tBoneIndices
	local vHeadLocalPosition	= Vector3.new(0, 0, 0)
	local qHeadLocalRotation	= Quaternion.new(Vector3.new(0, 0, 0))
	local bHasHeadTransform		= false

	for _, sBoneKey in ipairs(tCameraAttachmentBoneChain) do
		local nBoneIndex	= tBoneIndices[sBoneKey]

		vHeadLocalPosition, qHeadLocalRotation, bHasHeadTransform	= self:AccumulateBoneLocalTransform(oSkinnedMeshRenderer, vHeadLocalPosition, qHeadLocalRotation, nBoneIndex, bHasHeadTransform)
	end

	if not bHasHeadTransform then return end

	local vHeadLocalOffset		= Vector3.new(self.CAMERA_HEAD_OFFSET_X, self.CAMERA_HEAD_OFFSET_Y, self.CAMERA_HEAD_OFFSET_Z)
	local vCameraLocalPosition	= vHeadLocalPosition + (qHeadLocalRotation * vHeadLocalOffset)

	oCameraTransform:SetLocalPosition(vCameraLocalPosition)
end

function PlayerHeadLook:AccumulateBoneLocalTransform(oSkinnedMeshRenderer, vAccumPosition, qAccumRotation, nBoneIndex, bHasTransform)
	if not nBoneIndex then
		return vAccumPosition, qAccumRotation, bHasTransform or false
	end

	local vBoneLocalPosition	= oSkinnedMeshRenderer:GetBoneLocalPosition(nBoneIndex)
	local qBoneLocalRotation	= oSkinnedMeshRenderer:GetBoneLocalRotation(nBoneIndex)
	local bDidAccumulate		= (vBoneLocalPosition ~= nil) or (qBoneLocalRotation ~= nil)
	local bHasAccumulated		= bHasTransform or false

	if vBoneLocalPosition then
		vAccumPosition	= vAccumPosition + (qAccumRotation * vBoneLocalPosition)
	end

	if qBoneLocalRotation then
		qAccumRotation	= qAccumRotation * qBoneLocalRotation
	end

	return vAccumPosition, qAccumRotation, bHasAccumulated or bDidAccumulate
end

function PlayerHeadLook:ApplyBoneOffset(oSkinnedMeshRenderer, nBoneIndex, nPitchAngle, nYawAngle, nRollAngle)
	if not nBoneIndex then return end

	local qCurrentBoneRotation	= oSkinnedMeshRenderer:GetBoneLocalRotation(nBoneIndex)
	if not qCurrentBoneRotation then return end

	local qOffsetRotation		= Quaternion.new(Vector3.new(nPitchAngle, nYawAngle, nRollAngle))
	local qTargetBoneRotation	= qCurrentBoneRotation * qOffsetRotation

	oSkinnedMeshRenderer:SetBoneLocalRotation(nBoneIndex, qTargetBoneRotation)
end

return PlayerHeadLook
