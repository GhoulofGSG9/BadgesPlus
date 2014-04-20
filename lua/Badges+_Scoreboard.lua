--Badge_Client.lua Hooks

local clientIdToBadge = {}
local function OnReceiveBadge( message )	
	if not clientIdToBadge[ message.clientIndex ] then clientIdToBadge[ message.clientIndex ] = {} end
	local badge = kBadges[ message.badge ]
	if badge ~= "disabled" then
		clientIdToBadge[ message.clientIndex ][ message.badgerow ] = "ui/badges/" .. badge .. ".dds"
	else
		clientIdToBadge[ message.clientIndex ][ message.badgerow ] = nil
	end
end
addReceiveBadgeHook( OnReceiveBadge )

local function joinTwoTables( t1, t2 )
   for _, t in ipairs( t2 ) do
      table.insert( t1, t )
   end
   return t1
end

local OldBadges_GetBadgeTextures = Badges_GetBadgeTextures
function Badges_GetBadgeTextures( clientId, usecase )
	local textures = {}
	local badgeModTextures = clientIdToBadge[ clientId ]
	
	if badgeModTextures then
		for _, badgeModTexture in pairs( badgeModTextures ) do
			table.insert( textures, badgeModTexture )
		end
    end
    
    local hivetextures = OldBadges_GetBadgeTextures( clientId, usecase )
    textures = joinTwoTables( textures, hivetextures )
    
    return textures
end