---@class PlayerArmIK : Behaviour
local PlayerArmIK	=
{
	bEnableIK					= true,
	nIKRotationSmoothSpeed		= 20.0,
	nIKBendNormalSmoothSpeed	= 14.0,
	nIKTargetMargin				= 0.02,
	nIKEpsilon					= 0.0001,
	bEnableShoulderAssist			= true,
	nShoulderAssistWeight			= 0.35,
	nShoulderAssistSmoothSpeed		= 10.0,
	bEnableHandRotationAlignment		= true,
	nHandRotationSmoothSpeed		= 24.0,
	nHandRotationWeight			= 0.9,
	bEnableWeaponYawAssist		= false,
	nWeaponYawAssistSpeed		= 40.0,
	nWeaponYawAssistReturnSpeed	= 10.0,
	nWeaponYawAssistMaxOffset	= 45.0,
	nWeaponYawAssistGain		= 1.5,
	nWeaponYawAssistDeadZone	= 0.005,
	nWeaponYawAssistAngleDeadZone	= 0.35,
	nWeaponYawAssistSign		= 1.0,
	bEnableUpperBodyTargetCompensation	= false,
	nUpperBodyTargetCompensationWeight	= 0.78,
	nUpperBodyTargetCompensationPitchWeight	= 0.42,
	nUpperBodyTargetCompensationSmoothSpeed	= 14.0,
	nShoulderAssistMaxAngle		= 42.0,
	bEnableIKLogs				= false,

	_private	=
	{
		sModelActorName		= "Player Model",
		oSkinnedMeshRenderer	= nil,
		oModelTransform		= nil,
		oWeaponHolder		= nil,
		oPlayerState		= nil,
		sLastPlayerState	= nil,
		tBoneIndices		= {},
		tArmRuntimeByName	= {},
		nWeaponYawAssistCurrent	= 0.0,
		oWeaponYawAssistLastWeapon	= nil,
		oCurrentWeapon		= nil,
		oHeadLook			= nil,
		qUpperBodyCompensationCurrent	= nil,
	}
}

local tBoneNameByKey	=
{
	sHips				= "mixamorig:Hips",
	sSpine				= "mixamorig:Spine",
	sSpine1				= "mixamorig:Spine1",
	sSpine2				= "mixamorig:Spine2",
	sLeftShoulder		= "mixamorig:LeftShoulder",
	sLeftArm			= "mixamorig:LeftArm",
	sLeftForeArm		= "mixamorig:LeftForeArm",
	sLeftHand			= "mixamorig:LeftHand",
	sRightShoulder		= "mixamorig:RightShoulder",
	sRightArm			= "mixamorig:RightArm",
	sRightForeArm		= "mixamorig:RightForeArm",
	sRightHand			= "mixamorig:RightHand",
}

local tArmConfigs	=
{
	{
		sName			= "RightArm",
		sShoulderKey	= "sRightShoulder",
		sArmKey			= "sRightArm",
		sForeArmKey		= "sRightForeArm",
		sHandKey		= "sRightHand",
		sWeaponGripKey	= "sRightGrip",
		nElbowBendSign	= -1.0,
		nDefaultGripOffsetX	= 0.0,
		nDefaultGripOffsetY	= 0.0,
		nDefaultGripOffsetZ	= 0.0,
		tChainKeys		= { "sHips", "sSpine", "sSpine1", "sSpine2", "sRightShoulder", "sRightArm", "sRightForeArm", "sRightHand" },
	},
	{
		sName			= "LeftArm",
		sShoulderKey	= "sLeftShoulder",
		sArmKey			= "sLeftArm",
		sForeArmKey		= "sLeftForeArm",
		sHandKey		= "sLeftHand",
		sWeaponGripKey	= "sLeftGrip",
		nElbowBendSign	= -1.0,
		nDefaultGripOffsetX	= 0.0,
		nDefaultGripOffsetY	= 0.0,
		nDefaultGripOffsetZ	= 0.0,
		tChainKeys		= { "sHips", "sSpine", "sSpine1", "sSpine2", "sLeftShoulder", "sLeftArm", "sLeftForeArm", "sLeftHand" },
	},
}

function PlayerArmIK:OnAwake()
	self								= setmetatable(self, self:ResolveClassBehaviour())
	self._private.oSkinnedMeshRenderer	= self:ResolveSkinnedMeshRenderer()
	self._private.oModelTransform		= self:ResolveModelTransform()
	self._private.oWeaponHolder			= self:FindBehaviourInParents(self.owner, "WeaponHolder")
	self._private.oPlayerState			= self:FindBehaviourInParents(self.owner, "PlayerState")
	self._private.oHeadLook				= self:FindBehaviourInParents(self.owner, "PlayerHeadLook")
	self._private.tBoneIndices			= self:ResolveBoneIndices(self._private.oSkinnedMeshRenderer)
	self._private.qUpperBodyCompensationCurrent	= Quaternion.new(Vector3.new(0, 0, 0))
	self._private.sLastPlayerState		= self:GetCurrentPlayerStateName()
	self:InitializeArmRuntime()
end

function PlayerArmIK:OnLateUpdate(nDeltaTime)
	local oWeaponHolder			= self._private.oWeaponHolder
	local oWeapon				= oWeaponHolder and oWeaponHolder.GetEquippedWeapon and oWeaponHolder:GetEquippedWeapon() or nil
	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer
	local oModelTransform			= self._private.oModelTransform

	self._private.oCurrentWeapon		= oWeapon
	self:HandlePlayerStateRuntimeReset()
	self:UpdateUpperBodyTargetCompensation(nDeltaTime)

	if not self.bEnableIK then
		self:ResetAllArmRuntime()
		self:UpdateWeaponYawAssist(oWeapon, oSkinnedMeshRenderer, oModelTransform, nDeltaTime, nil)
		return
	end

	if not oSkinnedMeshRenderer or not oModelTransform or not oWeaponHolder then
		self:UpdateWeaponYawAssist(oWeapon, oSkinnedMeshRenderer, oModelTransform, nDeltaTime, nil)
		return
	end

	local tGripTargetsWorld	= self:ResolveWeaponGripTargetsWorld(oWeapon)
	self:UpdateWeaponYawAssist(oWeapon, oSkinnedMeshRenderer, oModelTransform, nDeltaTime, tGripTargetsWorld)

	tGripTargetsWorld	= self:ResolveWeaponGripTargetsWorld(oWeapon)
	if not tGripTargetsWorld then
		self:ResetAllArmRuntime()
		return
	end

	for _, tArmConfig in ipairs(tArmConfigs) do
		local sWeaponGripKey		= tArmConfig.sWeaponGripKey
		local tGripTarget		= tGripTargetsWorld[sWeaponGripKey]
		local vGripWorld		= tGripTarget and tGripTarget.vWorldPosition or nil
		local vGripModel		= vGripWorld and self:WorldToModelPosition(oModelTransform, vGripWorld) or nil

		if vGripModel then
			local bDidSolveArm	= self:ApplyTwoBoneArmIK(oSkinnedMeshRenderer, tArmConfig, vGripModel, tGripTarget, nDeltaTime)

			if not bDidSolveArm then
				self:ResetArmRuntime(tArmConfig)
			end
		else
			self:ResetArmRuntime(tArmConfig)
		end
	end
end

function PlayerArmIK:HandlePlayerStateRuntimeReset()
	local sCurrentPlayerState	= self:GetCurrentPlayerStateName()
	local sLastPlayerState		= self._private.sLastPlayerState
	local bDidStateChange		= sCurrentPlayerState ~= nil and sLastPlayerState ~= nil and sCurrentPlayerState ~= sLastPlayerState

	if bDidStateChange then
		local bWasCrouchingState	= self:IsCrouchingStateName(sLastPlayerState)
		local bIsCrouchingState		= self:IsCrouchingStateName(sCurrentPlayerState)
		local bDidToggleCrouchState	= bWasCrouchingState ~= bIsCrouchingState

		if bDidToggleCrouchState then
			self:ResetAllArmRuntime()
		end
	end

	self._private.sLastPlayerState	= sCurrentPlayerState or sLastPlayerState
end

function PlayerArmIK:GetCurrentPlayerStateName()
	local oPlayerState	= self._private.oPlayerState

	if not oPlayerState then
		oPlayerState					= self:FindBehaviourInParents(self.owner, "PlayerState")
		self._private.oPlayerState		= oPlayerState
	end

	local sCurrentState	= oPlayerState and oPlayerState.GetCurrentState and oPlayerState:GetCurrentState() or nil

	return sCurrentState
end

function PlayerArmIK:IsCrouchingStateName(sStateName)
	if not sStateName then
		return false
	end

	return sStateName == "CrouchingIdle" or sStateName == "CrouchingWalking"
end

function PlayerArmIK:UpdateUpperBodyTargetCompensation(nDeltaTime)
	local qIdentity					= Quaternion.new(Vector3.new(0, 0, 0))
	local bEnableCompensation		= self.bEnableUpperBodyTargetCompensation
	local oHeadLook					= self._private.oHeadLook
	local qCompensationTarget		= qIdentity

	if not oHeadLook then
		oHeadLook					= self:FindBehaviourInParents(self.owner, "PlayerHeadLook")
		self._private.oHeadLook		= oHeadLook
	end

	if bEnableCompensation and oHeadLook and oHeadLook.GetUpperBodyAimOffsetAngles then
		local nUpperBodyPitchAngle, nUpperBodyYawAngle	= oHeadLook:GetUpperBodyAimOffsetAngles()
		local nCompensationWeight			= self:Clamp(self.nUpperBodyTargetCompensationWeight or 0.0, 0.0, 1.0)
		local nCompensatedPitchWeight		= self:Clamp((self.nUpperBodyTargetCompensationPitchWeight or 1.0) * nCompensationWeight, 0.0, 1.0)
		local nCompensatedPitchAngle		= nUpperBodyPitchAngle * nCompensatedPitchWeight
		local nCompensatedYawAngle			= nUpperBodyYawAngle * nCompensationWeight

		qCompensationTarget				= Quaternion.new(Vector3.new(nCompensatedPitchAngle, nCompensatedYawAngle, 0.0))
	end

	local qCompensationCurrent		= self._private.qUpperBodyCompensationCurrent or qIdentity
	local nCompensationBlendAlpha	= nDeltaTime and self:Clamp(nDeltaTime * self.nUpperBodyTargetCompensationSmoothSpeed, 0.0, 1.0) or 1.0

	self._private.qUpperBodyCompensationCurrent	= self:BlendQuaternion(qCompensationCurrent, qCompensationTarget, nCompensationBlendAlpha)
end

function PlayerArmIK:ResolveUpperBodyCompensatedTargetModelPosition(tChainPose, vTargetModelPosition)
	if not vTargetModelPosition or not tChainPose or not self.bEnableUpperBodyTargetCompensation then
		return vTargetModelPosition
	end

	local qUpperBodyCompensation	= self._private.qUpperBodyCompensationCurrent
	local tSpine2Pose				= tChainPose.sSpine2
	local vCompensationPivot		= tSpine2Pose and tSpine2Pose.vModelPosition or nil

	if not qUpperBodyCompensation or not vCompensationPivot then
		return vTargetModelPosition
	end

	local vPivotToTarget		= vTargetModelPosition - vCompensationPivot
	local nPivotToTargetLength	= vPivotToTarget:Length()

	if nPivotToTargetLength <= self.nIKEpsilon then
		return vTargetModelPosition
	end

	return vCompensationPivot + (qUpperBodyCompensation * vPivotToTarget)
end

function PlayerArmIK:ResolveSkinnedMeshRenderer()
	local sModelActorName		= self._private.sModelActorName
	local oModelActor			= self:FindActorByNameRecursive(self.owner, sModelActorName)
	local oSkinnedMeshRenderer	= oModelActor and oModelActor:GetSkinnedMeshRenderer() or nil

	return oSkinnedMeshRenderer or self:FindSkinnedMeshRendererRecursive(self.owner)
end

function PlayerArmIK:ResolveClassBehaviour()
	local oCurrentActor	= self.owner

	while oCurrentActor do
		local oClass	= oCurrentActor:GetBehaviour("Class")

		if oClass then
			return oClass.ResolveClassBehaviour and oClass.ResolveClassBehaviour(self.owner) or oClass
		end

		oCurrentActor	= oCurrentActor:GetParent()
	end

	return {}
end

function PlayerArmIK:ResolveModelTransform()
	local sModelActorName	= self._private.sModelActorName
	local oModelActor		= self:FindActorByNameRecursive(self.owner, sModelActorName)

	return oModelActor and oModelActor:GetTransform() or nil
end

function PlayerArmIK:ResolveBoneIndices(oSkinnedMeshRenderer)
	local tBoneIndices	= {}
	if not oSkinnedMeshRenderer then return tBoneIndices end

	for sBoneKey, sBoneName in pairs(tBoneNameByKey) do
		tBoneIndices[sBoneKey]	= oSkinnedMeshRenderer:GetBoneIndex(sBoneName)
	end

	return tBoneIndices
end

function PlayerArmIK:InitializeArmRuntime()
	local tArmRuntimeByName	= {}

	for _, tArmConfig in ipairs(tArmConfigs) do
		tArmRuntimeByName[tArmConfig.sName]	=
		{
			qShoulderLocalRotation	= nil,
			qUpperLocalRotation		= nil,
			qForeArmLocalRotation	= nil,
			qHandLocalRotation		= nil,
			vBendPlaneNormal		= nil,
			vHandErrorModel			= nil,
		}
	end

	self._private.tArmRuntimeByName	= tArmRuntimeByName
end

function PlayerArmIK:GetArmRuntime(tArmConfig)
	local tArmRuntimeByName	= self._private.tArmRuntimeByName
	local sArmName			= tArmConfig and tArmConfig.sName or nil
	local tArmRuntime		= sArmName and tArmRuntimeByName[sArmName] or nil

	if tArmRuntime then
		return tArmRuntime
	end

	tArmRuntime	=
	{
		qShoulderLocalRotation	= nil,
		qUpperLocalRotation		= nil,
		qForeArmLocalRotation	= nil,
		qHandLocalRotation		= nil,
		vBendPlaneNormal		= nil,
		vHandErrorModel			= nil,
	}

	if sArmName then
		tArmRuntimeByName[sArmName]	= tArmRuntime
	end

	return tArmRuntime
end

function PlayerArmIK:ResetArmRuntime(tArmConfig)
	local tArmRuntime	= self:GetArmRuntime(tArmConfig)

	tArmRuntime.qShoulderLocalRotation	= nil
	tArmRuntime.qUpperLocalRotation		= nil
	tArmRuntime.qForeArmLocalRotation	= nil
	tArmRuntime.qHandLocalRotation		= nil
	tArmRuntime.vBendPlaneNormal		= nil
	tArmRuntime.vHandErrorModel		= nil
end

function PlayerArmIK:ResetAllArmRuntime()
	for _, tArmConfig in ipairs(tArmConfigs) do
		self:ResetArmRuntime(tArmConfig)
	end
end

function PlayerArmIK:ResolveWeaponGripTargetsWorld(oWeapon)
	if not oWeapon then return nil end

	local oRightGripTransform	= oWeapon.GetHandRightTransform and oWeapon:GetHandRightTransform() or nil
	local oLeftGripTransform	= oWeapon.GetHandLeftTransform and oWeapon:GetHandLeftTransform() or nil
	local vRightGripWorld		= oRightGripTransform and oRightGripTransform:GetWorldPosition() or nil
	local vLeftGripWorld		= oLeftGripTransform and oLeftGripTransform:GetWorldPosition() or nil
	local qRightGripWorld		= oRightGripTransform and oRightGripTransform:GetWorldRotation() or nil
	local qLeftGripWorld		= oLeftGripTransform and oLeftGripTransform:GetWorldRotation() or nil

	if not vRightGripWorld and not vLeftGripWorld then
		return nil
	end

	return {
		sRightGrip	=
		{
			oTransform		= oRightGripTransform,
			vWorldPosition	= vRightGripWorld,
			qWorldRotation	= qRightGripWorld,
		},
		sLeftGrip	=
		{
			oTransform		= oLeftGripTransform,
			vWorldPosition	= vLeftGripWorld,
			qWorldRotation	= qLeftGripWorld,
		},
	}
end

function PlayerArmIK:WorldToModelPosition(oModelTransform, vWorldPosition)
	local vModelWorldPosition	= oModelTransform:GetWorldPosition()
	local qModelWorldRotation	= oModelTransform:GetWorldRotation()
	local qModelWorldInverse	= self:InverseQuaternion(qModelWorldRotation)
	local vWorldOffset			= vWorldPosition - vModelWorldPosition

	return qModelWorldInverse * vWorldOffset
end

function PlayerArmIK:ApplyTwoBoneArmIK(oSkinnedMeshRenderer, tArmConfig, vTargetModelPosition, tGripTarget, nDeltaTime)
	local tArmRuntime		= self:GetArmRuntime(tArmConfig)
	local tInitialChainPose	= self:BuildBoneChainPose(oSkinnedMeshRenderer, tArmConfig.tChainKeys)
	if not tInitialChainPose then return false end
	local vCompensatedTargetModelPosition	= self:ResolveUpperBodyCompensatedTargetModelPosition(tInitialChainPose, vTargetModelPosition)

	local tShoulderAdjustedPose	= self:ApplyShoulderAssist(oSkinnedMeshRenderer, tArmConfig, tInitialChainPose, vCompensatedTargetModelPosition, nDeltaTime, tArmRuntime)
	local tWorkingChainPose		= tShoulderAdjustedPose or tInitialChainPose

	local tArmPose		= tWorkingChainPose[tArmConfig.sArmKey]
	local tForeArmPose	= tWorkingChainPose[tArmConfig.sForeArmKey]
	local tHandPose		= tWorkingChainPose[tArmConfig.sHandKey]
	local tShoulderPose	= tWorkingChainPose[tArmConfig.sShoulderKey]

	if not tArmPose or not tForeArmPose or not tHandPose or not tShoulderPose then
		return false
	end

	local vArmPosition		= tArmPose.vModelPosition
	local vForeArmPosition	= tForeArmPose.vModelPosition
	local vHandPosition		= tHandPose.vModelPosition
	local vUpperSegment		= vForeArmPosition - vArmPosition
	local vLowerSegment		= vHandPosition - vForeArmPosition
	local nUpperLength		= vUpperSegment:Length()
	local nLowerLength		= vLowerSegment:Length()
	local nIKEpsilon		= self.nIKEpsilon

	if nUpperLength <= nIKEpsilon or nLowerLength <= nIKEpsilon then
		return false
	end

	local vArmToTarget			= vCompensatedTargetModelPosition - vArmPosition
	local nTargetDistanceRaw	= vArmToTarget:Length()

	if nTargetDistanceRaw <= nIKEpsilon then
		return false
	end

	local nReachMinRaw			= math.abs(nUpperLength - nLowerLength)
	local nReachMaxRaw			= nUpperLength + nLowerLength
	local nTargetMinDistance	= nReachMinRaw + self.nIKTargetMargin
	local nTargetMaxDistance	= nReachMaxRaw - self.nIKTargetMargin
	local bIsTargetRangeInvalid	= nTargetMinDistance > nTargetMaxDistance

	if bIsTargetRangeInvalid then
		local nMidReachDistance	= (nReachMinRaw + nReachMaxRaw) * 0.5

		nTargetMinDistance	= nMidReachDistance
		nTargetMaxDistance	= nMidReachDistance
	end
	local nTargetDistance		= self:Clamp(nTargetDistanceRaw, nTargetMinDistance, nTargetMaxDistance)
	local vTargetDirection		= vArmToTarget / nTargetDistanceRaw
	local vTargetClamped		= vArmPosition + (vTargetDirection * nTargetDistance)
	local nUpperDenominator		= 2.0 * nUpperLength * nTargetDistance
	local nUpperCosRaw			= nUpperDenominator > nIKEpsilon and ((nUpperLength * nUpperLength) + (nTargetDistance * nTargetDistance) - (nLowerLength * nLowerLength)) / nUpperDenominator or 1.0
	local nUpperCos				= self:Clamp(nUpperCosRaw, -1.0, 1.0)
	local nUpperProjection		= nUpperLength * nUpperCos
	local nUpperPerpendicularSq	= (nUpperLength * nUpperLength) - (nUpperProjection * nUpperProjection)
	local nUpperPerpendicular	= nUpperPerpendicularSq > 0.0 and math.sqrt(nUpperPerpendicularSq) or 0.0
	local nArmSideSign				= tArmConfig.sName == "RightArm" and -1.0 or 1.0
	local nElbowBendSign			= tArmConfig.nElbowBendSign or 1.0
	local vShoulderUp				= tShoulderPose.qModelRotation * Vector3.new(0, 1, 0)
	local vShoulderSide				= tShoulderPose.qModelRotation * Vector3.new(nArmSideSign, 0, 0)
	local vCurrentBendNormalRaw		= vUpperSegment:Cross(vLowerSegment) * nElbowBendSign
	local vFallbackPlaneNormalA		= vTargetDirection:Cross(vShoulderUp) * nElbowBendSign
	local vFallbackPlaneNormalB		= vTargetDirection:Cross(vShoulderSide) * nElbowBendSign
	local vFallbackPlaneNormal		= self:NormalizeVector3(vFallbackPlaneNormalA, vFallbackPlaneNormalB)
	local vBendPlaneNormal			= self:ResolveStableBendPlaneNormal(tArmRuntime, vCurrentBendNormalRaw, vFallbackPlaneNormal, nDeltaTime)
	local vFallbackBend				= (tArmPose.qModelRotation * Vector3.new(0, 1, 0)) * nElbowBendSign
	local vBendDirection			= self:NormalizeVector3(vBendPlaneNormal:Cross(vTargetDirection), vFallbackBend)
	local vElbowTargetPosition	= vArmPosition + (vTargetDirection * nUpperProjection) + (vBendDirection * nUpperPerpendicular)
	local vUpperCurrentDirection	= self:NormalizeVector3(vUpperSegment, vTargetDirection)
	local vUpperTargetDirection	= self:NormalizeVector3(vElbowTargetPosition - vArmPosition, vUpperCurrentDirection)
	local qUpperWorldDelta		= self:QuaternionFromTo(vUpperCurrentDirection, vUpperTargetDirection)
	local qUpperWorldTarget		= qUpperWorldDelta * tArmPose.qModelRotation
	local qShoulderWorldInverse	= self:InverseQuaternion(tShoulderPose.qModelRotation)
	local qUpperLocalTarget		= qShoulderWorldInverse * qUpperWorldTarget
	local nRotationAlpha		= self:Clamp(nDeltaTime * self.nIKRotationSmoothSpeed, 0.0, 1.0)
	local qUpperLocalCurrent	= tArmRuntime.qUpperLocalRotation or oSkinnedMeshRenderer:GetBoneLocalRotation(tArmPose.nBoneIndex)
	local qUpperLocalBlended	= qUpperLocalCurrent and self:BlendQuaternion(qUpperLocalCurrent, qUpperLocalTarget, nRotationAlpha) or qUpperLocalTarget

	oSkinnedMeshRenderer:SetBoneLocalRotation(tArmPose.nBoneIndex, qUpperLocalBlended)
	tArmRuntime.qUpperLocalRotation	= qUpperLocalBlended

	local tUpdatedChainPose		= self:BuildBoneChainPose(oSkinnedMeshRenderer, tArmConfig.tChainKeys)
	local tUpdatedForeArmPose	= tUpdatedChainPose and tUpdatedChainPose[tArmConfig.sForeArmKey] or nil
	local tUpdatedHandPose		= tUpdatedChainPose and tUpdatedChainPose[tArmConfig.sHandKey] or nil
	if not tUpdatedForeArmPose or not tUpdatedHandPose then
		return false
	end

	local vForeArmToHand		= tUpdatedHandPose.vModelPosition - tUpdatedForeArmPose.vModelPosition
	local vForeArmToTarget		= vTargetClamped - tUpdatedForeArmPose.vModelPosition
	local nForeArmToTargetLength	= vForeArmToTarget:Length()
	if nForeArmToTargetLength <= nIKEpsilon then
		self:SetArmRuntimeHandError(tArmRuntime, vTargetClamped - tUpdatedHandPose.vModelPosition)
		return true
	end

	local vForeArmCurrentDirection	= self:NormalizeVector3(vForeArmToHand, vTargetDirection)
	local vForeArmTargetDirection	= self:NormalizeVector3(vForeArmToTarget, vForeArmCurrentDirection)
	local qForeArmWorldDelta		= self:QuaternionFromTo(vForeArmCurrentDirection, vForeArmTargetDirection)
	local qForeArmWorldTarget		= qForeArmWorldDelta * tUpdatedForeArmPose.qModelRotation
	local qArmWorldInverse			= self:InverseQuaternion(tUpdatedChainPose[tArmConfig.sArmKey].qModelRotation)
	local qForeArmLocalTarget		= qArmWorldInverse * qForeArmWorldTarget
	local qForeArmLocalCurrent		= tArmRuntime.qForeArmLocalRotation or oSkinnedMeshRenderer:GetBoneLocalRotation(tUpdatedForeArmPose.nBoneIndex)
	local qForeArmLocalBlended		= qForeArmLocalCurrent and self:BlendQuaternion(qForeArmLocalCurrent, qForeArmLocalTarget, nRotationAlpha) or qForeArmLocalTarget

	oSkinnedMeshRenderer:SetBoneLocalRotation(tUpdatedForeArmPose.nBoneIndex, qForeArmLocalBlended)
	tArmRuntime.qForeArmLocalRotation	= qForeArmLocalBlended

	local tSolvedChainPose		= self:BuildBoneChainPose(oSkinnedMeshRenderer, tArmConfig.tChainKeys)
	tSolvedChainPose			= self:ApplyHandRotationAlignment(oSkinnedMeshRenderer, tArmConfig, tSolvedChainPose, tGripTarget, nDeltaTime, tArmRuntime) or tSolvedChainPose
	local tSolvedHandPose		= tSolvedChainPose and tSolvedChainPose[tArmConfig.sHandKey] or nil
	local vSolvedHandPosition	= tSolvedHandPose and tSolvedHandPose.vModelPosition or tUpdatedHandPose.vModelPosition

	self:SetArmRuntimeHandError(tArmRuntime, vTargetClamped - vSolvedHandPosition)

	return true
end

function PlayerArmIK:ApplyShoulderAssist(oSkinnedMeshRenderer, tArmConfig, tChainPose, vTargetModelPosition, nDeltaTime, tArmRuntime)
	if not self.bEnableShoulderAssist or not tChainPose then
		return tChainPose
	end

	local tShoulderPose		= tChainPose[tArmConfig.sShoulderKey]
	local tArmPose			= tChainPose[tArmConfig.sArmKey]

	if not tShoulderPose or not tArmPose then
		return tChainPose
	end

	local vShoulderToArm		= tArmPose.vModelPosition - tShoulderPose.vModelPosition
	local vShoulderToTarget		= vTargetModelPosition - tShoulderPose.vModelPosition
	local nShoulderToArmLength	= vShoulderToArm:Length()
	local nShoulderToTargetLength	= vShoulderToTarget:Length()

	if nShoulderToArmLength <= self.nIKEpsilon or nShoulderToTargetLength <= self.nIKEpsilon then
		return tChainPose
	end

	local qShoulderDelta		= self:QuaternionFromTo(vShoulderToArm, vShoulderToTarget)
	local nShoulderAssistMaxAngle	= self.nShoulderAssistMaxAngle or 0.0

	if nShoulderAssistMaxAngle > 0.0 then
		local nShoulderDeltaAngle	= self:GetQuaternionAngleDegrees(qShoulderDelta)

		if nShoulderDeltaAngle > nShoulderAssistMaxAngle then
			local nShoulderClampAlpha	= nShoulderAssistMaxAngle / nShoulderDeltaAngle

			qShoulderDelta	= self:BlendQuaternion(Quaternion.new(Vector3.new(0, 0, 0)), qShoulderDelta, nShoulderClampAlpha)
		end
	end

	local qShoulderWorldTarget	= qShoulderDelta * tShoulderPose.qModelRotation
	local qShoulderParentInverse	= self:InverseQuaternion(tShoulderPose.qParentRotation)
	local qShoulderLocalTarget	= qShoulderParentInverse * qShoulderWorldTarget
	local nProfileWeight		= self:ResolveWeaponShoulderAssistWeight(tArmConfig)
	local nShoulderWeight		= self:Clamp(self.nShoulderAssistWeight * nProfileWeight, 0.0, 1.0)
	local nShoulderAlpha		= self:Clamp(nDeltaTime * self.nShoulderAssistSmoothSpeed * nShoulderWeight, 0.0, 1.0)
	local qShoulderLocalCurrent	= tArmRuntime.qShoulderLocalRotation or oSkinnedMeshRenderer:GetBoneLocalRotation(tShoulderPose.nBoneIndex)
	local qShoulderLocalBlended	= qShoulderLocalCurrent and self:BlendQuaternion(qShoulderLocalCurrent, qShoulderLocalTarget, nShoulderAlpha) or qShoulderLocalTarget

	oSkinnedMeshRenderer:SetBoneLocalRotation(tShoulderPose.nBoneIndex, qShoulderLocalBlended)
	tArmRuntime.qShoulderLocalRotation	= qShoulderLocalBlended

	return self:BuildBoneChainPose(oSkinnedMeshRenderer, tArmConfig.tChainKeys)
end

function PlayerArmIK:ApplyHandRotationAlignment(oSkinnedMeshRenderer, tArmConfig, tChainPose, tGripTarget, nDeltaTime, tArmRuntime)
	if not self.bEnableHandRotationAlignment or not tChainPose or not tGripTarget then
		return tChainPose
	end

	local qGripWorldRotation	= tGripTarget.qWorldRotation
	local oModelTransform		= self._private.oModelTransform
	local tForeArmPose		= tChainPose[tArmConfig.sForeArmKey]
	local tHandPose			= tChainPose[tArmConfig.sHandKey]

	if not qGripWorldRotation or not oModelTransform or not tForeArmPose or not tHandPose then
		return tChainPose
	end

	local qModelWorldInverse	= self:InverseQuaternion(oModelTransform:GetWorldRotation())
	local qGripModelRotation	= qModelWorldInverse * qGripWorldRotation
	local qGripOffsetRotation	= self:ResolveWeaponGripOffsetRotation(tArmConfig)
	local qHandModelTarget		= qGripModelRotation * qGripOffsetRotation
	local qForeArmWorldInverse	= self:InverseQuaternion(tForeArmPose.qModelRotation)
	local qHandLocalTarget		= qForeArmWorldInverse * qHandModelTarget
	local nProfileHandWeight	= self:ResolveWeaponHandRotationWeight(tArmConfig)
	local nHandWeight		= self:Clamp(self.nHandRotationWeight * nProfileHandWeight, 0.0, 1.0)
	local nHandAlpha		= self:Clamp(nDeltaTime * self.nHandRotationSmoothSpeed * nHandWeight, 0.0, 1.0)
	local qHandLocalCurrent		= tArmRuntime.qHandLocalRotation or oSkinnedMeshRenderer:GetBoneLocalRotation(tHandPose.nBoneIndex)
	local qHandLocalBlended		= qHandLocalCurrent and self:BlendQuaternion(qHandLocalCurrent, qHandLocalTarget, nHandAlpha) or qHandLocalTarget

	oSkinnedMeshRenderer:SetBoneLocalRotation(tHandPose.nBoneIndex, qHandLocalBlended)
	tArmRuntime.qHandLocalRotation	= qHandLocalBlended

	return self:BuildBoneChainPose(oSkinnedMeshRenderer, tArmConfig.tChainKeys)
end

function PlayerArmIK:ResolveWeaponGripProfile()
	local oWeapon	= self._private.oCurrentWeapon

	return oWeapon and oWeapon.GetGripProfile and oWeapon:GetGripProfile() or nil
end

function PlayerArmIK:ResolveWeaponShoulderAssistWeight(tArmConfig)
	local oGripProfile	= self:ResolveWeaponGripProfile()
	local nWeight		= oGripProfile and oGripProfile.GetShoulderAssistWeight and oGripProfile:GetShoulderAssistWeight(tArmConfig.sName) or 1.0

	return nWeight or 1.0
end

function PlayerArmIK:ResolveWeaponHandRotationWeight(tArmConfig)
	local oGripProfile	= self:ResolveWeaponGripProfile()
	local nWeight		= oGripProfile and oGripProfile.GetHandRotationWeight and oGripProfile:GetHandRotationWeight(tArmConfig.sName) or 1.0

	return nWeight or 1.0
end

function PlayerArmIK:ResolveWeaponGripOffsetRotation(tArmConfig)
	local oGripProfile	= self:ResolveWeaponGripProfile()
	local qProfileOffset	= oGripProfile and oGripProfile.GetGripOffsetRotation and oGripProfile:GetGripOffsetRotation(tArmConfig.sName) or nil

	return qProfileOffset or Quaternion.new(Vector3.new(tArmConfig.nDefaultGripOffsetX or 0.0, tArmConfig.nDefaultGripOffsetY or 0.0, tArmConfig.nDefaultGripOffsetZ or 0.0))
end

function PlayerArmIK:SetArmRuntimeHandError(tArmRuntime, vHandErrorModel)
	if not tArmRuntime then
		return
	end

	tArmRuntime.vHandErrorModel	= vHandErrorModel
end

function PlayerArmIK:ResolveWeaponYawAssistDeltaDegrees(oWeapon, oSkinnedMeshRenderer, oModelTransform, tGripTargetsWorld)
	if not self.bEnableWeaponYawAssist or not oWeapon or not oSkinnedMeshRenderer or not oModelTransform or not tGripTargetsWorld then
		return nil
	end

	local tRightGripTarget	= tGripTargetsWorld.sRightGrip
	local tLeftGripTarget	= tGripTargetsWorld.sLeftGrip
	local vRightGripWorld	= tRightGripTarget and tRightGripTarget.vWorldPosition or nil
	local vLeftGripWorld	= tLeftGripTarget and tLeftGripTarget.vWorldPosition or nil

	if not vRightGripWorld or not vLeftGripWorld then
		return nil
	end

	local tRightChainPose	= self:BuildBoneChainPose(oSkinnedMeshRenderer, tArmConfigs[1].tChainKeys)
	local tLeftChainPose	= self:BuildBoneChainPose(oSkinnedMeshRenderer, tArmConfigs[2].tChainKeys)
	local tRightHandPose	= tRightChainPose and tRightChainPose[tArmConfigs[1].sHandKey] or nil
	local tLeftHandPose	= tLeftChainPose and tLeftChainPose[tArmConfigs[2].sHandKey] or nil

	if not tRightHandPose or not tLeftHandPose then
		return nil
	end

	local vRightGripModel	= self:WorldToModelPosition(oModelTransform, vRightGripWorld)
	local vLeftGripModel	= self:WorldToModelPosition(oModelTransform, vLeftGripWorld)
	local vHandsAxisModel	= tLeftHandPose.vModelPosition - tRightHandPose.vModelPosition
	local vGripsAxisModel	= vLeftGripModel - vRightGripModel
	local vHandsAxisFlat	= Vector3.new(vHandsAxisModel.x, 0.0, vHandsAxisModel.z)
	local vGripsAxisFlat	= Vector3.new(vGripsAxisModel.x, 0.0, vGripsAxisModel.z)
	local nHandsAxisFlatLengthSq	= vHandsAxisFlat:Dot(vHandsAxisFlat)
	local nGripsAxisFlatLengthSq	= vGripsAxisFlat:Dot(vGripsAxisFlat)

	if nHandsAxisFlatLengthSq <= self.nIKEpsilon or nGripsAxisFlatLengthSq <= self.nIKEpsilon then
		return nil
	end

	local vHandsAxisFlatNormal	= vHandsAxisFlat / math.sqrt(nHandsAxisFlatLengthSq)
	local vGripsAxisFlatNormal	= vGripsAxisFlat / math.sqrt(nGripsAxisFlatLengthSq)
	local nDot			= self:Clamp(vGripsAxisFlatNormal:Dot(vHandsAxisFlatNormal), -1.0, 1.0)
	local nCrossY		= (vGripsAxisFlatNormal.z * vHandsAxisFlatNormal.x) - (vGripsAxisFlatNormal.x * vHandsAxisFlatNormal.z)
	local fAtan2		= math.atan2
	local nSignedDeltaRadians	= 0.0

	if fAtan2 then
		nSignedDeltaRadians	= fAtan2(nCrossY, nDot)
	else
		local nUnsignedDeltaRadians	= math.acos(nDot)
		nSignedDeltaRadians	= nCrossY < 0.0 and -nUnsignedDeltaRadians or nUnsignedDeltaRadians
	end

	local nAssistGain		= self.nWeaponYawAssistGain or 1.0
	local nSignedDeltaDegrees	= math.deg(nSignedDeltaRadians) * self.nWeaponYawAssistSign * nAssistGain

	if math.abs(nSignedDeltaDegrees) <= self.nWeaponYawAssistAngleDeadZone then
		return 0.0
	end

	return nSignedDeltaDegrees
end

function PlayerArmIK:UpdateWeaponYawAssist(oWeapon, oSkinnedMeshRenderer, oModelTransform, nDeltaTime, tGripTargetsWorld)
	if not self.bEnableWeaponYawAssist then
		self._private.nWeaponYawAssistCurrent	= 0.0
		self._private.oWeaponYawAssistLastWeapon	= oWeapon

		if oWeapon then
			if oWeapon.SetDynamicYawOffsetY then
				oWeapon:SetDynamicYawOffsetY(0.0)
			elseif oWeapon.ResetDynamicYawOffsetY then
				oWeapon:ResetDynamicYawOffsetY()
			end

			if oWeapon.ApplyEquipOffset then
				oWeapon:ApplyEquipOffset()
			end
		end

		return
	end

	local nCurrentYawOffset	= self._private.nWeaponYawAssistCurrent or 0.0
	local oLastWeapon		= self._private.oWeaponYawAssistLastWeapon

	if oWeapon ~= oLastWeapon then
		nCurrentYawOffset	= 0.0
	end

	local nYawDeltaDegrees	= self:ResolveWeaponYawAssistDeltaDegrees(oWeapon, oSkinnedMeshRenderer, oModelTransform, tGripTargetsWorld)
	local nMaxYawOffset		= self.nWeaponYawAssistMaxOffset
	local nYawStepMax		= self.nWeaponYawAssistSpeed * nDeltaTime

	if nYawDeltaDegrees then
		local nYawStep	= self:Clamp(nYawDeltaDegrees, -nYawStepMax, nYawStepMax)

		nCurrentYawOffset	= self:Clamp(nCurrentYawOffset + nYawStep, -nMaxYawOffset, nMaxYawOffset)
	else
		local nReturnAlpha	= self:Clamp(nDeltaTime * self.nWeaponYawAssistReturnSpeed, 0.0, 1.0)

		nCurrentYawOffset	= nCurrentYawOffset + ((0.0 - nCurrentYawOffset) * nReturnAlpha)
	end

	self._private.nWeaponYawAssistCurrent	= nCurrentYawOffset
	self._private.oWeaponYawAssistLastWeapon	= oWeapon

	if oWeapon then
		if oWeapon.SetDynamicYawOffsetY then
			oWeapon:SetDynamicYawOffsetY(nCurrentYawOffset)
		elseif oWeapon.ResetDynamicYawOffsetY then
			oWeapon:ResetDynamicYawOffsetY()
		end

		if oWeapon.ApplyEquipOffset then
			oWeapon:ApplyEquipOffset()
		end
	end
end

function PlayerArmIK:BuildBoneChainPose(oSkinnedMeshRenderer, tChainKeys)
	local tBoneIndices		= self._private.tBoneIndices
	local vAccumPosition	= Vector3.new(0, 0, 0)
	local qAccumRotation	= Quaternion.new(Vector3.new(0, 0, 0))
	local tChainPose		= {}

	for _, sBoneKey in ipairs(tChainKeys) do
		local nBoneIndex		= tBoneIndices[sBoneKey]
		local vBoneLocalPosition	= nBoneIndex and oSkinnedMeshRenderer:GetBoneLocalPosition(nBoneIndex) or nil
		local qBoneLocalRotation	= nBoneIndex and oSkinnedMeshRenderer:GetBoneLocalRotation(nBoneIndex) or nil

		if not nBoneIndex or not vBoneLocalPosition or not qBoneLocalRotation then
			if self.bEnableIKLogs then
				Debug.LogWarning("PlayerArmIK: missing bone data for key '" .. sBoneKey .. "'")
			end

			return nil
		end

		local qParentRotation	= qAccumRotation

		vAccumPosition	= vAccumPosition + (qAccumRotation * vBoneLocalPosition)
		qAccumRotation	= qAccumRotation * qBoneLocalRotation

		tChainPose[sBoneKey]	=
		{
			nBoneIndex		= nBoneIndex,
			vLocalPosition	= vBoneLocalPosition,
			qLocalRotation	= qBoneLocalRotation,
			vModelPosition	= vAccumPosition,
			qModelRotation	= qAccumRotation,
			qParentRotation	= qParentRotation,
		}
	end

	return tChainPose
end

function PlayerArmIK:ResolveStableBendPlaneNormal(tArmRuntime, vCurrentBendNormalRaw, vFallbackPlaneNormal, nDeltaTime)
	local vCurrentBendNormal	= self:NormalizeVector3(vCurrentBendNormalRaw, vFallbackPlaneNormal)
	local vCachedBendNormal		= tArmRuntime and tArmRuntime.vBendPlaneNormal or nil

	if not vCachedBendNormal then
		if tArmRuntime then
			tArmRuntime.vBendPlaneNormal	= vCurrentBendNormal
		end

		return vCurrentBendNormal
	end

	local nConsistencyDot			= vCachedBendNormal:Dot(vCurrentBendNormal)
	local vConsistentCurrentNormal	= nConsistencyDot < 0.0 and (vCurrentBendNormal * -1.0) or vCurrentBendNormal
	local nBendNormalAlpha			= self:Clamp(nDeltaTime * self.nIKBendNormalSmoothSpeed, 0.0, 1.0)
	local nCachedWeight				= 1.0 - nBendNormalAlpha
	local nCurrentWeight			= nBendNormalAlpha
	local vBlendedNormal			= self:NormalizeVector3(
		(vCachedBendNormal * nCachedWeight) + (vConsistentCurrentNormal * nCurrentWeight),
		vConsistentCurrentNormal
	)

	if tArmRuntime then
		tArmRuntime.vBendPlaneNormal	= vBlendedNormal
	end

	return vBlendedNormal
end

function PlayerArmIK:NormalizeVector3(vValue, vFallback)
	local nLength	= vValue and vValue:Length() or 0.0

	if nLength > self.nIKEpsilon then
		return vValue / nLength
	end

	local nFallbackLength	= vFallback and vFallback:Length() or 0.0

	if nFallbackLength > self.nIKEpsilon then
		return vFallback / nFallbackLength
	end

	return Vector3.new(0, 0, 1)
end

function PlayerArmIK:NormalizeQuaternion(qValue)
	if not qValue then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	local nLengthSq	= (qValue.x * qValue.x) + (qValue.y * qValue.y) + (qValue.z * qValue.z) + (qValue.w * qValue.w)

	if nLengthSq <= self.nIKEpsilon then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	local nInvLength	= 1.0 / math.sqrt(nLengthSq)

	return Quaternion.new(qValue.x * nInvLength, qValue.y * nInvLength, qValue.z * nInvLength, qValue.w * nInvLength)
end

function PlayerArmIK:InverseQuaternion(qValue)
	if not qValue then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	local nLengthSq	= (qValue.x * qValue.x) + (qValue.y * qValue.y) + (qValue.z * qValue.z) + (qValue.w * qValue.w)

	if nLengthSq <= self.nIKEpsilon then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	local nInvLengthSq	= 1.0 / nLengthSq

	return Quaternion.new(-qValue.x * nInvLengthSq, -qValue.y * nInvLengthSq, -qValue.z * nInvLengthSq, qValue.w * nInvLengthSq)
end

function PlayerArmIK:QuaternionFromTo(vFromDirection, vToDirection)
	local vFrom	= self:NormalizeVector3(vFromDirection, Vector3.new(0, 0, 1))
	local vTo	= self:NormalizeVector3(vToDirection, vFrom)
	local nDot	= self:Clamp(vFrom:Dot(vTo), -1.0, 1.0)

	if nDot >= 0.9999 then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	if nDot <= -0.9999 then
		local nAbsX				= math.abs(vFrom.x)
		local vReferenceAxis	= nAbsX < 0.9 and Vector3.new(1, 0, 0) or Vector3.new(0, 1, 0)
		local vOppositeAxis		= self:NormalizeVector3(vFrom:Cross(vReferenceAxis), Vector3.new(0, 0, 1))

		return Quaternion.new(vOppositeAxis.x, vOppositeAxis.y, vOppositeAxis.z, 0.0)
	end

	local vCross	= vFrom:Cross(vTo)
	local qDelta	= Quaternion.new(vCross.x, vCross.y, vCross.z, 1.0 + nDot)

	return self:NormalizeQuaternion(qDelta)
end

function PlayerArmIK:GetQuaternionAngleDegrees(qValue)
	local qNormalized	= self:NormalizeQuaternion(qValue)
	local nClampedW		= self:Clamp(qNormalized.w, -1.0, 1.0)
	local nAngleRadians	= 2.0 * math.acos(nClampedW)

	return math.deg(nAngleRadians)
end

function PlayerArmIK:BlendQuaternion(qFrom, qTo, nAlpha)
	local nClampedAlpha	= self:Clamp(nAlpha, 0.0, 1.0)
	local qSafeFrom		= self:NormalizeQuaternion(qFrom)
	local qSafeTo		= self:NormalizeQuaternion(qTo)
	local nDot			= (qSafeFrom.x * qSafeTo.x) + (qSafeFrom.y * qSafeTo.y) + (qSafeFrom.z * qSafeTo.z) + (qSafeFrom.w * qSafeTo.w)
	local qAdjustedTo	= nDot < 0.0 and Quaternion.new(-qSafeTo.x, -qSafeTo.y, -qSafeTo.z, -qSafeTo.w) or qSafeTo
	local nFromWeight	= 1.0 - nClampedAlpha
	local nToWeight		= nClampedAlpha
	local qBlended		= Quaternion.new(
		(qSafeFrom.x * nFromWeight) + (qAdjustedTo.x * nToWeight),
		(qSafeFrom.y * nFromWeight) + (qAdjustedTo.y * nToWeight),
		(qSafeFrom.z * nFromWeight) + (qAdjustedTo.z * nToWeight),
		(qSafeFrom.w * nFromWeight) + (qAdjustedTo.w * nToWeight)
	)

	return self:NormalizeQuaternion(qBlended)
end

return PlayerArmIK
