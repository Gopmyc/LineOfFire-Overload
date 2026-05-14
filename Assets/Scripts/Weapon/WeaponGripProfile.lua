---@class WeaponGripProfile : Behaviour
local WeaponGripProfile	=
{
	nMountOffsetX			= 0.0,
	nMountOffsetY			= 0.0,
	nMountOffsetZ			= 0.0,
	nMountRotationPitch		= 0.0,
	nMountRotationYaw		= 0.0,
	nMountRotationRoll		= 0.0,
	nRightGripOffsetPitch		= 0.0,
	nRightGripOffsetYaw		= 0.0,
	nRightGripOffsetRoll		= 0.0,
	nLeftGripOffsetPitch		= 0.0,
	nLeftGripOffsetYaw			= 0.0,
	nLeftGripOffsetRoll			= 0.0,
	nRightHandRotationWeight	= 1.0,
	nLeftHandRotationWeight		= 1.0,
	nRightShoulderAssistWeight	= 1.0,
	nLeftShoulderAssistWeight	= 1.0,
	nSocketUpperBodyYawWeight	= 1.0,
	nSocketUpperBodyPitchWeight	= 1.0,
	nSocketPitchPositionWeight	= 1.0,

	_private	=
	{
	}
}

function WeaponGripProfile:OnAwake()
	self	= setmetatable(self, self:ResolveClassBehaviour())
end

function WeaponGripProfile:ResolveClassBehaviour()
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

function WeaponGripProfile:GetGripOffsetRotation(sArmName)
	local bIsRightArm	= sArmName == "RightArm"
	local nPitch		= bIsRightArm and self.nRightGripOffsetPitch or self.nLeftGripOffsetPitch
	local nYaw			= bIsRightArm and self.nRightGripOffsetYaw or self.nLeftGripOffsetYaw
	local nRoll			= bIsRightArm and self.nRightGripOffsetRoll or self.nLeftGripOffsetRoll

	return Quaternion.new(Vector3.new(nPitch or 0.0, nYaw or 0.0, nRoll or 0.0))
end

function WeaponGripProfile:GetMountOffset()
	return Vector3.new(self.nMountOffsetX or 0.0, self.nMountOffsetY or 0.0, self.nMountOffsetZ or 0.0)
end

function WeaponGripProfile:GetMountRotation()
	local nPitch	= self.nMountRotationPitch or 0.0
	local nYaw	= self.nMountRotationYaw or 0.0
	local nRoll	= self.nMountRotationRoll or 0.0

	return Quaternion.new(Vector3.new(nPitch, nYaw, nRoll))
end

function WeaponGripProfile:GetHandRotationWeight(sArmName)
	local bIsRightArm	= sArmName == "RightArm"
	local nWeight		= bIsRightArm and self.nRightHandRotationWeight or self.nLeftHandRotationWeight

	return self:ClampValue(nWeight or 1.0, 0.0, 2.0)
end

function WeaponGripProfile:GetShoulderAssistWeight(sArmName)
	local bIsRightArm	= sArmName == "RightArm"
	local nWeight		= bIsRightArm and self.nRightShoulderAssistWeight or self.nLeftShoulderAssistWeight

	return self:ClampValue(nWeight or 1.0, 0.0, 2.0)
end

function WeaponGripProfile:GetSocketUpperBodyYawWeight()
	local nWeight	= self.nSocketUpperBodyYawWeight

	return self:ClampValue(nWeight or 1.0, 0.0, 2.0)
end

function WeaponGripProfile:GetSocketUpperBodyPitchWeight()
	local nWeight	= self.nSocketUpperBodyPitchWeight

	return self:ClampValue(nWeight or 1.0, 0.0, 2.0)
end

function WeaponGripProfile:GetSocketPitchPositionWeight()
	local nWeight	= self.nSocketPitchPositionWeight

	return self:ClampValue(nWeight or 1.0, 0.0, 2.0)
end

function WeaponGripProfile:ClampValue(nValue, nMin, nMax)
	if self.Clamp then
		return self:Clamp(nValue, nMin, nMax)
	end

	local nClampedMin	= nValue < nMin and nMin or nValue

	return nClampedMin > nMax and nMax or nClampedMin
end

return WeaponGripProfile
