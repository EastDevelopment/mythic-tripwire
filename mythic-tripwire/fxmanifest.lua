fx_version 'cerulean'
game 'gta5'
author 'East'
description 'Tripwire Resource @ DevEra'
lua54 'yes'

client_script "@mythic-base/components/cl_error.lua"
client_script "@mythic-pwnzor/client/check.lua"
server_script "@oxmysql/lib/MySQL.lua"

shared_scripts {
    'shared/config.lua',
    'shared/tripwire.lua',
    'locale/*.lua',
}

client_scripts {
    '@mythic-polyzone/client.lua',
    '@mythic-polyzone/BoxZone.lua',
    '@mythic-polyzone/EntityZone.lua',
    '@mythic-polyzone/CircleZone.lua',
    '@mythic-polyzone/ComboZone.lua',
    'client/component.lua',
    'client/tripwire.lua',
}

server_scripts {
    'server/component.lua',
    'server/tripwire.lua',
}

dependency '/assetpacks'

