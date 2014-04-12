--Badge_Client.lua Hooks

local clientIdToBadge = {}
local function OnReceiveBadge(message)
    clientIdToBadge[message.clientIndex] = "ui/badges/" .. kBadges[message.badge] .. ".dds"
end
addReceiveBadgeHook(OnReceiveBadge)

local OldBadges_GetBadgeTextures = Badges_GetBadgeTextures
function Badges_GetBadgeTextures( clientId, usecase )
	local textures = OldBadges_GetBadgeTextures( clientId, usecase )
	local badgeModTexture = clientIdToBadge[ clientId ]
	
	if badgeModTexture then
       table.insert( textures, badgeModTexture )
    end
    
    return textures
end