fx_version "cerulean"
lua54 "yes"
game "gta5"

author "DevJacob"
description "A FiveM script to sync lights on emergency fleets"
version "0.2.0"

dependencies {
	"DevJacob_CallbackManager",
	"DevJacob_CommonLib",
}

shared_scripts {
	"imports.lua",
	"config.lua",
}

client_scripts {
	"@DevJacob_CommonLib/lib/client.lua",
	"client/utils.lua",
	"client/main.lua",
}

server_scripts {
	"@DevJacob_CommonLib/lib/server.lua",
	"server/main.lua",
}
