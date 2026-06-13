Config = {}

Config.CLIENT_UPDATE_INTERVAL_SECONDS = 3 -- On-map blip refresh (seconds)

-- Inserted between a department label and the player name on blips ("👮 LSPD | Sam")
Config.Separator = ' | '

-- Departments in display order. Emoji is OPTIONAL (omit it or use ''); the code
-- derives the blip tag "👮 LSPD | ", the count label "👮 LSPD", and the no-emoji "LSPD".
Config.Departments = {
    { emoji = '👮', name = 'LSPD',    role = 1234567890, color = 2,  webhook = nil },
    { emoji = '👮', name = 'Sheriff', role = 1234567890, color = 17, webhook = nil },
    { emoji = '👮', name = 'SAHP',    role = 1234567890, color = 3,  webhook = nil },
    -- Examples with no emoji (both show as just "EMS") — omit the field, or set it to '':
    -- { name = 'EMS', role = 1234567890, color = 1, webhook = nil },
    -- { emoji = '', name = 'EMS', role = 1234567890, color = 1, webhook = nil },
}

-- Pseudo-department for everyone NOT on duty (listed last). Emoji optional here too.
Config.Civ = { emoji = '👱‍♂️', name = 'CIV' }
