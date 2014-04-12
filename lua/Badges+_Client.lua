Script.Load( "lua/Badges+_Shared.lua" )

-- temp cache of often used function
local StringFormat = string.format
local TableInsert = table.insert

--Badges+ functions
local sServerBadges = {}
	
function GetBadgeStrings( callback )        
	local sClientBadges = sServerBadges
	callback( sClientBadges )        
end

local receiveBadges = {}
function addReceiveBadgeHook( func )
	TableInsert(receiveBadges, func )
end

local function OnReceiveBadge( message )
	if message.clientIndex == -1 then
		local sBadge = kBadges[ message.badge ]
		TableInsert( sServerBadges, sBadge )
		-- default to first badge if we haven't selected one
		if Client.GetOptionString( "Badge", "" ) == "" or Client.GetOptionString( "Badge", "" ) == sBadge then
			Client.SetOptionString( "Badge", "" )
			Shared.ConsoleCommand( StringFormat( "badge \"%s\"", sBadge ))
		end 
	else
		for i, func in ipairs( receiveBadges ) do
			func( message )
		end
	end
end
Client.HookNetworkMessage( "Badge", OnReceiveBadge )

local function OnLoadComplete()
	local sSavedBadge = Client.GetOptionString( "Badge", "" )
	if Client.GetIsConnected() then
		if sBadgeExists( sSavedBadge ) then
			Client.SendNetworkMessage( "Badge", { badge = kBadges[ sSavedBadge ] }, true )
		else
			Client.SetOptionString( "Badge", "" )     
		end
	end    
end
Event.Hook( "LoadComplete", OnLoadComplete )

local function OnClientDisconnected()
	sServerBadges = {}
end
Event.Hook( "ClientDisconnected", OnClientDisconnected )

Script.Load( "lua/Badges+_ConsoleCommands.lua" )
Script.Load( "lua/Badges+_Scoreboard.lua" )
Script.Load( "lua/Badges+_MainMenu.lua" )
