fx_version 'cerulean'
game 'gta5'

author 'KP_Script & Chatgpt'
description 'Personal AI Bodyguard system for Shadow Cartel Boss'
version '2.0.0'

shared_scripts {
    '@ox_lib/init.lua'
    '@es_extended/imports.lua',
    'config/config.lua',
}

client_scripts {
    'client/menu.lua',
    'client/main.lua',
    'client/shared_state.lua',
    'client/vehicle.lua',
    'client/heli.lua',
    'client/other-logic.lua'
}

server_scripts {
    'server/main.lua'
}
