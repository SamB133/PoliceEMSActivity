Config = {}

Config.CLIENT_UPDATE_INTERVAL_SECONDS = 3 -- On-map blip refresh (seconds)

-- Title shown at the top of the /duty department menu (NUI)
Config.Menu = { Title = 'Select Department' }

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

-- Optional live status embed (channel webhook, NOT a bot token)
Config.StatusEmbed = {
    Enabled               = false,        -- Master switch
    WebhookURL            = '',           -- https://discord.com/api/webhooks/ID/TOKEN
    BotName               = 'Server Status',
    BotAvatarURL          = '',           -- '' = Webhook default avatar
    ServerName            = 'My Server',  -- Embed title
    ThumbnailURL          = '',           -- '' = No thumbnail
    Color                 = '',           -- Side bar hex e.g. '#5865F2'; '' or invalid => black
    UpdateIntervalSeconds = 60,
    MaxPlayers            = 'auto',       -- 'auto' => GetConvarInt('sv_maxClients', 48), or a number
    HeartbeatSeconds      = 600,          -- Force a refresh at least this often (keeps footer time fresh)
}
