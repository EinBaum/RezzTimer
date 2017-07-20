
local name = "RezzTimer"
local version = "1.0.0"

local list = {}
local f = CreateFrame("frame")
local d = CreateFrame("frame")
local dt = d:CreateFontString()
local lasttime = 0

local tablelength = function(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

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

RT_show = function()
	local text = ""
	foreach(list, function(name, num)
		text = text .. name .. ": " .. num .. "|n"
	end)
	dt:SetText(text)
end

RT_checktimers = function()
	if tablelength(list) == 0 then
		f:SetScript("OnUpdate", nil)
	elseif f:GetScript("OnUpdate") == nil then
		lasttime = time()
		f:SetScript("OnUpdate", RT_update)
	end
end

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

RT_send = function(data)
	SendAddonMessage(name, data, "RAID")
end

RT_recv = function(prefix, data, chan, RT_sender)
	if prefix == name then
		RT_parse(RT_sender, data)
	end
end

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
	RT_show()
end

RT_update = function()
	local curtime = time()
	local dif = curtime - lasttime
	if dif >= 1 then
		lasttime = curtime
		RT_updatelist(dif)
	end
end

RT_inform = function()
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
		if string.lower(arg1) == string.lower(name) then
			RT_init()
			RT_inform()
		end
	elseif event == "PLAYER_DEAD" then
		RT_inform()
	elseif event == "PLAYER_ALIVE" then
		RT_inform()
	elseif event == "CHAT_MSG_ADDON" then
		RT_recv(arg1, arg2, arg3, arg4)
	end
end)
