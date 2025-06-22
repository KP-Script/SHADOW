fx_version 'cerulean'
game 'gta5'

description 'Shadow Cartel Guard System'
author 'KP_script'

client_scripts {
    'client/*.lua'
}

server_scripts {
    '@es_extended/imports.lua',
    'server/access_control.lua'
}

shared_script {
    'config/config.lua',
    'config/cayo.lua',
    '@ox_lib/init.lua'
}