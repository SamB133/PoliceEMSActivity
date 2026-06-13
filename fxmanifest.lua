fx_version 'cerulean'
game 'gta5'

author 'JaredScar'
description 'PoliceEMSActivity'
version '2.1'
url 'https://github.com/JaredScar/PoliceEMSActivity'

-- NUI duty menu
ui_page 'nui/index.html'

files {
	'nui/index.html',
	'nui/style.css',
	'nui/script.js',
}

client_scripts {
	'client.lua',
	'EmergencyBlips/cl_emergencyblips.lua',
}

server_scripts {
	'config.lua', -- Must load first so Config exists
	'server.lua',
	'EmergencyBlips/sv_emergencyblips.lua',
	'StatusEmbed/sv_statusembed.lua',
}
