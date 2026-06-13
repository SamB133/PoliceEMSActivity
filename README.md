# PoliceEMSActivity

A FiveM resource that gives on‑duty emergency services (police, sheriff, EMS, etc.) live **map blips** of every other on‑duty member, an in‑game **duty menu**, an **`/online`** roster, and an optional **live Discord status embed** that shows who is connected and on duty.

Permissions are driven by **Discord roles** (via `Badger_Discord_API`), so a player can only go on duty as a department they actually have the role for.

---

## Table of contents

- [Features](#features)
- [How it works](#how-it-works)
- [Dependencies](#dependencies)
- [Installation](#installation)
- [Commands](#commands)
- [Permissions](#permissions)
- [Configuration](#configuration)
  - [Departments](#departments)
  - [Blip colors](#blip-colors)
  - [CIV (off‑duty bucket)](#civ-off-duty-bucket)
  - [The duty menu](#the-duty-menu)
  - [Per‑department duty logs](#per-department-duty-logs)
  - [Discord status embed](#discord-status-embed)
- [Example setups](#example-setups)
- [Duty loadout (weapons)](#duty-loadout-weapons)
- [FAQ / notes](#faq--notes)
- [Credits](#credits)

---

## Features

- **Shared duty blips** – on‑duty members see a blip for every other on‑duty member, colored per department and labelled `👮 LSPD | PlayerName`. Positions refresh on an interval.
- **In‑game duty menu** – `/duty` opens a NUI menu listing **only** the departments you have permission for. Pick one to go on duty as it.
- **`/online` roster** – per‑department head‑counts in chat, plus a civilian total for everyone connected and off duty.
- **Duty loadout** – weapons and armor are handed out when you go on duty and removed when you go off.
- **Optional per‑department duty logs** – post an on/off‑duty embed to a Discord webhook whenever a member of that department toggles duty.
- **Optional live status embed** – a single Discord message (posted via a channel webhook) that auto‑updates with department counts and a connected‑players list.

---

## How it works

- Permissions are resolved **once when a player spawns**: the script reads the player's Discord roles through `Badger_Discord_API` and records which configured departments they may use (`permTracker`).
- **`/duty`** (off duty) sends the player's allowed departments to the NUI menu. The player's choice is sent back to the server, **re‑validated** against their permissions, and then they go on duty: a blip is created, the duty loadout is given, and (optionally) a duty‑log webhook fires.
- **`/duty`** (on duty) takes the player straight off duty – no menu.
- Blips are only drawn **for on‑duty players**; off‑duty players don't see them. The server broadcasts on‑duty coordinates every `CLIENT_UPDATE_INTERVAL_SECONDS`.
- The **status embed** runs independently on the server: every `UpdateIntervalSeconds` it recomputes the panel and edits its Discord message with the latest counts, player list, and timestamp.

---

## Dependencies

| Dependency | Required | Purpose |
| --- | --- | --- |
| [`Badger_Discord_API`](https://github.com/JaredScar/Badger_Discord_API) | **Yes** | Reads each player's Discord roles to decide which departments they can use. Must be installed, configured (its own bot token + guild ID), and **started before** this resource. |
| A Discord **bot** | Yes (for `Badger_Discord_API`) | `Badger_Discord_API` needs a bot in your guild to look up member roles. This is **separate** from the status embed, which uses a webhook (no bot needed). |
| A Discord **channel webhook** | Optional | Only needed if you enable the status embed and/or per‑department duty logs. |

> The dependency is used implicitly through `exports.Badger_Discord_API`. If you want the server to enforce start order, add `dependency 'Badger_Discord_API'` to `fxmanifest.lua`.

---

## Installation

1. Install and configure **`Badger_Discord_API`** first (bot token + guild ID in its config).
2. Drop the `PoliceEMSActivity` folder into your server's `resources` directory.
3. Edit `config.lua` (see [Configuration](#configuration)) – at minimum set each department's `role` to a real Discord role ID.
4. Ensure both resources start, with the dependency first, e.g. in `server.cfg`:
   ```cfg
   ensure Badger_Discord_API
   ensure PoliceEMSActivity
   ```

---

## Commands

| Command | Who | What it does |
| --- | --- | --- |
| `/duty` | Players with a department role | **Off duty:** opens the department menu (only your permitted departments). **On duty:** goes off duty. |
| `/online` | Anyone | Prints each department's on‑duty count, then a civilian total (everyone connected and off duty). |

Example `/online` output:

```
👮 LSPD: 4
👮 Sheriff: 1
👮 SAHP: 0
👱‍♂️ CIV: 12
```

---

## Permissions

Each department has a `role` – a **Discord role ID**. When a player spawns, the script asks `Badger_Discord_API` for their Discord roles and grants access to every department whose `role` they hold. Players with no matching roles can't go on duty and get an error from `/duty`.

To switch departments while playing: go **off** duty, run `/duty` again, and pick a different one.

---

## Configuration

Everything lives in `config.lua`. Here is the full file with every option explained:

```lua
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
```

### Departments

Each entry needs only two display fields and the role/color:

| Field | Required | Notes |
| --- | --- | --- |
| `name` | Yes | Clean name, no emoji. Used on blips, in `/online`, and (without the emoji) in the embed's player list. |
| `emoji` | No | Shown before the name in count lines (`👮 LSPD`). Omit it or use `''` for no emoji. |
| `role` | Yes | Discord role ID that grants access to this department. |
| `color` | Yes | FiveM blip color index. |
| `webhook` | No | Per‑department duty‑log webhook URL (`nil` to disable). |

From these the script derives:
- the **blip tag / identity** `👮 LSPD | ` ( `emoji` + `name` + `Config.Separator` ),
- the **count label** `👮 LSPD` (used in `/online` and the embed),
- the **plain name** `LSPD` (used in the embed's Connected Players column).

> Tip: Discord role IDs are large numbers. If a real ID ever mismatches, quote it as a string, e.g. `role = '887518674607562803'`.

### Blip colors

`color` is a standard FiveM/GTA blip color index. A few common values:

| ID | Color |
| --- | --- |
| 0 | White |
| 1 | Red |
| 2 | Green |
| 3 | Blue |
| 5 | Yellow |

See the full list in the [FiveM blip colors documentation](https://docs.fivem.net/docs/game-references/blips/#blip-colors).

### CIV (off‑duty bucket)

`Config.Civ` is **not** a real department – it has no `role` and can't be selected for duty. It's the label for everyone who is connected but off duty, shown last in `/online` and at the bottom of the embed. You can change its `emoji`/`name` (emoji optional).

### The duty menu

`Config.Menu.Title` sets the heading of the in‑game `/duty` menu. The menu lists one button per department the player is permitted to use; clicking one puts them on duty, and pressing **ESC** (or **Cancel**) closes it without changing duty.

### Per‑department duty logs

Set a department's `webhook` to a Discord channel webhook URL to log duty changes for that department. When a member goes **on** duty a green embed is posted, and when they go **off** duty (including disconnecting) a red embed with the on‑duty duration is posted. This is independent of the status embed.

```lua
Config.Departments = {
    { emoji = '👮', name = 'LSPD', role = 1234567890, color = 2,
      webhook = 'https://discord.com/api/webhooks/XXXX/YYYY' },
}
```

### Discord status embed

A single Discord message, posted to a channel **webhook**, that mirrors live server activity. It shows:

- the **server name** (`ServerName`) as the title and an optional **thumbnail** (`ThumbnailURL`),
- one line per department with its on‑duty count (`👮 LSPD: 4`), then `👱‍♂️ CIV: N`,
- a **Connected Players** code block listing `ID | Name | Dept` (department without emoji), sorted by server ID,
- a **footer** with the date/time it was last updated.

Behavior:

- **Custom name & avatar** – `BotName` and `BotAvatarURL` override the webhook's display name/avatar per message.
- **Side color** – `Color` is a hex code (`'#5865F2'`); blank or invalid falls back to **black**.
- **Auto‑update** – every `UpdateIntervalSeconds` (default 60) it edits the existing message with the latest department counts, connected-players list, and footer time.
- **One message, kept in place** – the message ID is remembered across restarts (resource KVP, tied to the webhook URL). On start it edits the existing message, or posts a new one if none exists. If the message was deleted it posts a fresh one; if you point `WebhookURL` at a different channel it posts a new one there.
- **Failure handling** – if the webhook can't be posted to (bad URL/permissions), it logs the HTTP error to the server console and **stops trying until the resource is restarted**, so it won't spam.
- **Player count** – `MaxPlayers = 'auto'` reads the `sv_maxClients` convar; set a number to override.

**Webhook setup:** In Discord, open the target channel → *Edit Channel* → *Integrations* → *Webhooks* → *New Webhook* → *Copy Webhook URL*, and paste it into `WebhookURL`.

---

## Example setups

**1. Police + Fire/EMS, with the status embed on**

```lua
Config.Departments = {
    { emoji = '👮', name = 'Police', role = 111111111111111111, color = 3,  webhook = nil },
    { emoji = '🚑', name = 'EMS',    role = 222222222222222222, color = 1,  webhook = nil },
    { emoji = '🚒', name = 'Fire',   role = 333333333333333333, color = 47, webhook = nil },
}

Config.StatusEmbed = {
    Enabled               = true,
    WebhookURL            = 'https://discord.com/api/webhooks/123/abc',
    BotName               = 'City RP | Status',
    BotAvatarURL          = 'https://i.imgur.com/yourlogo.png',
    ServerName            = 'City Roleplay',
    ThumbnailURL          = 'https://i.imgur.com/yourlogo.png',
    Color                 = '#1ABC9C',
    UpdateIntervalSeconds = 60,
    MaxPlayers            = 'auto',
}
```

**2. A department with no emoji**

```lua
Config.Departments = {
    { name = 'LSPD', role = 1234567890, color = 2, webhook = nil }, -- shows as "LSPD"
}
```

**3. Per‑department duty logging (no status embed)**

```lua
Config.Departments = {
    { emoji = '👮', name = 'LSPD', role = 1234567890, color = 2,
      webhook = 'https://discord.com/api/webhooks/123/abc' },
}

Config.StatusEmbed = { Enabled = false } -- (leave the rest default)
```

---

## Duty loadout (weapons)

Going on duty gives a default police loadout (nightstick, stun gun, flashlight, combat pistol, carbine rifle, pump shotgun, attachments, and 100 armor); going off duty removes all weapons and armor. This is defined in **`client.lua`** under the `PoliceEMSActivity:GiveWeapons` / `:TakeWeapons` handlers – edit those if you want a different loadout (or to disable it).

---

## FAQ / notes

- **How do I change my department mid‑session?** Go off duty (`/duty`), then `/duty` again and pick another. (The old `/bliptag` command was removed.)
- **A player has access to more than one department.** The menu lists all of them; they pick one each time they go on duty.
- **Nothing happens / "must be an LEO" error.** The player has no department role, or `Badger_Discord_API` isn't running/configured, or `role` IDs in the config are still placeholders.
- **The embed didn't post.** Check the server console for `[PEA-Status]` lines – it reports an empty/invalid webhook and disables itself until restart.
- **Do off‑duty players show on the map?** No – blips are only visible to on‑duty members.

---

## Credits

- Original script by **JaredScar** – <https://github.com/JaredScar/PoliceEMSActivity>
- Emergency blips module originally by **minipunch**
- Permissions powered by **Badger_Discord_API**
