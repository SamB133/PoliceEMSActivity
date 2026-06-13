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

-- A signature of everything the embed renders EXCEPT the footer time
local function signatureOf(depCounts, civ, connected, players)
	local parts = { 'C' .. connected, 'V' .. civ }
	for i = 1, #Config.Departments do
		local d = Config.Departments[i]
		parts[#parts + 1] = d.name .. '=' .. (depCounts[d.tag] or 0)
	end
	for i = 1, #players do
		local p = players[i]
		parts[#parts + 1] = p.id .. ':' .. p.name .. ':' .. p.dept
	end
	return table.concat(parts, '|')
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
