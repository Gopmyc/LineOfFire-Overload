---@class Class : Behaviour
return {
	__index	= function(self, sKey)
		local mValue	= rawget(self, sKey)
		local tPrivate	= rawget(self, "_private")

		return mValue ~= nil and mValue or (tPrivate and rawget(tPrivate, sKey) or nil)
	end,
}