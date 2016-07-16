local source = [[
local EventFolderParent = game:GetService("ReplicatedStorage")
local modulesFolder = script

local ChatService = require(modulesFolder:WaitForChild("ChatService"))
local proxy = require(modulesFolder:WaitForChild("ChatServiceProxy")).CreateProxy(ChatService)

local didInit = false


local EventFolder = Instance.new("Folder")
EventFolder.Name = "ChatEvents"
EventFolder.Archivable = false
Instance.new("RemoteEvent", EventFolder).Name = "OnNewMessage"
Instance.new("RemoteEvent", EventFolder).Name = "OnNewSystemMessage"
Instance.new("RemoteEvent", EventFolder).Name = "OnChannelJoined"
Instance.new("RemoteEvent", EventFolder).Name = "OnChannelLeft"
Instance.new("RemoteEvent", EventFolder).Name = "OnMuted"
Instance.new("RemoteEvent", EventFolder).Name = "OnUnmuted"
Instance.new("RemoteEvent", EventFolder).Name =  "OnSpeakerExtraDataUpdated"

Instance.new("RemoteEvent", EventFolder).Name = "SayMessageRequest"
Instance.new("RemoteEvent", EventFolder).Name = "GetInitDataRequest"

EventFolder.Parent = EventFolderParent


local Players = game:GetService("Players")
local function HandlePlayerJoining(playerObj)
	while not didInit do wait(0.2) end

	--// If a developer already created a speaker object with the
	--// name of a player and then a player joins and tries to 
	--// take that name, we first need to remove the old speaker object
	local speaker = ChatService:GetSpeaker(playerObj.Name)
	if (speaker) then
		ChatService:RemoveSpeaker(playerObj.Name)
	end
	
	speaker = ChatService:AddSpeaker(playerObj.Name)
	speaker:AssignPlayerObject(playerObj)

	speaker.OnReceivedMessage:connect(function(fromSpeaker, channel, message)
		EventFolder.OnNewMessage:FireClient(playerObj, fromSpeaker, channel, message)
	end)

	speaker.OnReceivedSystemMessage:connect(function(message, channel)
		EventFolder.OnNewSystemMessage:FireClient(playerObj, message, channel)
	end)

	speaker.OnChannelJoined:connect(function(channel, welcomeMessage)
		EventFolder.OnChannelJoined:FireClient(playerObj, channel, welcomeMessage)
	end)

	speaker.OnChannelLeft:connect(function(channel)
		EventFolder.OnChannelLeft:FireClient(playerObj, channel)
	end)

	speaker.OnMuted:connect(function(channel, reason, length)
		EventFolder.OnMuted:FireClient(playerObj, channel, reason, length)
	end)

	speaker.OnUnmuted:connect(function(channel)
		EventFolder.OnUnmuted:FireClient(playerObj, channel)
	end)

	for i, channel in pairs(ChatService:GetAutoJoinChannelList()) do
		speaker:JoinChannel(channel.Name)
	end
end

Players.PlayerAdded:connect(function(playerObj)
	HandlePlayerJoining(playerObj)
end)

Players.PlayerRemoving:connect(function(playerObj)
	ChatService:RemoveSpeaker(playerObj.Name)
end)


EventFolder.SayMessageRequest.OnServerEvent:connect(function(playerObj, message, channel)
	local speaker = ChatService:GetSpeaker(playerObj.Name)
	if (speaker) then
		speaker:SayMessage(message, channel)
	end
end)

EventFolder.GetInitDataRequest.OnServerEvent:connect(function(playerObj)
	local speaker = ChatService:GetSpeaker(playerObj.Name)
	if (speaker) then
		
		for i, channelName in pairs(speaker:GetChannelList()) do
			local channel = ChatService:GetChannel(channelName)
			EventFolder.OnChannelJoined:FireClient(playerObj, channel.Name, channel.WelcomeMessage)
			if (channel:IsSpeakerMuted(speaker.Name)) then
				EventFolder.OnMuted:FireClient(playerObj, channelName, nil, nil)
			end
		end
		
		for i, oSpeakerName in pairs(ChatService:GetSpeakerList()) do
			local oSpeaker = ChatService:GetSpeaker(oSpeakerName)
			EventFolder.OnSpeakerExtraDataUpdated:FireClient(playerObj, oSpeakerName, oSpeaker.ExtraData)
		end
		
	end
end)

ChatService.OnSpeakerAdded:connect(function(speakerName)
	local speaker = ChatService:GetSpeaker(speakerName)
	
	EventFolder.OnSpeakerExtraDataUpdated:FireAllClients(speakerName, speaker.ExtraData)
	
	speaker.OnExtraDataUpdated:connect(function(key, value)
		local data = {}
		data[key] = value
		EventFolder.OnSpeakerExtraDataUpdated:FireAllClients(speakerName, data)
	end)
end)


ChatService:RegisterFilterMessageFunction("default_filter", function(fromSpeaker, message)
	for filter, v in pairs(ChatService.WordFilters) do
		message = string.gsub(message, filter, string.rep("*", string.len(filter)))
	end
	for alias, replacement in pairs(ChatService.WordAliases) do
		message = string.gsub(message, alias, replacement)
	end
	
	return message
end)

local function DoJoinCommand(speakerName, channelName)
	local speaker = ChatService:GetSpeaker(speakerName)
	local channel = ChatService:GetChannel(channelName)
	
	if (speaker) then
		if (channel) then
			if (channel.Joinable) then
				if (not speaker:IsInChannel(channel.Name)) then
					speaker:JoinChannel(channel.Name)
				end
			else
				speaker:SendSystemMessage("You cannot join channel '" .. channelName .. "'.", nil)
			end
		else
			speaker:SendSystemMessage("Channel '" .. channelName .. "' does not exist.", nil)
		end
	end
end

local function DoLeaveCommand(speakerName, channelName)
	local speaker = ChatService:GetSpeaker(speakerName)
	local channel = ChatService:GetChannel(channelName)
	
	if (speaker) then
		if (speaker:IsInChannel(channelName)) then
			if (channel.Leavable) then
				speaker:LeaveChannel(channel.Name)
			else
				speaker:SendSystemMessage("You cannot leave channel '" .. channelName .. "'.", nil)
			end
		else
			speaker:SendSystemMessage("You are not in channel '" .. channelName .. "'.", nil)
		end
	end
end

ChatService:RegisterProcessCommandsFunction("default_commands", function(fromSpeaker, message, channel)
	if (string.sub(message, 1, 6):lower() == "/join ") then
		DoJoinCommand(fromSpeaker, string.sub(message, 7))
		return true
	elseif (string.sub(message, 1, 3):lower() == "/j ") then
		DoJoinCommand(fromSpeaker, string.sub(message, 4))
		return true
		
	elseif (string.sub(message, 1, 7):lower() == "/leave ") then
		DoLeaveCommand(fromSpeaker, string.sub(message, 8))
		return true
	elseif (string.sub(message, 1, 3):lower() == "/l ") then
		DoLeaveCommand(fromSpeaker, string.sub(message, 4))
		return true
		
	elseif (string.sub(message, 1, 3) == "/e " or string.sub(message, 1, 7) == "/emote ") then
		-- Just don't show these in the chatlog. The animation script listens on these.
		return true
		
	end
	
	return false
end)


local allChannel = ChatService:AddChannel("All")
local systemChannel = ChatService:AddChannel("System")

allChannel.Leavable = false
allChannel.AutoJoin = true
allChannel.WelcomeMessage = "Chat '/?' for a list of chat commands."

systemChannel.Leavable = false
systemChannel.AutoJoin = true
systemChannel.WelcomeMessage = "This channel is for system and game notifications."

systemChannel.OnSpeakerJoined:connect(function(speakerName)
	systemChannel:MuteSpeaker(speakerName)
end)


local function TryRunModule(module)
	if module:IsA("ModuleScript") then
		spawn(function()
			local ret = require(module)
			if (type(ret) == "function") then
				ret(proxy)
			end
		end)
	end
end

local modules = game:GetService("ServerStorage"):FindFirstChild("ChatModules")
if modules then
	modules.ChildAdded:connect(function(child)
		pcall(TryRunModule, child)
	end)
	
	for i, module in pairs(modules:GetChildren()) do
		pcall(TryRunModule, module)
	end
end

wait()

didInit = true


spawn(function()
	wait()
	for i, player in pairs(game:GetService("Players"):GetChildren()) do
		local spkr = ChatService:GetSpeaker(player.Name)
		if (not spkr or not spkr:GetPlayerObject()) then
			HandlePlayerJoining(player)
		end
	end
end)
]]

local generated = Instance.new("Script")
generated.Disabled = true
generated.Name = "Generated"
generated.Source = source
generated.Parent = script