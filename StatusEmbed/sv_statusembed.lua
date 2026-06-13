-- Live Discord status embed posted to a channel webhook (NOT a bot token).
-- Reads the global onDuty/activeBlip tables from server.lua (same runtime).

local CFG = Config.StatusEmbed
local SEP = Config.Separator or ' | '

-- Build "👮 LSPD", or just "LSPD" when no emoji (own copy; server.lua locals don't cross files)
local function deptLabel(d)
	if d.emoji and d.emoji ~= '' then return d.emoji .. ' ' .. d.name end
	return d.name
end

-- Map a department tag -> clean name (no emoji) for the connected-players list
local nameByTag = {}
for i = 1, #Config.Departments do
	local d = Config.Departments[i]
	nameByTag[deptLabel(d) .. SEP] = d.name
end

-- Hex string -> Discord colour int; '' or invalid => black
local function hexToInt(hex)
	if type(hex) ~= 'string' then return 0 end
	hex = hex:gsub('#', ''):gsub('%s', '')
	if hex == '' then return 0 end
	return tonumber(hex, 16) or 0 -- Invalid => black
end

-- Server slot count (config override, else the sv_maxClients convar)
local function maxPlayers()
	if type(CFG.MaxPlayers) == 'number' then return CFG.MaxPlayers end
	return GetConvarInt('sv_maxClients', 48)
end

-- Pad/clip a string to a fixed width for the monospace table
local function pad(s, width)
	s = tostring(s)
	if #s > width then return string.sub(s, 1, width) end
	if #s < width then return s .. string.rep(' ', width - #s) end
	return s
end

-- Gather the current state the embed renders
local function gatherState()
	local depCounts = {} -- [tag] = number on duty
	local onDutyCount = 0
	local ids = GetPlayers() -- Array of connected server id strings
	local players = {}
	for i = 1, #ids do
		local sid = tonumber(ids[i])
		local tag = activeBlip[sid]
		local deptName = Config.Civ.name
		if onDuty[sid] ~= nil and tag ~= nil then
			depCounts[tag] = (depCounts[tag] or 0) + 1
			onDutyCount = onDutyCount + 1
			deptName = nameByTag[tag] or '?'
		end
		players[#players + 1] = { id = sid, name = GetPlayerName(sid) or '?', dept = deptName }
	end
	table.sort(players, function(a, b) return a.id < b.id end) -- Ascending server id
	local connected = #ids
	local civ = connected - onDutyCount
	if civ < 0 then civ = 0 end
	return depCounts, civ, connected, players
end

-- Build the webhook JSON body (embed + bot name/avatar)
local function buildEmbedPayload(depCounts, civ, connected, players)
	-- Department count lines, then CIV, then the connected-players header
	local lines = {}
	for i = 1, #Config.Departments do
		local d = Config.Departments[i]
		lines[#lines + 1] = deptLabel(d) .. ': ' .. (depCounts[d.tag] or 0)
	end
	lines[#lines + 1] = deptLabel(Config.Civ) .. ': ' .. civ
	lines[#lines + 1] = ''
	lines[#lines + 1] = '**Connected Players (' .. connected .. '/' .. maxPlayers() .. '):**'
	local body = table.concat(lines, '\n') .. '\n'

	-- Connected players as a monospace code block, one per line, sorted by id
	local rows = { pad('ID', 5) .. '| ' .. pad('NAME', 22) .. '| DEPT' }
	rows[#rows + 1] = string.rep('-', 36)
	for i = 1, #players do
		local p = players[i]
		local row = pad('[' .. p.id .. ']', 5) .. '| ' .. pad(p.name, 22) .. '| ' .. p.dept
		-- Keep the whole description under Discord's 4096 limit (leave headroom)
		if #body + 8 + #table.concat(rows, '\n') + 1 + #row > 4000 then
			rows[#rows + 1] = '… (list truncated)'
			break
		end
		rows[#rows + 1] = row
	end
	local description = body .. '```\n' .. table.concat(rows, '\n') .. '\n```'

	local embed = {
		title = CFG.ServerName,
		description = description,
		color = hexToInt(CFG.Color),
		footer = { text = os.date('Date: %m/%d/%Y | Time: %I:%M %p') },
	}
	if CFG.ThumbnailURL ~= '' then embed.thumbnail = { url = CFG.ThumbnailURL } end

	local payload = { embeds = { embed } }
	if CFG.BotName ~= '' then payload.username = CFG.BotName end
	if CFG.BotAvatarURL ~= '' then payload.avatar_url = CFG.BotAvatarURL end
	return payload
end

-- KVP keys: remember the message id and which webhook it belongs to
local KVP_MSG_ID = 'pea_status_msg_id'
local KVP_MSG_URL = 'pea_status_webhook_url'

local state = {
	disabled = false, -- Set after a fatal webhook failure (until restart)
	messageId = nil,
}

-- POST a brand-new message; ?wait=true returns the message id in the body
local function postNew(payload)
	local url = CFG.WebhookURL .. '?wait=true'
	PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
		if statusCode == 200 and responseText then
			local ok, decoded = pcall(json.decode, responseText)
			if ok and decoded and decoded.id then
				state.messageId = decoded.id
				SetResourceKvpString(KVP_MSG_ID, decoded.id)
				SetResourceKvpString(KVP_MSG_URL, CFG.WebhookURL)
				print('[PEA-Status] Posted status message id=' .. decoded.id)
			else
				print('[PEA-Status] POST ok but no message id returned; disabling until restart.')
				state.disabled = true
			end
		else
			print('[PEA-Status] POST failed (HTTP ' .. tostring(statusCode) .. '). Check WebhookURL/permissions. Disabling until restart.')
			state.disabled = true
		end
	end, 'POST', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- PATCH the existing message; 404 means it was deleted -> recreate it
local function patchExisting(payload)
	local url = CFG.WebhookURL .. '/messages/' .. state.messageId
	PerformHttpRequest(url, function(statusCode, responseText, responseHeaders)
		if statusCode == 200 then
			return -- Updated in place
		elseif statusCode == 404 then
			print('[PEA-Status] Status message missing (404). Recreating.')
			state.messageId = nil
			DeleteResourceKvp(KVP_MSG_ID)
			postNew(payload)
		else
			print('[PEA-Status] PATCH failed (HTTP ' .. tostring(statusCode) .. '). Disabling until restart.')
			state.disabled = true
		end
	end, 'PATCH', json.encode(payload), { ['Content-Type'] = 'application/json' })
end

-- Edit if we have a message id, otherwise post a new one
local function postOrUpdate(payload)
	if state.messageId == nil then
		postNew(payload)
	else
		patchExisting(payload)
	end
end

-- Adopt a saved message id only if it belongs to the configured webhook
local function loadPersistedId()
	local savedUrl = GetResourceKvpString(KVP_MSG_URL)
	local savedId = GetResourceKvpString(KVP_MSG_ID)
	if savedId and savedUrl == CFG.WebhookURL then
		state.messageId = savedId
	else
		state.messageId = nil
		if savedId then
			print('[PEA-Status] Saved message id is for a different webhook; will post fresh.')
		end
	end
end

-- Rebuild the embed and push it (edit existing message, or post a new one)
local function pushUpdate()
	if state.disabled or not CFG.Enabled then return end
	local depCounts, civ, connected, players = gatherState()
	postOrUpdate(buildEmbedPayload(depCounts, civ, connected, players))
end

-- One init path covers both server start and resource restart (KVP persists across both)
CreateThread(function()
	if not CFG.Enabled then
		print('[PEA-Status] Disabled in config.')
		return
	end
	if CFG.WebhookURL == '' then
		print('[PEA-Status] Enabled but WebhookURL is empty; disabling.')
		state.disabled = true
		return
	end
	loadPersistedId()
	Wait(5000) -- Let players register first
	while true do
		pushUpdate() -- Refresh every interval, changed or not
		Wait((CFG.UpdateIntervalSeconds or 60) * 1000)
	end
end)
