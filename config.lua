Config = {}

-- How often (seconds) on-duty blip positions refresh on the map
Config.CLIENT_UPDATE_INTERVAL_SECONDS = 3

-- Title shown at the top of the /duty department menu
Config.Menu = { Title = 'Select Department' }

-- Inserted between a department label and the player name on blips ("👮 LSPD | Sam")
Config.Separator = ' | '

-- Departments in display order. Emoji is optional (omit it or use '').
--   name    = clean department name (shown without the emoji in the embed player list)
--   emoji   = optional icon shown before the name in counts ("👮 LSPD")
--   role    = Discord role ID that grants this department (replace the placeholder!)
--   color   = FiveM blip color (https://docs.fivem.net/docs/game-references/blips/#blip-colors)
--   webhook = optional per-department duty-log webhook (nil = off)
Config.Departments = {
    { emoji = '👮', name = 'LSPD',    role = 1234567890, color = 2,  webhook = nil },
    { emoji = '👮', name = 'Sheriff', role = 1234567890, color = 17, webhook = nil },
    { emoji = '👮', name = 'SAHP',    role = 1234567890, color = 3,  webhook = nil },
    -- No-emoji examples (both show as just "EMS") — omit the field, or set it to '':
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
    BotAvatarURL          = '',           -- '' = webhook's default avatar
    ServerName            = 'My Server',  -- Embed title
    ThumbnailURL          = '',           -- '' = no thumbnail
    Color                 = '',           -- Side-bar hex e.g. '#5865F2'; '' or invalid => black
    UpdateIntervalSeconds = 60,           -- How often (seconds) the embed refreshes
    MaxPlayers            = 'auto',       -- 'auto' => sv_maxClients convar, or set a number
}
