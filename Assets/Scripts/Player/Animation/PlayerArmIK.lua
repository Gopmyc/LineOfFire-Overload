---@class PlayerArmIK : Behaviour
local PlayerArmIK	=
{
	bEnableIK				= true,
	nIKRotationSmoothSpeed	= 20.0,
	nIKTargetMargin			= 0.02,
	nIKEpsilon				= 0.0001,
	bEnableIKLogs			= false,

	_private	=
	{
		sModelActorName		= "Player Model",
		oSkinnedMeshRenderer	= nil,
		oModelTransform		= nil,
		oWeaponHolder		= nil,
		tBoneIndices		= {},
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
		tChainKeys		= { "sHips", "sSpine", "sSpine1", "sSpine2", "sRightShoulder", "sRightArm", "sRightForeArm", "sRightHand" },
	},
	{
		sName			= "LeftArm",
		sShoulderKey	= "sLeftShoulder",
		sArmKey			= "sLeftArm",
		sForeArmKey		= "sLeftForeArm",
		sHandKey		= "sLeftHand",
		sWeaponGripKey	= "sLeftGrip",
		tChainKeys		= { "sHips", "sSpine", "sSpine1", "sSpine2", "sLeftShoulder", "sLeftArm", "sLeftForeArm", "sLeftHand" },
	},
}

function PlayerArmIK:OnAwake()
	self								= setmetatable(self, self.owner:GetBehaviour("Class"))
	self._private.oSkinnedMeshRenderer	= self:ResolveSkinnedMeshRenderer()
	self._private.oModelTransform		= self:ResolveModelTransform()
	self._private.oWeaponHolder			= self.owner:GetBehaviour("WeaponHolder")
	self._private.tBoneIndices			= self:ResolveBoneIndices(self._private.oSkinnedMeshRenderer)
end

function PlayerArmIK:OnLateUpdate(nDeltaTime)
	if not self.bEnableIK then return end

	local oSkinnedMeshRenderer	= self._private.oSkinnedMeshRenderer
	local oModelTransform		= self._private.oModelTransform
	local oWeaponHolder			= self._private.oWeaponHolder

	if not oSkinnedMeshRenderer or not oModelTransform or not oWeaponHolder then return end

	local tGripTargetsWorld	= self:ResolveWeaponGripTargetsWorld(oWeaponHolder)
	if not tGripTargetsWorld then return end

	for _, tArmConfig in ipairs(tArmConfigs) do
		local sWeaponGripKey	= tArmConfig.sWeaponGripKey
		local vGripWorld		= tGripTargetsWorld[sWeaponGripKey]
		local vGripModel		= vGripWorld and self:WorldToModelPosition(oModelTransform, vGripWorld) or nil

		if vGripModel then
			self:ApplyTwoBoneArmIK(oSkinnedMeshRenderer, tArmConfig, vGripModel, nDeltaTime)
		end
	end
end

function PlayerArmIK:ResolveSkinnedMeshRenderer()
	local sModelActorName		= self._private.sModelActorName
	local oModelActor			= self:FindActorByNameRecursive(self.owner, sModelActorName)
	local oSkinnedMeshRenderer	= oModelActor and oModelActor:GetSkinnedMeshRenderer() or nil

	return oSkinnedMeshRenderer or self:FindSkinnedMeshRendererRecursive(self.owner)
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

function PlayerArmIK:ResolveWeaponGripTargetsWorld(oWeaponHolder)
	local oWeapon	= oWeaponHolder and oWeaponHolder.GetEquippedWeapon and oWeaponHolder:GetEquippedWeapon() or nil
	if not oWeapon then return nil end

	local oRightGripTransform	= oWeapon.GetHandRightTransform and oWeapon:GetHandRightTransform() or nil
	local oLeftGripTransform	= oWeapon.GetHandLeftTransform and oWeapon:GetHandLeftTransform() or nil
	local vRightGripWorld		= oRightGripTransform and oRightGripTransform:GetWorldPosition() or nil
	local vLeftGripWorld		= oLeftGripTransform and oLeftGripTransform:GetWorldPosition() or nil

	if not vRightGripWorld and not vLeftGripWorld then
		return nil
	end

	return {
		sRightGrip	= vRightGripWorld,
		sLeftGrip	= vLeftGripWorld,
	}
end

function PlayerArmIK:WorldToModelPosition(oModelTransform, vWorldPosition)
	local vModelWorldPosition	= oModelTransform:GetWorldPosition()
	local qModelWorldRotation	= oModelTransform:GetWorldRotation()
	local qModelWorldInverse	= self:InverseQuaternion(qModelWorldRotation)
	local vWorldOffset			= vWorldPosition - vModelWorldPosition

	return qModelWorldInverse * vWorldOffset
end

function PlayerArmIK:ApplyTwoBoneArmIK(oSkinnedMeshRenderer, tArmConfig, vTargetModelPosition, nDeltaTime)
	local tInitialChainPose	= self:BuildBoneChainPose(oSkinnedMeshRenderer, tArmConfig.tChainKeys)
	if not tInitialChainPose then return false end

	local tArmPose		= tInitialChainPose[tArmConfig.sArmKey]
	local tForeArmPose	= tInitialChainPose[tArmConfig.sForeArmKey]
	local tHandPose		= tInitialChainPose[tArmConfig.sHandKey]
	local tShoulderPose	= tInitialChainPose[tArmConfig.sShoulderKey]

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

	local vArmToTarget			= vTargetModelPosition - vArmPosition
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
	local vCurrentBend			= vForeArmPosition - vArmPosition
	local vProjectedBend		= vCurrentBend - (vTargetDirection * vCurrentBend:Dot(vTargetDirection))
	local vFallbackBend			= tArmPose.qModelRotation * Vector3.new(0, 1, 0)
	local vBendDirection		= self:NormalizeVector3(vProjectedBend, vFallbackBend)
	local vElbowTargetPosition	= vArmPosition + (vTargetDirection * nUpperProjection) + (vBendDirection * nUpperPerpendicular)
	local vUpperCurrentDirection	= self:NormalizeVector3(vUpperSegment, vTargetDirection)
	local vUpperTargetDirection	= self:NormalizeVector3(vElbowTargetPosition - vArmPosition, vUpperCurrentDirection)
	local qUpperWorldDelta		= self:QuaternionFromTo(vUpperCurrentDirection, vUpperTargetDirection)
	local qUpperWorldTarget		= qUpperWorldDelta * tArmPose.qModelRotation
	local qShoulderWorldInverse	= self:InverseQuaternion(tShoulderPose.qModelRotation)
	local qUpperLocalTarget		= qShoulderWorldInverse * qUpperWorldTarget
	local nRotationAlpha		= self:Clamp(nDeltaTime * self.nIKRotationSmoothSpeed, 0.0, 1.0)
	local qUpperLocalCurrent	= oSkinnedMeshRenderer:GetBoneLocalRotation(tArmPose.nBoneIndex)
	local qUpperLocalBlended	= qUpperLocalCurrent and self:BlendQuaternion(qUpperLocalCurrent, qUpperLocalTarget, nRotationAlpha) or qUpperLocalTarget

	oSkinnedMeshRenderer:SetBoneLocalRotation(tArmPose.nBoneIndex, qUpperLocalBlended)

	local tUpdatedChainPose		= self:BuildBoneChainPose(oSkinnedMeshRenderer, tArmConfig.tChainKeys)
	local tUpdatedForeArmPose	= tUpdatedChainPose and tUpdatedChainPose[tArmConfig.sForeArmKey] or nil
	local tUpdatedHandPose		= tUpdatedChainPose and tUpdatedChainPose[tArmConfig.sHandKey] or nil
	if not tUpdatedForeArmPose or not tUpdatedHandPose then
		return false
	end

	local vForeArmToHand		= tUpdatedHandPose.vModelPosition - tUpdatedForeArmPose.vModelPosition
	local vForeArmToTarget		= vTargetClamped - tUpdatedForeArmPose.vModelPosition
	local nForeArmToTargetLength	= vForeArmToTarget:Length()
	if nForeArmToTargetLength <= nIKEpsilon then return true end

	local vForeArmCurrentDirection	= self:NormalizeVector3(vForeArmToHand, vTargetDirection)
	local vForeArmTargetDirection	= self:NormalizeVector3(vForeArmToTarget, vForeArmCurrentDirection)
	local qForeArmWorldDelta		= self:QuaternionFromTo(vForeArmCurrentDirection, vForeArmTargetDirection)
	local qForeArmWorldTarget		= qForeArmWorldDelta * tUpdatedForeArmPose.qModelRotation
	local qArmWorldInverse			= self:InverseQuaternion(tUpdatedChainPose[tArmConfig.sArmKey].qModelRotation)
	local qForeArmLocalTarget		= qArmWorldInverse * qForeArmWorldTarget
	local qForeArmLocalCurrent		= oSkinnedMeshRenderer:GetBoneLocalRotation(tUpdatedForeArmPose.nBoneIndex)
	local qForeArmLocalBlended		= qForeArmLocalCurrent and self:BlendQuaternion(qForeArmLocalCurrent, qForeArmLocalTarget, nRotationAlpha) or qForeArmLocalTarget

	oSkinnedMeshRenderer:SetBoneLocalRotation(tUpdatedForeArmPose.nBoneIndex, qForeArmLocalBlended)

	return true
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
