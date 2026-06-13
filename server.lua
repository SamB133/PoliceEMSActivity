-- CONFIG --
local SEP = Config.Separator or ' | '

-- Build "👮 LSPD", or just "LSPD" when no emoji
local function deptLabel(d)
	if d.emoji and d.emoji ~= '' then return d.emoji .. ' ' .. d.name end
	return d.name
end

-- Blip prefix + identity, e.g. "👮 LSPD | "
local function deptTag(d) return deptLabel(d) .. SEP end

-- Ordered department list + tag lookup built from config
local Departments = { ordered = Config.Departments, byTag = {} }
for i = 1, #Config.Departments do
	local d = Config.Departments[i]
	d.tag = deptTag(d) -- Compute once; identity stored in activeBlip/permTracker
	Departments.byTag[d.tag] = d
end

-- Safe lookup: returns the department for a tag, or nil
local function deptOf(tag)
	if tag == nil then return nil end
	return Departments.byTag[tag]
end

-- CODE --
Citizen.CreateThread(function()
	while true do
		-- Wait a second and add it to their timeTracker
		Wait(1000)
		for k, v in pairs(timeTracker) do
			timeTracker[k] = timeTracker[k] + 1
		end
	end
end)
timeTracker = {}
hasPerms = {}
permTracker = {}
activeBlip = {}
onDuty = {}
prefix = '^9[^5Badger-Blips^9] ^3';

AddEventHandler("playerDropped", function()
	local src = source
	if onDuty[src] ~= nil then -- Log off duty + clear blip/weapons
		goOffDuty(src, false)
	end
	timeTracker[src] = nil;
	onDuty[src] = nil;
	permTracker[src] = nil;
	hasPerms[src] = nil;
	activeBlip[src] = nil;
end)

function sendToDisc(title, message, footer, webhookURL, color)
	local embed = {}
	embed = {
		{
			["color"] = color, -- GREEN = 65280 --- RED = 16711680
			["title"] = "**".. title .."**",
			["description"] = "** " .. message ..  " **",
			["footer"] = {
				["text"] = footer,
			},
		}
	}
	PerformHttpRequest(webhookURL,
	function(err, text, headers) end, 'POST', json.encode({username = name, embeds = embed}), { ['Content-Type'] = 'application/json' })
end

function sendMsg(src, msg)
	TriggerClientEvent('chatMessage', src, prefix .. msg);
end

-- Put a player ON duty as the given tag (caller validates the tag)
function goOnDuty(src, tag)
	local dept = deptOf(tag)
	if dept == nil then
		sendMsg(src, '^1ERROR: Unknown department.')
		return false
	end
	activeBlip[src] = tag
	onDuty[src] = true
	timeTracker[src] = 0
	TriggerEvent('eblips:add', { name = tag .. GetPlayerName(src), src = src, color = dept.color })
	TriggerClientEvent('PoliceEMSActivity:GiveWeapons', src)
	if dept.webhook ~= nil then -- Per-department duty log
		sendToDisc('Player ' .. GetPlayerName(src) .. ' is now on duty',
			'Player ' .. GetPlayerName(src) .. ' has gone on duty as ' .. tag, '',
			dept.webhook, 65280)
	end
	sendMsg(src, 'You have toggled your emergency blip ^2ON ^3and your Blip-Tag is: ' .. tag)
	return true
end

-- Take a player OFF duty; sendChat controls the chat confirmation
function goOffDuty(src, sendChat)
	local tag = activeBlip[src]
	local dept = deptOf(tag)
	if dept and dept.webhook ~= nil and timeTracker[src] ~= nil then
		local minutesActive = math.floor(timeTracker[src] / 60) -- timeTracker counts seconds
		sendToDisc('Player ' .. GetPlayerName(src) .. ' is now off duty',
			'Player ' .. GetPlayerName(src) .. ' has gone off duty as ' .. tostring(tag),
			'Duration: ' .. minutesActive .. ' minutes',
			dept.webhook, 16711680)
	end
	onDuty[src] = nil
	timeTracker[src] = nil
	TriggerClientEvent('PoliceEMSActivity:TakeWeapons', src)
	TriggerEvent('eblips:remove', src)
	if sendChat then
		sendMsg(src, 'You have toggled your emergency blip ^1OFF')
	end
end

-- /duty: toggle on/off duty as your default department
RegisterCommand('duty', function(source, args, rawCommand)
	local src = source
	if hasPerms[src] == nil then -- Permissions check
		sendMsg(src, '^1ERROR: You must be an LEO on our discord to use this...')
		return
	end
	if onDuty[src] ~= nil then
		goOffDuty(src, true)
	else
		goOnDuty(src, activeBlip[src])
	end
end)

RegisterCommand('cops', function(source, args, rawCommand)
	-- Prints the active cops online with a /blip that is on
	sendMsg(source, 'The active cops on are:')
	for id, _ in pairs(onDuty) do
		TriggerClientEvent('chatMessage', source, '^9[^4' .. id .. '^9] ^0' .. GetPlayerName(id));
	end
end)

RegisterNetEvent('PoliceEMSActivity:RegisterUser')
AddEventHandler('PoliceEMSActivity:RegisterUser', function()
	local src = source
	local identifierDiscord = nil -- Local so it never leaks between players
	for k, v in ipairs(GetPlayerIdentifiers(src)) do
		if string.sub(v, 1, string.len("discord:")) == "discord:" then
			identifierDiscord = v
		end
	end
	local perms = {}
	if identifierDiscord then
		local roleIDs = exports.Badger_Discord_API:GetDiscordRoles(src)
		if not (roleIDs == false) then
			for i = 1, #Departments.ordered do -- Check each department's role
				local d = Departments.ordered[i]
				for j = 1, #roleIDs do
					if exports.Badger_Discord_API:CheckEqual(d.role, roleIDs[j]) then
						table.insert(perms, d.tag);
						activeBlip[src] = d.tag; -- Default selection (menu re-asks anyway)
						hasPerms[src] = true;
						print("[PEA] Gave Perms Sucessfully (" .. d.name .. ")")
					end
				end
			end
		else
			print("[PoliceEMSActivity] " .. GetPlayerName(src) .. " has not gotten their permissions cause roleIDs == false")
		end
	else
		print("[PoliceEMSActivity] " .. GetPlayerName(src) .. " has not gotten their permissions cause discord was not detected...")
	end
	permTracker[src] = perms;
end)
