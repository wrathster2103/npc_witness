fx_version 'serverdata'
game 'gta5'

author 'wrathster2103'
description 'NPC witness system: detects crimes, spawns witnesses with varied behaviors (phone calls, tracking, panic), and dispatches police'
version '1.1.0'

server_script 'server.lua'
client_script 'client.lua'

shared_script '@qb-core/shared/locale.lua' -- optional, won't fail if qbcore present
shared_script 'config.lua'

lua54 'yes'