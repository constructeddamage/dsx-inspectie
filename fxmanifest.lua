fx_version "cerulean"
game "gta5"
lua54 "yes"

author "Merlijn Swarts"
description "dsx-inspectie"
version "1.0.0"

client_scripts { "client/main.lua" }
server_scripts { "server/main.lua" }
shared_scripts { "@es_extended/imports.lua", "@es_extended/locale.lua", "@ox_lib/init.lua", "shared/config.lua" }
dependencies { "es_extended", "ox_target", "ox_lib" }