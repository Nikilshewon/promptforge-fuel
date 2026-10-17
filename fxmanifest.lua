fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'promptforge-fuel'
author 'PromptForge'
description 'PromptForge Fuel - modern multi-framework (Qbox / QBCore / ESX / standalone) fuel system with neon 3D pump text, tablet UI and fuel hose'
version '1.0.0'

dependencies { 'ox_lib', 'ox_target' } -- framework (qbx_core / qb-core / es_extended) is optional, auto-detected

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_script 'client/main.lua'
server_script 'server/main.lua'

ui_page 'web/index.html'
files { 'web/index.html', 'web/style.css', 'web/script.js', 'web/img/*.png' }

provide 'LegacyFuel' -- exports['LegacyFuel']:GetFuel / SetFuel keep working
