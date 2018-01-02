
local addon_name = "RezzTimer"
local addon_version = "1.0.1"

local list = {}	-- list of (playername => rezztimer)
local f = CreateFrame("frame")	-- counter & events
local d = CreateFrame("frame")	-- GUI
local dt = d:CreateFontString()	-- GUI text for numbers
local lasttime = 0	-- time since last GUI update (should be 1 Hz)

local tablelength = function(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

-- Creates GUI
RT_init = function()
	d:SetPoint("TOP", UIParent, 0, 0)
	d:SetWidth(100)
	d:SetHeight(20)

	dt:SetPoint("CENTER", d, "CENTER", 0, 0)
	dt:SetWidth(100)
	dt:SetHeight(20)
	dt:SetFont("Fonts\\FRIZQT__.TTF", 10)

	d:Show()
end

-- Shows/updates dead player list on GUI
RT_show = function()
	local text = ""
	foreach(list, function(name, num)
		text = text .. name .. ": " .. num .. "|n"
	end)
	dt:SetText(text)
end

-- Goes through the "list"
-- Decreases all timers by "dif" time and deletes entries that are <= 0 time
RT_updatelist = function(dif)
	foreach(list, function(name, num)
		local newnum = num - dif
		if newnum <= 0 then
			list[name] = nil
		else
			list[name] = newnum
		end
	end)
	RT_checktimers()
end

-- This function is called periodically to decrease timers & update GUI
RT_update = function()
	local curtime = time()
	local dif = curtime - lasttime
	if dif >= 1 then
		lasttime = curtime
		RT_updatelist(dif)
		RT_show()
	end
end

-- Disables/enables timers & GUI updates (e.g. disable if list empty)
RT_checktimers = function()
	if tablelength(list) == 0 then
		f:SetScript("OnUpdate", nil)
	elseif f:GetScript("OnUpdate") == nil then
		lasttime = time()
		f:SetScript("OnUpdate", RT_update)
	end
end

-- Check if received data is valid and add it to the list
-- Also starts timers & show GUI
RT_parse = function(name, data)
	data = tonumber(data)
	if data == nil or data < 0 or data > 120 then
		return
	end

	if data == 0 then
		list[name] = nil
	else
		list[name] = data
	end

	RT_checktimers()
	RT_show()
end

-- Send any data as an addon message to the raid
RT_send = function(data)
	SendAddonMessage(addon_name, data, "RAID")
end

-- Callback function for receiving an addon message
RT_recv = function(prefix, data, chan, sender)
	if prefix == addon_name then
		RT_parse(sender, data)
	end
end

-- Check if player is dead and send notification to other raid members if dead
RT_checkifdead = function()
	if UnitIsGhost("player") then
		RT_send(GetCorpseRecoveryDelay())
	end
end

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_DEAD")
f:RegisterEvent("PLAYER_ALIVE")
f:RegisterEvent("CHAT_MSG_ADDON")

f:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" then
		if string.lower(arg1) == string.lower(addon_name) then
			RT_init()
			RT_checkifdead()
		end
	elseif event == "PLAYER_DEAD" then
		RT_checkifdead()
	elseif event == "PLAYER_ALIVE" then
		RT_checkifdead()
	elseif event == "CHAT_MSG_ADDON" then
		RT_recv(arg1, arg2, arg3, arg4)
	end
end)
