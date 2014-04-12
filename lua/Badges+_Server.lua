Script.Load( "lua/Badges+_Shared.lua" )

-- temp cache of often used function
local StringFormat = string.format

local TableInsert = table.insertunique
local TableContains = table.contains

local JsonDecode = json.decode

-- The currently selected badge for each player on the server
local kPlayerBadges = {}
-- Badges defined by the server operator or other mods
local sServerBadges = {}

function GiveBadge( userId, sBadgeName )
	local sClientBadges = sServerBadges[ userId ]
	if not sClientBadges then
		sClientBadges = {}
		sServerBadges[ userId ] = sClientBadges
	end
	if sBadgeExists( sBadgeName ) then
		table.insertunique( sClientBadges, sBadgeName )
		return true
	end
	return false
end

-- Parse the server admin file
do
	local function LoadConfigFile(fileName)
		Shared.Message( StringFormat( "Loading Badge config://%s", fileName ))
		local openedFile = io.open( StringFormat( "config://%s", fileName ), "r" )
		if openedFile then
		
			local parsedFile = openedFile:read("*all")
			io.close(openedFile)
			return parsedFile
			
		end
		return nil
	end
	
	local function ParseJSONStruct( struct )
		return JsonDecode( struct ) or {}
	end

	local serverAdmin = ParseJSONStruct( LoadConfigFile( "ServerAdmin.json" ))
	if serverAdmin.users then
		for _, user in pairs(serverAdmin.users) do
			local userId = user.id
			for i = 1, #user.groups do
				-- Check if the group has a badge assigned
				local groupName = user.groups[i]
				local group = serverAdmin.groups[groupName]
				if group then
					local sGroupBadges = group.badges or {}
					if group.badge then
						TableInsert( sGroupBadges, group.badge )
					end 
					
					-- Assign all badges for the group
					for i, sGroupBadge in ipairs( sGroupBadges ) do
						if not GiveBadge( userId, sGroupBadge ) then
							Print( StringFormat( "%s is configured for a badge that non-existent or reserved badge: %s", groupName, sGroupBadge ))
						end
					end
				end
				
				-- Attempt to assign the group name otherwise
				GiveBadge( userId, groupName )
			end
		end
	end
end

local function BroadcastBadge( id, kBadge )
	Server.SendNetworkMessage( "Badge", BuildBadgeMessage( id, kBadge ), true)
end

function setClientBadgeEnum( client, kBadge )
	local id = client.GetId and client:GetId()
	if not id then return end
	kPlayerBadges[ id ] = kBadge
	local player = client:GetControllingPlayer()
	player.currentBadge = kBadge
	BroadcastBadge( id, kBadge )
end

function getClientBadgeEnum( client )
	if not client then return end
	local kPlayerBadge = kPlayerBadges[ client:GetId() ]
	if kPlayerBadge then
		return kPlayerBadge
	else
		return kBadges.None
	end
end

local function GetBadgeStrings( client, callback )
	local steamid = client.GetUserId and client:GetUserId() or 0
	if steamid < 1 then return end
	
	local sClientBadges = sServerBadges[ steamid ] or {}
	callback( sClientBadges )        
end

function foreachBadge( f )
	for id,kPlayerBadge in pairs( kPlayerBadges ) do
		f( id, kPlayerBadge )
	end
end

local function OnRequestBadge( client, message )
	local kBadge = message.badge
	if kBadge == getClientBadgeEnum( client ) then return end
	if client and kBadge then
		local function RequestCallback( sClientBadges )                
			if #sClientBadges > 0 and client.GetId then
				local authorized = TableContains( sClientBadges, kBadges[ kBadge ] ) 
				if authorized then
					setClientBadgeEnum( client, kBadge )
				else                    
					setClientBadgeEnum( client, kBadges[ sClientBadges[ 1 ] ] )
				end
			end
		end
		GetBadgeStrings( client, RequestCallback )
	end
end
Server.HookNetworkMessage( "Badge", OnRequestBadge )

local function OnClientConnect( client )
	foreachBadge( BroadcastBadge )
	local function RequestCallback( sClientBadges )
		for i, sClientBadge in ipairs( sClientBadges ) do
			Server.SendNetworkMessage( client, "Badge", BuildBadgeMessage( -1, kBadges[ sClientBadge ] ), true)
		end
	end
	GetBadgeStrings( client, RequestCallback )
end
Event.Hook( "ClientConnect", OnClientConnect )

local function OnClientDisconnect( client ) 
	kPlayerBadges[ client:GetId() ] = nil
end
Event.Hook( "ClientDisconnect", OnClientDisconnect )