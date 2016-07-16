local source = [[
local module = {}

local function AssignmentError(index, expected, got)
	error("bad argument #3 to '" .. index .. "' (" .. expected .. " expected, got " .. tostring(got) .. ")")
end

local function NotAValidMemberError(index, obj)
	error(index .. " is not a valid member of " .. obj.Target.__ClassName)
end

local function TypeCastError(from, to)
	error("Unable to cast " .. from .. " to " .. to)
end


local function AssertAssignmentTypeEquals(index, var, t)
	if (type(var) ~= t) then AssignmentError(index, t, type(var)) end
end

local function AssertParameterTypeEquals(var, t)
	if (type(var) ~= t) then TypeCastError(type(var), t) end
end

function module.CreateProxy(ChatChannel)
	local proxy = newproxy(true)
	local metatable = getmetatable(proxy)
	local obj = {}
	obj.Target = ChatChannel
	
	obj.Target.OnDestroyed:connect(function()
		obj.Target = nil
		
		metatable.__tostring = function() return "" end
		metatable.__index = function() error("Object is destroyed!") end
		metatable.__newindex = function() error("Object is destroyed!") end
	end)
	
	function obj:AddWordFilter(expression)
		AssertParameterTypeEquals(expression, "string")
		obj.Target:AddWordFilter(expression)
	end
	
	function obj:RemoveWordFilter(expression)
		AssertParameterTypeEquals(expression, "string")
		obj.Target:RemoveWordFilter(expression)
	end
	
	function obj:AddWordAlias(expression, replacement)
		AssertParameterTypeEquals(expression, "string")
		AssertParameterTypeEquals(replacement, "string")
		obj.Target:AddWordAlias(expression, replacement)
	end
	
	function obj:RemoveWordAlias(expression)
		AssertParameterTypeEquals(expression, "string")
		obj.Target:RemoveWordAlias(expression)
	end
	
	function obj:KickSpeaker(speakerName, reason)
		AssertParameterTypeEquals(speakerName, "string")
		
		if (type(reason) ~= "string" and type(reason) ~= "nil") then
			AssertParameterTypeEquals(reason, "string")
		end
		
		obj.Target:KickSpeaker(speakerName, reason)
	end
	
	function obj:MuteSpeaker(speakerName, reason, length)
		AssertParameterTypeEquals(speakerName, "string")
		
		if (type(reason) ~= "string" and type(reason) ~= "nil") then
			AssertParameterTypeEquals(reason, "string")
		end
		
		if (type(length) ~= "number" and type(length) ~= "nil") then
			AssertParameterTypeEquals(reason, "number")
		end
		
		obj.Target:MuteSpeaker(speakerName, reason, length)
	end
	
	function obj:UnmuteSpeaker(speakerName)
		AssertParameterTypeEquals(speakerName, "string")
		
		obj.Target:UnmuteSpeaker(speakerName)
	end
	
	function obj:IsSpeakerMuted(speakerName)
		AssertParameterTypeEquals(speakerName, "string")
		
		return obj.Target:IsSpeakerMuted(speakerName)
	end
	
	function obj:GetSpeakerList()
		return obj.Target:GetSpeakerList()
	end
	
	function obj:RegisterFilterMessageFunction(funcId, func)
		AssertParameterTypeEquals(funcId, "string")
		AssertParameterTypeEquals(func, "function")
		
		if (funcId == "default_filter") then
			error("You cannot register this filter!")
		end
		
		local allow = false
		pcall(function()
			local ret = func("Player1", "test message")
			AssertParameterTypeEquals(ret, "string")
			allow = true
		end)
		
		if (not allow) then
			error("Function must return a string!")
		end
		
		obj.Target:RegisterFilterMessageFunction(funcId, func)
	end

	function obj:UnregisterFilterMessageFunction(funcId, func)
		AssertParameterTypeEquals(funcId, "string")
		
		if (funcId == "default_filter") then
			error("You cannot unregister this filter!")
		end
		
		obj.Target:UnregisterFilterMessageFunction(funcId)
	end
	
	function obj:RegisterProcessCommandsFunction(funcId, func)
		AssertParameterTypeEquals(funcId, "string")
		AssertParameterTypeEquals(func, "function")
		
		if (funcId == "default_commands") then
			error("You cannot register this set of commands!")
		end
		
		obj.Target:RegisterProcessCommandsFunction(funcId, func)
	end
	
	function obj:UnregisterProcessCommandsFunction(funcId)
		AssertParameterTypeEquals(funcId, "string")
		
		if (funcId == "default_commands") then
			error("You cannot unregister this set of commands!")
		end
		
		obj.Target:UnregisterProcessCommandsFunction(funcId)
	end
	
	function obj:SendSystemMessage(message)
		AssertParameterTypeEquals(message, "string")
		
		obj.Target:SendSystemMessage(message)
	end
	
	metatable.__metatable = "The metatable is locked"
	metatable.__tostring = function () return tostring(obj.Target) end
	
	metatable.__index = function(tbl, index)
		if (index == "Joinable" or index == "Leavable" or
			index == "AutoJoin" or index == "Private" or
			index == "Name" or index == "WelcomeMessage" or
			index == "OnNewMessage" or index == "OnSpeakerJoined" or index == "OnSpeakerLeft" or 
			index == "OnSpeakerMuted" or index == "OnSpeakerUnmuted") then
			return obj.Target[index]
			
		elseif (index == "AddWordFilter" or index == "RemoveWordFilter" or
				index == "AddWordAlias" or index == "RemoveWordAlias" or
				index == "KickSpeaker" or index == "MuteSpeaker" or index == "UnmuteSpeaker" or index == "IsSpeakerMuted" or
				index == "GetSpeakerList" or index == "SendSystemMessage" or 
				index == "RegisterFilterMessageFunction" or index == "UnregisterFilterMessageFunction" or
				index == "RegisterProcessCommandsFunction" or index == "UnregisterProcessCommandsFunction") then
			return obj[index]
			
		else
			NotAValidMemberError(index, obj)
			
		end
	end
	
	metatable.__newindex = function(tbl, index, value)
		if (index == "Joinable" or index == "Leavable" or index == "AutoJoin" or index == "Private") then
			AssertAssignmentTypeEquals(index, value, "boolean")
			
			obj.Target[index] = value
			
		elseif (index == "WelcomeMessage") then
			AssertAssignmentTypeEquals(index, value, "string")
			
			obj.Target[index] = value
			
		else
			NotAValidMemberError(index, obj)
			
		end
	end	
	
	
	return proxy
end

return module

]]

local generated = Instance.new("ModuleScript")
generated.Name = "Generated"
generated.Source = source
generated.Parent = script