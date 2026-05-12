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
		sModelActorName				= "Player Model",
		sCameraActorName			= "Player Camera",
		sHeadBoneName				= "mixamorig:Head",
		sNeckBoneName				= "mixamorig:Neck",
		sSpine2BoneName				= "mixamorig:Spine2",
		sSpine1BoneName				= "mixamorig:Spine1",
		sSpineBoneName				= "mixamorig:Spine",
		sHipsBoneName				= "mixamorig:Hips",
		sLeftUpLegBoneName			= "mixamorig:LeftUpLeg",
		sRightUpLegBoneName			= "mixamorig:RightUpLeg",
		sLeftLegBoneName			= "mixamorig:LeftLeg",
		sRightLegBoneName			= "mixamorig:RightLeg",
		sLeftFootBoneName			= "mixamorig:LeftFoot",
		sRightFootBoneName			= "mixamorig:RightFoot",
		oSkinnedMeshRenderer		= nil,
		oCameraTransform			= nil,
		oView						= nil,
		oController					= nil,
		nHeadBoneIndex				= nil,
		nNeckBoneIndex				= nil,
		nSpine2BoneIndex			= nil,
		nSpine1BoneIndex			= nil,
		nSpineBoneIndex				= nil,
		nHipsBoneIndex				= nil,
		nLeftUpLegBoneIndex			= nil,
		nRightUpLegBoneIndex		= nil,
		nLeftLegBoneIndex			= nil,
		nRightLegBoneIndex			= nil,
		nLeftFootBoneIndex			= nil,
		nRightFootBoneIndex			= nil,
		nHeadYaw					= 0.0,
		nHeadPitch					= 0.0,
		nNeckYaw					= 0.0,
		nNeckPitch					= 0.0,
		nSpine2Yaw					= 0.0,
		nSpine2Pitch				= 0.0,
		nSpine1Yaw					= 0.0,
		nSpine1Pitch				= 0.0,
		nSpineYaw					= 0.0,
		nSpinePitch					= 0.0,
		nTurnStepPhase				= 0.0,
		nHipsYaw					= 0.0,
		nHipsRoll					= 0.0,
		nHipsPitch					= 0.0,
		nLeftUpLegYaw				= 0.0,
		nLeftUpLegRoll				= 0.0,
		nLeftUpLegPitch				= 0.0,
		nRightUpLegYaw				= 0.0,
		nRightUpLegRoll				= 0.0,
		nRightUpLegPitch			= 0.0,
		nLeftLegPitch				= 0.0,
		nRightLegPitch				= 0.0,
		nLeftFootYaw				= 0.0,
		nLeftFootRoll				= 0.0,
		nLeftFootPitch				= 0.0,
		nRightFootYaw				= 0.0,
		nRightFootRoll				= 0.0,
		nRightFootPitch				= 0.0,
		qHeadPreviousOffset			= nil,
		qNeckPreviousOffset			= nil,
		qSpine2PreviousOffset		= nil,
		qSpine1PreviousOffset		= nil,
		qSpinePreviousOffset		= nil,
		qHipsPreviousOffset			= nil,
		qLeftUpLegPreviousOffset	= nil,
		qRightUpLegPreviousOffset	= nil,
		qLeftLegPreviousOffset		= nil,
		qRightLegPreviousOffset		= nil,
		qLeftFootPreviousOffset		= nil,
		qRightFootPreviousOffset	= nil,
	}
}

function PlayerHeadLook:OnAwake()
	self									= setmetatable(self, self.owner:GetBehaviour("Class"))

	local oSkinnedMeshRenderer				= self:ResolveSkinnedMeshRenderer()
	local oCameraTransform					= self:ResolveCameraTransform()
	local oView							= self:ResolveViewBehaviour()
	local oController						= self.owner:GetBehaviour("Controller")

	self._private.oSkinnedMeshRenderer		= oSkinnedMeshRenderer
	self._private.oCameraTransform			= oCameraTransform
	self._private.oView						= oView
	self._private.oController				= oController
	self._private.nHeadBoneIndex			= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sHeadBoneName)
	self._private.nNeckBoneIndex			= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sNeckBoneName)
	self._private.nSpine2BoneIndex			= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sSpine2BoneName)
	self._private.nSpine1BoneIndex			= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sSpine1BoneName)
	self._private.nSpineBoneIndex			= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sSpineBoneName)
	self._private.nHipsBoneIndex			= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sHipsBoneName)
	self._private.nLeftUpLegBoneIndex		= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sLeftUpLegBoneName)
	self._private.nRightUpLegBoneIndex		= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sRightUpLegBoneName)
	self._private.nLeftLegBoneIndex		= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sLeftLegBoneName)
	self._private.nRightLegBoneIndex		= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sRightLegBoneName)
	self._private.nLeftFootBoneIndex		= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sLeftFootBoneName)
	self._private.nRightFootBoneIndex		= self:ResolveBoneIndex(oSkinnedMeshRenderer, self._private.sRightFootBoneName)

	local qIdentityOffset					= Quaternion.new(Vector3.new(0, 0, 0))

	self._private.qHeadPreviousOffset		= qIdentityOffset
	self._private.qNeckPreviousOffset		= qIdentityOffset
	self._private.qSpine2PreviousOffset		= qIdentityOffset
	self._private.qSpine1PreviousOffset		= qIdentityOffset
	self._private.qSpinePreviousOffset		= qIdentityOffset
	self._private.qHipsPreviousOffset		= qIdentityOffset
	self._private.qLeftUpLegPreviousOffset	= qIdentityOffset
	self._private.qRightUpLegPreviousOffset	= qIdentityOffset
	self._private.qLeftLegPreviousOffset	= qIdentityOffset
	self._private.qRightLegPreviousOffset	= qIdentityOffset
	self._private.qLeftFootPreviousOffset	= qIdentityOffset
	self._private.qRightFootPreviousOffset	= qIdentityOffset
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

function PlayerHeadLook:ResolveBoneIndex(oSkinnedMeshRenderer, sBoneName)
	return oSkinnedMeshRenderer and oSkinnedMeshRenderer:GetBoneIndex(sBoneName) or nil
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
	local nYawAngle				= self:NormalizeAngle180(vCameraEulerAngles.y)

	return nYawAngle
end

function PlayerHeadLook:UpdateUpperBodyAngles(nDeltaTime, nCameraPitchAngle, nCameraYawAngle)
	local nHeadNeckYawAngle		= self:Clamp(nCameraYawAngle, -self.HEAD_NECK_MAX_YAW_ANGLE, self.HEAD_NECK_MAX_YAW_ANGLE)
	local nHeadNeckPitchAngle	= self:Clamp(nCameraPitchAngle, -self.HEAD_NECK_MAX_UP_ANGLE, self.HEAD_NECK_MAX_DOWN_ANGLE)
	local nTorsoYawInput		= self:Clamp(nCameraYawAngle - nHeadNeckYawAngle, -self.TORSO_MAX_YAW_ANGLE, self.TORSO_MAX_YAW_ANGLE)
	local nTorsoPitchInput		= self:Clamp(nCameraPitchAngle - nHeadNeckPitchAngle, -self.TORSO_MAX_UP_ANGLE, self.TORSO_MAX_DOWN_ANGLE)
	local nUpperBodyAlpha		= self:Clamp(nDeltaTime * self.UPPER_BODY_SMOOTH_SPEED, 0.0, 1.0)
	local tPrivate				= self._private

	tPrivate.nHeadYaw		= self:LerpAngle(tPrivate.nHeadYaw, nHeadNeckYawAngle * self.HEAD_YAW_RATIO, nUpperBodyAlpha)
	tPrivate.nHeadPitch		= self:LerpAngle(tPrivate.nHeadPitch, nHeadNeckPitchAngle * self.HEAD_PITCH_RATIO, nUpperBodyAlpha)
	tPrivate.nNeckYaw		= self:LerpAngle(tPrivate.nNeckYaw, nHeadNeckYawAngle * self.NECK_YAW_RATIO, nUpperBodyAlpha)
	tPrivate.nNeckPitch		= self:LerpAngle(tPrivate.nNeckPitch, nHeadNeckPitchAngle * self.NECK_PITCH_RATIO, nUpperBodyAlpha)
	tPrivate.nSpine2Yaw		= self:LerpAngle(tPrivate.nSpine2Yaw, nTorsoYawInput * self.SPINE2_YAW_RATIO, nUpperBodyAlpha)
	tPrivate.nSpine2Pitch	= self:LerpAngle(tPrivate.nSpine2Pitch, nTorsoPitchInput * self.SPINE2_PITCH_RATIO, nUpperBodyAlpha)
	tPrivate.nSpine1Yaw		= self:LerpAngle(tPrivate.nSpine1Yaw, nTorsoYawInput * self.SPINE1_YAW_RATIO, nUpperBodyAlpha)
	tPrivate.nSpine1Pitch	= self:LerpAngle(tPrivate.nSpine1Pitch, nTorsoPitchInput * self.SPINE1_PITCH_RATIO, nUpperBodyAlpha)
	tPrivate.nSpineYaw		= self:LerpAngle(tPrivate.nSpineYaw, nTorsoYawInput * self.SPINE_YAW_RATIO, nUpperBodyAlpha)
	tPrivate.nSpinePitch	= self:LerpAngle(tPrivate.nSpinePitch, nTorsoPitchInput * self.SPINE_PITCH_RATIO, nUpperBodyAlpha)
end

function PlayerHeadLook:UpdateTurnInPlaceSway(nDeltaTime)
	local oView					= self._private.oView
	local oController			= self._private.oController
	local nBodyYawSpeed			= oView and oView.GetBodyYawSpeed and oView:GetBodyYawSpeed() or 0.0
	local nBodyYawSpeedAbs		= nBodyYawSpeed < 0 and -nBodyYawSpeed or nBodyYawSpeed
	local bHasMovementInput		= oController and oController:HasMovementInput() or false
	local bIsTurningInPlace		= not bHasMovementInput and nBodyYawSpeedAbs > self.TURN_IN_PLACE_SPEED_THRESHOLD
	local nTurnSign				= nBodyYawSpeed >= 0 and 1 or -1
	local nTurnAlphaRaw			= self.TURN_IN_PLACE_FULL_SPEED - self.TURN_IN_PLACE_SPEED_THRESHOLD
	local nTurnNormalized		= nTurnAlphaRaw > 0 and ((nBodyYawSpeedAbs - self.TURN_IN_PLACE_SPEED_THRESHOLD) / nTurnAlphaRaw) or 0.0
	local nTurnAlpha			= bIsTurningInPlace and self:Clamp(nTurnNormalized, 0.0, 1.0) or 0.0
	local nSwayAlpha			= self:Clamp(nDeltaTime * self.TURN_SWAY_SMOOTH_SPEED, 0.0, 1.0)
	local tPrivate				= self._private

	local nStepCycleSpeed		= self.TURN_STEP_BASE_CYCLE_SPEED + (self.TURN_STEP_CYCLE_SPEED_FACTOR * nTurnAlpha)
	local nTwoPi				= 6.28318530718
	local nStepPhase			= tPrivate.nTurnStepPhase + (nStepCycleSpeed * nDeltaTime * nTwoPi * nTurnAlpha)
	local nWrappedStepPhase		= nStepPhase > nTwoPi and (nStepPhase - nTwoPi) or nStepPhase
	local nStepWaveRaw			= math.sin(nWrappedStepPhase)
	local nStepWave				= nStepWaveRaw * self.TURN_STEP_WEIGHT
	local nStepWaveAbs			= nStepWaveRaw < 0 and -nStepWaveRaw or nStepWaveRaw
	local nDirectionalAsymmetry	= nTurnSign * self.TACTICAL_LEG_ASYMMETRY * nTurnAlpha
	local nLeftLegAsymmetry		= -nDirectionalAsymmetry
	local nRightLegAsymmetry	= nDirectionalAsymmetry
	local nFootOpening			= nTurnSign * self.TACTICAL_FOOT_OPENING * nTurnAlpha
	local nKneeFlexBias			= self.TACTICAL_KNEE_FLEX_BIAS * nTurnAlpha

	tPrivate.nTurnStepPhase		= nWrappedStepPhase

	local nHipsYawTarget			= nTurnSign * self.HIPS_YAW_MAX_ANGLE * nTurnAlpha
	local nHipsRollBase			= nTurnSign * self.HIPS_ROLL_MAX_ANGLE * nTurnAlpha
	local nHipsRollStep			= nStepWave * (self.HIPS_ROLL_MAX_ANGLE * 0.30) * nTurnAlpha
	local nHipsRollTarget			= nHipsRollBase + nHipsRollStep
	local nHipsPitchTarget			= -nStepWaveAbs * self.HIPS_PITCH_MAX_ANGLE * nTurnAlpha
	local nLeftUpLegYawTarget		= (nTurnSign * self.UPLEG_YAW_MAX_ANGLE * nTurnAlpha) - (nStepWave * self.UPLEG_YAW_MAX_ANGLE * 0.35 * nTurnSign * nTurnAlpha) + (self.UPLEG_YAW_MAX_ANGLE * nLeftLegAsymmetry)
	local nRightUpLegYawTarget		= (nTurnSign * self.UPLEG_YAW_MAX_ANGLE * nTurnAlpha) + (nStepWave * self.UPLEG_YAW_MAX_ANGLE * 0.35 * nTurnSign * nTurnAlpha) + (self.UPLEG_YAW_MAX_ANGLE * nRightLegAsymmetry)
	local nLeftUpLegRollBase		= -nTurnSign * self.UPLEG_ROLL_MAX_ANGLE * nTurnAlpha
	local nRightUpLegRollBase		= nTurnSign * self.UPLEG_ROLL_MAX_ANGLE * nTurnAlpha
	local nLeftUpLegRollTarget		= nLeftUpLegRollBase + (nStepWave * self.UPLEG_ROLL_MAX_ANGLE * 0.25 * nTurnAlpha)
	local nRightUpLegRollTarget		= nRightUpLegRollBase - (nStepWave * self.UPLEG_ROLL_MAX_ANGLE * 0.25 * nTurnAlpha)
	local nLeftUpLegPitchTarget		= (-nStepWave * self.UPLEG_PITCH_MAX_ANGLE * nTurnAlpha) + (self.UPLEG_PITCH_MAX_ANGLE * nLeftLegAsymmetry * 0.40)
	local nRightUpLegPitchTarget	= (nStepWave * self.UPLEG_PITCH_MAX_ANGLE * nTurnAlpha) + (self.UPLEG_PITCH_MAX_ANGLE * nRightLegAsymmetry * 0.40)
	local nLeftLegPitchTarget		= (nStepWave * self.LOWER_LEG_PITCH_MAX_ANGLE * nTurnAlpha) + (self.LOWER_LEG_PITCH_MAX_ANGLE * (nKneeFlexBias + (nLeftLegAsymmetry * 0.20)))
	local nRightLegPitchTarget		= (-nStepWave * self.LOWER_LEG_PITCH_MAX_ANGLE * nTurnAlpha) + (self.LOWER_LEG_PITCH_MAX_ANGLE * (nKneeFlexBias + (nRightLegAsymmetry * 0.20)))
	local nLeftFootYawTarget		= (nTurnSign * self.FOOT_YAW_MAX_ANGLE * nTurnAlpha) - (nStepWave * self.FOOT_YAW_MAX_ANGLE * 0.40 * nTurnSign * nTurnAlpha) + (self.FOOT_YAW_MAX_ANGLE * nFootOpening)
	local nRightFootYawTarget		= (nTurnSign * self.FOOT_YAW_MAX_ANGLE * nTurnAlpha) + (nStepWave * self.FOOT_YAW_MAX_ANGLE * 0.40 * nTurnSign * nTurnAlpha) - (self.FOOT_YAW_MAX_ANGLE * nFootOpening)
	local nLeftFootRollTarget		= (-nTurnSign * self.FOOT_ROLL_MAX_ANGLE * nTurnAlpha) + (nStepWave * self.FOOT_ROLL_MAX_ANGLE * 0.20 * nTurnAlpha)
	local nRightFootRollTarget		= (nTurnSign * self.FOOT_ROLL_MAX_ANGLE * nTurnAlpha) - (nStepWave * self.FOOT_ROLL_MAX_ANGLE * 0.20 * nTurnAlpha)
	local nLeftFootPitchTarget		= (-nStepWave * self.FOOT_PITCH_MAX_ANGLE * nTurnAlpha) + (self.FOOT_PITCH_MAX_ANGLE * nLeftLegAsymmetry * 0.25)
	local nRightFootPitchTarget		= (nStepWave * self.FOOT_PITCH_MAX_ANGLE * nTurnAlpha) + (self.FOOT_PITCH_MAX_ANGLE * nRightLegAsymmetry * 0.25)

	tPrivate.nHipsYaw			= self:LerpAngle(tPrivate.nHipsYaw, nHipsYawTarget, nSwayAlpha)
	tPrivate.nHipsRoll			= self:LerpAngle(tPrivate.nHipsRoll, nHipsRollTarget, nSwayAlpha)
	tPrivate.nHipsPitch			= self:LerpAngle(tPrivate.nHipsPitch, nHipsPitchTarget, nSwayAlpha)
	tPrivate.nLeftUpLegYaw		= self:LerpAngle(tPrivate.nLeftUpLegYaw, nLeftUpLegYawTarget, nSwayAlpha)
	tPrivate.nRightUpLegYaw		= self:LerpAngle(tPrivate.nRightUpLegYaw, nRightUpLegYawTarget, nSwayAlpha)
	tPrivate.nLeftUpLegRoll		= self:LerpAngle(tPrivate.nLeftUpLegRoll, nLeftUpLegRollTarget, nSwayAlpha)
	tPrivate.nRightUpLegRoll	= self:LerpAngle(tPrivate.nRightUpLegRoll, nRightUpLegRollTarget, nSwayAlpha)
	tPrivate.nLeftUpLegPitch	= self:LerpAngle(tPrivate.nLeftUpLegPitch, nLeftUpLegPitchTarget, nSwayAlpha)
	tPrivate.nRightUpLegPitch	= self:LerpAngle(tPrivate.nRightUpLegPitch, nRightUpLegPitchTarget, nSwayAlpha)
	tPrivate.nLeftLegPitch		= self:LerpAngle(tPrivate.nLeftLegPitch, nLeftLegPitchTarget, nSwayAlpha)
	tPrivate.nRightLegPitch		= self:LerpAngle(tPrivate.nRightLegPitch, nRightLegPitchTarget, nSwayAlpha)
	tPrivate.nLeftFootYaw		= self:LerpAngle(tPrivate.nLeftFootYaw, nLeftFootYawTarget, nSwayAlpha)
	tPrivate.nLeftFootRoll		= self:LerpAngle(tPrivate.nLeftFootRoll, nLeftFootRollTarget, nSwayAlpha)
	tPrivate.nLeftFootPitch		= self:LerpAngle(tPrivate.nLeftFootPitch, nLeftFootPitchTarget, nSwayAlpha)
	tPrivate.nRightFootYaw		= self:LerpAngle(tPrivate.nRightFootYaw, nRightFootYawTarget, nSwayAlpha)
	tPrivate.nRightFootRoll		= self:LerpAngle(tPrivate.nRightFootRoll, nRightFootRollTarget, nSwayAlpha)
	tPrivate.nRightFootPitch	= self:LerpAngle(tPrivate.nRightFootPitch, nRightFootPitchTarget, nSwayAlpha)
end

function PlayerHeadLook:ApplyProceduralOffsets(oSkinnedMeshRenderer)
	local tPrivate	= self._private

	tPrivate.qHeadPreviousOffset			= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nHeadBoneIndex, tPrivate.qHeadPreviousOffset, tPrivate.nHeadPitch, tPrivate.nHeadYaw, 0.0)
	tPrivate.qNeckPreviousOffset			= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nNeckBoneIndex, tPrivate.qNeckPreviousOffset, tPrivate.nNeckPitch, tPrivate.nNeckYaw, 0.0)
	tPrivate.qSpine2PreviousOffset			= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nSpine2BoneIndex, tPrivate.qSpine2PreviousOffset, tPrivate.nSpine2Pitch, tPrivate.nSpine2Yaw, 0.0)
	tPrivate.qSpine1PreviousOffset			= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nSpine1BoneIndex, tPrivate.qSpine1PreviousOffset, tPrivate.nSpine1Pitch, tPrivate.nSpine1Yaw, 0.0)
	tPrivate.qSpinePreviousOffset			= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nSpineBoneIndex, tPrivate.qSpinePreviousOffset, tPrivate.nSpinePitch, tPrivate.nSpineYaw, 0.0)
	tPrivate.qHipsPreviousOffset			= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nHipsBoneIndex, tPrivate.qHipsPreviousOffset, tPrivate.nHipsPitch, tPrivate.nHipsYaw, tPrivate.nHipsRoll)
	tPrivate.qLeftUpLegPreviousOffset		= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nLeftUpLegBoneIndex, tPrivate.qLeftUpLegPreviousOffset, tPrivate.nLeftUpLegPitch, tPrivate.nLeftUpLegYaw, tPrivate.nLeftUpLegRoll)
	tPrivate.qRightUpLegPreviousOffset		= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nRightUpLegBoneIndex, tPrivate.qRightUpLegPreviousOffset, tPrivate.nRightUpLegPitch, tPrivate.nRightUpLegYaw, tPrivate.nRightUpLegRoll)
	tPrivate.qLeftLegPreviousOffset		= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nLeftLegBoneIndex, tPrivate.qLeftLegPreviousOffset, tPrivate.nLeftLegPitch, 0.0, 0.0)
	tPrivate.qRightLegPreviousOffset		= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nRightLegBoneIndex, tPrivate.qRightLegPreviousOffset, tPrivate.nRightLegPitch, 0.0, 0.0)
	tPrivate.qLeftFootPreviousOffset		= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nLeftFootBoneIndex, tPrivate.qLeftFootPreviousOffset, tPrivate.nLeftFootPitch, tPrivate.nLeftFootYaw, tPrivate.nLeftFootRoll)
	tPrivate.qRightFootPreviousOffset		= self:ApplyBoneOffset(oSkinnedMeshRenderer, tPrivate.nRightFootBoneIndex, tPrivate.qRightFootPreviousOffset, tPrivate.nRightFootPitch, tPrivate.nRightFootYaw, tPrivate.nRightFootRoll)
end

function PlayerHeadLook:UpdateCameraHeadAttachment()
	local tPrivate				= self._private
	local oSkinnedMeshRenderer	= tPrivate.oSkinnedMeshRenderer
	local oCameraTransform		= tPrivate.oCameraTransform

	if not oSkinnedMeshRenderer or not oCameraTransform then return end

	local vHeadLocalPosition	= Vector3.new(0, 0, 0)
	local qHeadLocalRotation	= Quaternion.new(Vector3.new(0, 0, 0))
	local bHasHeadTransform		= false

	vHeadLocalPosition, qHeadLocalRotation, bHasHeadTransform	= self:AccumulateBoneLocalTransform(oSkinnedMeshRenderer, vHeadLocalPosition, qHeadLocalRotation, tPrivate.nHipsBoneIndex)
	vHeadLocalPosition, qHeadLocalRotation, bHasHeadTransform	= self:AccumulateBoneLocalTransform(oSkinnedMeshRenderer, vHeadLocalPosition, qHeadLocalRotation, tPrivate.nSpineBoneIndex, bHasHeadTransform)
	vHeadLocalPosition, qHeadLocalRotation, bHasHeadTransform	= self:AccumulateBoneLocalTransform(oSkinnedMeshRenderer, vHeadLocalPosition, qHeadLocalRotation, tPrivate.nSpine1BoneIndex, bHasHeadTransform)
	vHeadLocalPosition, qHeadLocalRotation, bHasHeadTransform	= self:AccumulateBoneLocalTransform(oSkinnedMeshRenderer, vHeadLocalPosition, qHeadLocalRotation, tPrivate.nSpine2BoneIndex, bHasHeadTransform)
	vHeadLocalPosition, qHeadLocalRotation, bHasHeadTransform	= self:AccumulateBoneLocalTransform(oSkinnedMeshRenderer, vHeadLocalPosition, qHeadLocalRotation, tPrivate.nNeckBoneIndex, bHasHeadTransform)
	vHeadLocalPosition, qHeadLocalRotation, bHasHeadTransform	= self:AccumulateBoneLocalTransform(oSkinnedMeshRenderer, vHeadLocalPosition, qHeadLocalRotation, tPrivate.nHeadBoneIndex, bHasHeadTransform)

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

function PlayerHeadLook:ApplyBoneOffset(oSkinnedMeshRenderer, nBoneIndex, qPreviousOffset, nPitchAngle, nYawAngle, nRollAngle)
	if not nBoneIndex then
		return qPreviousOffset
	end

	local qCurrentBoneRotation	= oSkinnedMeshRenderer:GetBoneLocalRotation(nBoneIndex)
	if not qCurrentBoneRotation then
		return qPreviousOffset
	end

	local qNewOffset			= Quaternion.new(Vector3.new(nPitchAngle, nYawAngle, nRollAngle))
	local qTargetBoneRotation	= qCurrentBoneRotation * qNewOffset

	oSkinnedMeshRenderer:SetBoneLocalRotation(nBoneIndex, qTargetBoneRotation)

	return qNewOffset
end

function PlayerHeadLook:LerpAngle(nFromAngle, nToAngle, nAlpha)
	local nDeltaAngle	= self:NormalizeAngle180(nToAngle - nFromAngle)

	return nFromAngle + (nDeltaAngle * nAlpha)
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
