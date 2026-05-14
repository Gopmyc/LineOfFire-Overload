---@class WeaponHolder : Behaviour
local WeaponHolder	=
{
	oDefaultWeaponActor			= Actor(),
	sDefaultWeaponActorName		= "Sopmod_Block3",
	sWeaponSocketActorName		= "WeaponSocket",
	sWeaponSocketParentActorName	= "Player Model",
	bOverrideSocketLocalPose	= true,
	nSocketLocalPositionX		= 0,
	nSocketLocalPositionY		= 4.3,
	nSocketLocalPositionZ		= 1.2,
	nSocketLocalRotationX		= 0.0,
	nSocketLocalRotationY		= 0.0,
	nSocketLocalRotationZ		= 0.0,
	bFollowUpperBodyYawYOnly	= true,
	bUseTorsoAimDirectSocketRotation	= true,
	bEnableUpperBodySocketSync	= false,
	nUpperBodySocketYawWeight	= 1.0,
	nUpperBodySocketPitchWeight	= 0.0,
	nUpperBodySocketSmoothSpeed	= 14.0,
	nUpperBodySocketMaxYawAngle	= 0.0,
	nUpperBodySocketMaxPitchAngle	= 0.0,
	bEnableViewPitchSocketSync	= true,
	nViewPitchSocketWeight		= 0.65,
	nViewPitchSocketMaxAngle	= 38.0,
	bEnableSocketPitchPositionCompensation	= true,
	nSocketPitchPositionWeight	= 1.0,
	nSocketPitchPositionOffsetPerDegreeX	= 0.0,
	nSocketPitchPositionOffsetPerDegreeY	= -0.0065,
	nSocketPitchPositionOffsetPerDegreeZ	= -0.0055,
	nSocketPitchPositionDownMultiplier	= 1.75,
	nSocketPitchPositionUpMultiplier	= 1.0,
	sPlayerCameraActorName		= "Player Camera",
	bEnableAimDownSights		= true,
	nAimMouseButton			= MouseButton.BUTTON_RIGHT,
	nAimEnterSpeed			= 16.0,
	nAimExitSpeed			= 12.0,
	nAimSocketBlendWeight		= 1.0,
	nAimSocketCameraOffsetX		= -0.2,
	nAimSocketCameraOffsetY		= -0.8,
	nAimSocketCameraOffsetZ		= 1,
	nAimSocketRotationPitch		= -0.8,
	nAimSocketRotationYaw		= 0.0,
	nAimSocketRotationRoll		= 0.0,
	bEquipOnStart				= true,
	bEnableWeaponLogs			= true,

	_private	=
	{
		oPlayerActor				= nil,
		oSocketActor				= nil,
		oSocketTransform			= nil,
		oEquippedWeaponActor		= nil,
		oEquippedWeapon				= nil,
		oHeadLook					= nil,
		oView						= nil,
		oCameraTransform			= nil,
		vSocketBaseLocalPosition	= nil,
		qSocketBaseLocalRotation	= nil,
		vSocketHipLocalPosition		= nil,
		qSocketHipLocalRotation		= nil,
		nSocketUpperBodyPitchAngle	= 0.0,
		nSocketUpperBodyYawAngle	= 0.0,
		nAimAlpha				= 0.0,
		bIsAimingDownSights		= false,
		bDidLogMissingSocket		= false,
	}
}

function WeaponHolder:OnAwake()
	self									= setmetatable(self, self.owner:GetBehaviour("Class"))
	self._private.oPlayerActor				= self.owner:GetParent() or self.owner
	self._private.oSocketActor				= self:ResolveActor(self.sWeaponSocketActorName)
	self._private.oSocketTransform			= self._private.oSocketActor and self._private.oSocketActor:GetTransform() or nil
	self._private.oHeadLook					= self.owner:GetBehaviour("PlayerHeadLook") or self:FindBehaviourInParents(self.owner, "PlayerHeadLook")
	self._private.oView						= self.owner:GetBehaviour("View") or self:FindBehaviourInParents(self.owner, "View")
	self._private.oCameraTransform			= self:ResolveCameraTransform()

	self:EnsureSocketParent()
	self:ApplySocketLocalPose()
	self:CacheSocketBaseLocalPosition()
	self:CacheSocketBaseLocalRotation()
	self:ValidateRequiredActors()
end

function WeaponHolder:OnStart()
	if self.bEquipOnStart then
		self:TryEquipDefaultWeapon()
	end
end

function WeaponHolder:OnLateUpdate(nDeltaTime)
	self:UpdateSocketUpperBodySync(nDeltaTime)
	self:UpdateAimDownSights(nDeltaTime)
	self:UpdateEquippedWeaponPose(nDeltaTime)
end

function WeaponHolder:ResolveActor(sActorName)
	if not sActorName or sActorName == "" then
		return nil
	end

	local oPlayerActor	= self._private.oPlayerActor
	local oActor		= oPlayerActor and self:FindActorByNameRecursive(oPlayerActor, sActorName) or nil

	if oActor then
		return oActor
	end

	local oScene	= Scenes.GetCurrentScene()

	return oScene and oScene:FindActorByName(sActorName) or nil
end

function WeaponHolder:ValidateRequiredActors()
	if not self._private.oSocketTransform and not self._private.bDidLogMissingSocket then
		Debug.LogError("WeaponHolder: missing weapon socket '" .. self.sWeaponSocketActorName .. "'")
		self._private.bDidLogMissingSocket	= true
	end
end

function WeaponHolder:ApplySocketLocalPose()
	if not self.bOverrideSocketLocalPose then
		return false
	end

	local oSocketTransform	= self._private.oSocketTransform

	if not oSocketTransform then
		return false
	end

	local vSocketLocalPosition	= Vector3.new(self.nSocketLocalPositionX, self.nSocketLocalPositionY, self.nSocketLocalPositionZ)
	local qSocketLocalRotation	= Quaternion.new(Vector3.new(self.nSocketLocalRotationX, self.nSocketLocalRotationY, self.nSocketLocalRotationZ))

	oSocketTransform:SetLocalPosition(vSocketLocalPosition)
	oSocketTransform:SetLocalRotation(qSocketLocalRotation)

	return true
end

function WeaponHolder:CacheSocketBaseLocalRotation()
	local oSocketTransform	= self._private.oSocketTransform

	if not oSocketTransform then
		self._private.qSocketBaseLocalRotation	= nil
		return nil
	end

	local qSocketBaseLocalRotation	= oSocketTransform:GetLocalRotation()

	self._private.qSocketBaseLocalRotation	= qSocketBaseLocalRotation

	return qSocketBaseLocalRotation
end

function WeaponHolder:CacheSocketBaseLocalPosition()
	local oSocketTransform	= self._private.oSocketTransform

	if not oSocketTransform then
		self._private.vSocketBaseLocalPosition	= nil
		return nil
	end

	local vSocketBaseLocalPosition	= oSocketTransform:GetLocalPosition()

	self._private.vSocketBaseLocalPosition	= vSocketBaseLocalPosition

	return vSocketBaseLocalPosition
end

function WeaponHolder:UpdateSocketUpperBodySync(nDeltaTime)
	local oSocketTransform				= self._private.oSocketTransform
	local bEnableUpperBodySocketSync	= self.bEnableUpperBodySocketSync
	local bEnableViewPitchSocketSync	= self.bEnableViewPitchSocketSync

	if not oSocketTransform then
		return false
	end

	if not bEnableUpperBodySocketSync and not bEnableViewPitchSocketSync then
		local qSocketBaseLocalRotation	= self._private.qSocketBaseLocalRotation or self:CacheSocketBaseLocalRotation()
		local vSocketBaseLocalPosition	= self._private.vSocketBaseLocalPosition or self:CacheSocketBaseLocalPosition()

		self._private.nSocketUpperBodyPitchAngle	= 0.0
		self._private.nSocketUpperBodyYawAngle		= 0.0

		if qSocketBaseLocalRotation then
			oSocketTransform:SetLocalRotation(qSocketBaseLocalRotation)
			self._private.qSocketHipLocalRotation	= qSocketBaseLocalRotation
		end

		if vSocketBaseLocalPosition then
			oSocketTransform:SetLocalPosition(vSocketBaseLocalPosition)
			self._private.vSocketHipLocalPosition	= vSocketBaseLocalPosition
		end

		return true
	end

	local nSocketTargetPitchAngle		= 0.0
	local nSocketTargetYawAngle			= 0.0
	local nProfileSocketPitchWeight		= self:ResolveSocketUpperBodyPitchProfileWeight()
	local nProfileSocketYawWeight		= self:ResolveSocketUpperBodyYawProfileWeight()
	local nMaxPitchAngle				= self.nUpperBodySocketMaxPitchAngle or 0.0
	local nMaxYawAngle					= self.nUpperBodySocketMaxYawAngle or 0.0
	local nViewPitchAngle				= 0.0

	if bEnableUpperBodySocketSync then
		local oHeadLook					= self._private.oHeadLook

		if not oHeadLook then
			oHeadLook					= self.owner:GetBehaviour("PlayerHeadLook") or self:FindBehaviourInParents(self.owner, "PlayerHeadLook")
			self._private.oHeadLook		= oHeadLook
		end

		local bCanSyncSocketWithHeadLook	= oHeadLook and oHeadLook.GetUpperBodyAimOffsetAngles

		if bCanSyncSocketWithHeadLook then
			local nUpperBodyPitchAngle, nUpperBodyYawAngle	= oHeadLook:GetUpperBodyAimOffsetAngles()
			local bFollowUpperBodyYawYOnly	= self.bFollowUpperBodyYawYOnly
			local nSocketPitchWeight	= (self.nUpperBodySocketPitchWeight or 0.0) * nProfileSocketPitchWeight
			local nSocketYawWeight		= (self.nUpperBodySocketYawWeight or 0.0) * nProfileSocketYawWeight
			local nWeightedPitchAngle	= bFollowUpperBodyYawYOnly and 0.0 or (nUpperBodyPitchAngle * nSocketPitchWeight)
			local nWeightedYawAngle		= nUpperBodyYawAngle * nSocketYawWeight

			nSocketTargetPitchAngle	= nMaxPitchAngle > 0.0 and self:Clamp(nWeightedPitchAngle, -nMaxPitchAngle, nMaxPitchAngle) or nWeightedPitchAngle
			nSocketTargetYawAngle	= nMaxYawAngle > 0.0 and self:Clamp(nWeightedYawAngle, -nMaxYawAngle, nMaxYawAngle) or nWeightedYawAngle
		end
	end

	if bEnableViewPitchSocketSync then
		nViewPitchAngle				= self:ResolveViewPitchAngle()
		local nViewPitchSocketWeight	= (self.nViewPitchSocketWeight or 0.0) * nProfileSocketPitchWeight
		local nViewPitchSocketMaxAngle	= self.nViewPitchSocketMaxAngle or 0.0
		local nWeightedViewPitchAngle	= nViewPitchAngle * nViewPitchSocketWeight
		local nClampedViewPitchAngle	= nViewPitchSocketMaxAngle > 0.0 and self:Clamp(nWeightedViewPitchAngle, -nViewPitchSocketMaxAngle, nViewPitchSocketMaxAngle) or nWeightedViewPitchAngle

		nSocketTargetPitchAngle	= nSocketTargetPitchAngle + nClampedViewPitchAngle
	end

	local bUseDirectSocketRotation	= self.bUseTorsoAimDirectSocketRotation
	local nSocketBlendAlpha			= bUseDirectSocketRotation and 1.0 or self:Clamp(nDeltaTime * (self.nUpperBodySocketSmoothSpeed or 0.0), 0.0, 1.0)
	local nCurrentSocketPitchAngle	= self._private.nSocketUpperBodyPitchAngle or 0.0
	local nCurrentSocketYawAngle	= self._private.nSocketUpperBodyYawAngle or 0.0
	local nUpdatedSocketPitchAngle	= self:LerpAngle(nCurrentSocketPitchAngle, nSocketTargetPitchAngle, nSocketBlendAlpha)
	local nUpdatedSocketYawAngle	= self:LerpAngle(nCurrentSocketYawAngle, nSocketTargetYawAngle, nSocketBlendAlpha)
	local qSocketBaseLocalRotation	= self._private.qSocketBaseLocalRotation or self:CacheSocketBaseLocalRotation()
	local vSocketBaseLocalPosition	= self._private.vSocketBaseLocalPosition or self:CacheSocketBaseLocalPosition()
	local vSocketTargetLocalPosition	= vSocketBaseLocalPosition

	self._private.nSocketUpperBodyPitchAngle	= nUpdatedSocketPitchAngle
	self._private.nSocketUpperBodyYawAngle		= nUpdatedSocketYawAngle

	if not qSocketBaseLocalRotation then
		return false
	end

	local qUpperBodySocketOffsetRotation	= Quaternion.new(Vector3.new(nUpdatedSocketPitchAngle, nUpdatedSocketYawAngle, 0.0))
	local qSocketTargetLocalRotation		= qSocketBaseLocalRotation * qUpperBodySocketOffsetRotation

	oSocketTransform:SetLocalRotation(qSocketTargetLocalRotation)

	if vSocketBaseLocalPosition and self.bEnableSocketPitchPositionCompensation then
		local nProfileSocketPitchPositionWeight	= self:ResolveSocketPitchPositionProfileWeight()
		local nSocketPitchPositionWeight		= (self.nSocketPitchPositionWeight or 0.0) * nProfileSocketPitchPositionWeight
		local nSocketPitchSourceAngle			= bEnableViewPitchSocketSync and nViewPitchAngle or nUpdatedSocketPitchAngle
		local nSocketPitchDirectionMultiplier	= nSocketPitchSourceAngle >= 0.0 and (self.nSocketPitchPositionDownMultiplier or 1.0) or (self.nSocketPitchPositionUpMultiplier or 1.0)
		local nSocketPitchOffsetScale			= nSocketPitchSourceAngle * nSocketPitchPositionWeight * nSocketPitchDirectionMultiplier
		local vSocketPitchPositionOffset		= Vector3.new(
			(self.nSocketPitchPositionOffsetPerDegreeX or 0.0) * nSocketPitchOffsetScale,
			(self.nSocketPitchPositionOffsetPerDegreeY or 0.0) * nSocketPitchOffsetScale,
			(self.nSocketPitchPositionOffsetPerDegreeZ or 0.0) * nSocketPitchOffsetScale
		)

		vSocketTargetLocalPosition	= vSocketBaseLocalPosition + vSocketPitchPositionOffset
	end

	if vSocketTargetLocalPosition then
		oSocketTransform:SetLocalPosition(vSocketTargetLocalPosition)
	end

	self._private.qSocketHipLocalRotation	= qSocketTargetLocalRotation
	self._private.vSocketHipLocalPosition	= vSocketTargetLocalPosition or vSocketBaseLocalPosition

	return true
end

function WeaponHolder:EnsureSocketParent()
	local oSocketActor		= self._private.oSocketActor
	local sSocketParentActorName	= self.sWeaponSocketParentActorName

	if not oSocketActor or not sSocketParentActorName or sSocketParentActorName == "" then
		return false
	end

	local oExpectedParentActor	= self:ResolveActor(sSocketParentActorName)
	local oCurrentParentActor	= oSocketActor:GetParent()

	if not oExpectedParentActor then
		Debug.LogWarning("WeaponHolder: missing socket parent '" .. sSocketParentActorName .. "'")
		return false
	end

	if oCurrentParentActor == oExpectedParentActor then
		return true
	end

	oSocketActor:SetParent(oExpectedParentActor)
	self._private.oSocketTransform	= oSocketActor:GetTransform()

	return true
end

function WeaponHolder:TryEquipDefaultWeapon()
	if self._private.oEquippedWeapon then
		return true
	end

	local oWeaponActor	= self:ResolveDefaultWeaponActor()

	if not oWeaponActor then
		Debug.LogWarning("WeaponHolder: no weapon actor found to equip")
		return false
	end

	return self:EquipWeaponActor(oWeaponActor)
end

function WeaponHolder:ResolveDefaultWeaponActor()
	local oDefaultWeaponActor	= self.oDefaultWeaponActor

	if oDefaultWeaponActor then
		return oDefaultWeaponActor
	end

	return self:ResolveActor(self.sDefaultWeaponActorName)
end

function WeaponHolder:EquipWeaponActor(oWeaponActor)
	local oSocketActor	= self._private.oSocketActor

	if not oSocketActor then
		Debug.LogError("WeaponHolder: cannot equip weapon without socket actor")
		return false
	end

	local oWeapon	= oWeaponActor and oWeaponActor:GetBehaviour("Weapon") or nil

	if not oWeapon or not oWeapon.EquipToSocket then
		Debug.LogError("WeaponHolder: actor '" .. (oWeaponActor and oWeaponActor:GetName() or "<nil>") .. "' has no compatible Weapon behaviour")
		return false
	end

	local bDidEquip	= oWeapon:EquipToSocket(oSocketActor)

	if not bDidEquip then
		return false
	end

	self._private.oEquippedWeaponActor	= oWeaponActor
	self._private.oEquippedWeapon		= oWeapon
	self:SetAimDownSightsAlpha(self._private.nAimAlpha or 0.0)

	if self.bEnableWeaponLogs then
		Debug.Log("WeaponHolder: equipped '" .. oWeaponActor:GetName() .. "'")
	end

	return true
end

function WeaponHolder:UnequipCurrentWeapon()
	local oWeapon	= self._private.oEquippedWeapon

	self:SetAimDownSightsAlpha(0.0)

	if oWeapon and oWeapon.Unequip then
		oWeapon:Unequip()
	end

	self._private.oEquippedWeaponActor	= nil
	self._private.oEquippedWeapon		= nil
end

function WeaponHolder:UpdateEquippedWeaponPose(nDeltaTime)
	local oWeapon	= self._private.oEquippedWeapon

	if oWeapon and oWeapon.ApplyEquipOffset then
		oWeapon:ApplyEquipOffset()
	end
end

function WeaponHolder:UpdateAimDownSights(nDeltaTime)
	local bEnableAimDownSights	= self.bEnableAimDownSights
	local nAimMouseButton		= self.nAimMouseButton
	local bWantsAimDownSights	= bEnableAimDownSights and Inputs.GetMouseButton(nAimMouseButton)
	local nAimTargetAlpha		= bWantsAimDownSights and 1.0 or 0.0
	local nAimAlphaCurrent		= self._private.nAimAlpha or 0.0
	local nAimSpeed			= bWantsAimDownSights and (self.nAimEnterSpeed or 0.0) or (self.nAimExitSpeed or 0.0)
	local nAimBlendAlpha		= self:Clamp((nDeltaTime or 0.0) * nAimSpeed, 0.0, 1.0)
	local nAimAlphaUpdated		= nAimAlphaCurrent + ((nAimTargetAlpha - nAimAlphaCurrent) * nAimBlendAlpha)
	local nAimAlpha			= self:Clamp(nAimAlphaUpdated, 0.0, 1.0)

	self:SetAimDownSightsAlpha(nAimAlpha)
	self:ApplyAimDownSightsSocketPose()
end

function WeaponHolder:SetAimDownSightsAlpha(nAimAlpha)
	local nClampedAimAlpha	= self:Clamp(nAimAlpha or 0.0, 0.0, 1.0)
	local oWeapon		= self._private.oEquippedWeapon

	self._private.nAimAlpha			= nClampedAimAlpha
	self._private.bIsAimingDownSights	= nClampedAimAlpha > 0.0001

	if oWeapon then
		if oWeapon.SetAimAlpha then
			oWeapon:SetAimAlpha(nClampedAimAlpha)
		elseif oWeapon.ResetAimAlpha then
			oWeapon:ResetAimAlpha()
		end
	end
end

function WeaponHolder:ApplyAimDownSightsSocketPose()
	local oSocketTransform	= self._private.oSocketTransform
	local nAimAlphaRaw	= self._private.nAimAlpha or 0.0
	local nAimBlendWeight	= self.nAimSocketBlendWeight or 1.0
	local nAimAlpha		= self:Clamp(nAimAlphaRaw * nAimBlendWeight, 0.0, 1.0)

	if not oSocketTransform or nAimAlpha <= 0.0001 then
		return false
	end

	local vSocketHipLocalPosition	= self._private.vSocketHipLocalPosition or oSocketTransform:GetLocalPosition()
	local qSocketHipLocalRotation	= self._private.qSocketHipLocalRotation or oSocketTransform:GetLocalRotation()
	local vSocketAimLocalPosition, qSocketAimLocalRotation	= self:ResolveAimDownSightsSocketLocalPose()

	if not vSocketHipLocalPosition or not qSocketHipLocalRotation or not vSocketAimLocalPosition or not qSocketAimLocalRotation then
		return false
	end

	local vSocketLocalPosition	= self:LerpVector3(vSocketHipLocalPosition, vSocketAimLocalPosition, nAimAlpha)
	local qSocketLocalRotation	= self:BlendQuaternion(qSocketHipLocalRotation, qSocketAimLocalRotation, nAimAlpha)

	oSocketTransform:SetLocalPosition(vSocketLocalPosition)
	oSocketTransform:SetLocalRotation(qSocketLocalRotation)

	return true
end

function WeaponHolder:ResolveAimDownSightsSocketLocalPose()
	local oSocketActor		= self._private.oSocketActor
	local oCameraTransform	= self._private.oCameraTransform or self:ResolveCameraTransform()

	if not oSocketActor or not oCameraTransform then
		return nil, nil
	end

	local oSocketParentActor	= oSocketActor:GetParent()
	local oSocketParentTransform	= oSocketParentActor and oSocketParentActor:GetTransform() or nil

	if not oSocketParentTransform then
		return nil, nil
	end

	local vParentWorldPosition	= oSocketParentTransform:GetWorldPosition()
	local qParentWorldRotation	= oSocketParentTransform:GetWorldRotation()
	local qParentWorldInverse	= self:InverseQuaternion(qParentWorldRotation)
	local vCameraWorldPosition	= oCameraTransform:GetWorldPosition()
	local qCameraWorldRotation	= oCameraTransform:GetWorldRotation()
	local vAimCameraOffset		= Vector3.new(self.nAimSocketCameraOffsetX or 0.0, self.nAimSocketCameraOffsetY or 0.0, self.nAimSocketCameraOffsetZ or 0.0)
	local qAimCameraRotationOffset	= Quaternion.new(Vector3.new(self.nAimSocketRotationPitch or 0.0, self.nAimSocketRotationYaw or 0.0, self.nAimSocketRotationRoll or 0.0))
	local vAimWorldPosition		= vCameraWorldPosition + (qCameraWorldRotation * vAimCameraOffset)
	local qAimWorldRotation		= qCameraWorldRotation * qAimCameraRotationOffset
	local vAimParentSpaceOffset	= vAimWorldPosition - vParentWorldPosition
	local vAimLocalPosition		= qParentWorldInverse * vAimParentSpaceOffset
	local qAimLocalRotation		= qParentWorldInverse * qAimWorldRotation

	self._private.oCameraTransform	= oCameraTransform

	return vAimLocalPosition, qAimLocalRotation
end

function WeaponHolder:GetAimDownSightsAlpha()
	return self._private.nAimAlpha or 0.0
end

function WeaponHolder:IsAimingDownSights()
	return self._private.bIsAimingDownSights or false
end

function WeaponHolder:GetEquippedWeaponActor()
	return self._private.oEquippedWeaponActor
end

function WeaponHolder:GetEquippedWeapon()
	return self._private.oEquippedWeapon
end

function WeaponHolder:ResolveSocketUpperBodyYawProfileWeight()
	local oWeapon		= self._private.oEquippedWeapon
	local oGripProfile	= oWeapon and oWeapon.GetGripProfile and oWeapon:GetGripProfile() or nil
	local nWeight		= oGripProfile and oGripProfile.GetSocketUpperBodyYawWeight and oGripProfile:GetSocketUpperBodyYawWeight() or 1.0

	return nWeight or 1.0
end

function WeaponHolder:ResolveSocketUpperBodyPitchProfileWeight()
	local oWeapon		= self._private.oEquippedWeapon
	local oGripProfile	= oWeapon and oWeapon.GetGripProfile and oWeapon:GetGripProfile() or nil
	local nWeight		= oGripProfile and oGripProfile.GetSocketUpperBodyPitchWeight and oGripProfile:GetSocketUpperBodyPitchWeight() or 1.0

	return nWeight or 1.0
end

function WeaponHolder:ResolveSocketPitchPositionProfileWeight()
	local oWeapon		= self._private.oEquippedWeapon
	local oGripProfile	= oWeapon and oWeapon.GetGripProfile and oWeapon:GetGripProfile() or nil
	local nWeight		= oGripProfile and oGripProfile.GetSocketPitchPositionWeight and oGripProfile:GetSocketPitchPositionWeight() or 1.0

	return nWeight or 1.0
end

function WeaponHolder:ResolveViewPitchAngle()
	local oView	= self._private.oView

	if not oView then
		oView					= self.owner:GetBehaviour("View") or self:FindBehaviourInParents(self.owner, "View")
		self._private.oView		= oView
	end

	local nViewPitchAngle	= oView and oView.GetPitchAngle and oView:GetPitchAngle() or 0.0

	return nViewPitchAngle or 0.0
end

function WeaponHolder:ResolveCameraTransform()
	local oCameraActor	= self:ResolveActor(self.sPlayerCameraActorName)

	return oCameraActor and oCameraActor:GetTransform() or nil
end

function WeaponHolder:LerpVector3(vFrom, vTo, nAlpha)
	local nClampedAlpha	= self:Clamp(nAlpha or 0.0, 0.0, 1.0)

	return vFrom + ((vTo - vFrom) * nClampedAlpha)
end

function WeaponHolder:NormalizeQuaternion(qValue)
	if not qValue then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	local nLengthSq	= (qValue.x * qValue.x) + (qValue.y * qValue.y) + (qValue.z * qValue.z) + (qValue.w * qValue.w)

	if nLengthSq <= 0.0001 then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	local nInvLength	= 1.0 / math.sqrt(nLengthSq)

	return Quaternion.new(qValue.x * nInvLength, qValue.y * nInvLength, qValue.z * nInvLength, qValue.w * nInvLength)
end

function WeaponHolder:InverseQuaternion(qValue)
	if not qValue then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	local nLengthSq	= (qValue.x * qValue.x) + (qValue.y * qValue.y) + (qValue.z * qValue.z) + (qValue.w * qValue.w)

	if nLengthSq <= 0.0001 then
		return Quaternion.new(Vector3.new(0, 0, 0))
	end

	local nInvLengthSq	= 1.0 / nLengthSq

	return Quaternion.new(-qValue.x * nInvLengthSq, -qValue.y * nInvLengthSq, -qValue.z * nInvLengthSq, qValue.w * nInvLengthSq)
end

function WeaponHolder:BlendQuaternion(qFrom, qTo, nAlpha)
	local nClampedAlpha	= self:Clamp(nAlpha or 0.0, 0.0, 1.0)
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

function WeaponHolder:GetWeaponSocketActor()
	return self._private.oSocketActor
end

return WeaponHolder
