Script.Load("lua/BadgeManager.lua")

local ClientId2Badges = {}

Client.HookNetworkMessage("ClientBadges",
        function(msg) 
            //Print("received ClientBadges msg for client id = "..msg.clientId.." msg = "..ToString(msg) )
            ClientId2Badges[ msg.clientId ] = msg 
        end)
 
local clientIdToBadge = {}
local function OnReceiveBadge(message)
    clientIdToBadge[message.clientIndex] = "ui/badges/" .. kBadges[message.badge] .. ".dds"
end
addReceiveBadgeHook(OnReceiveBadge)
        
function Badges_GetBadgeTextures( clientId, usecase )

    local badges = ClientId2Badges[ clientId ]
    local badgeModTexture = clientIdToBadge[ clientId ]
    
    local textures = {}
    local textureKey = ( usecase == "scoreboard" and "scoreboardTexture" or "unitStatusTexture" )
        
    if badgeModTexture then
        table.insert( textures, badgeModTexture )
    end
    
    if badges then
        for _,info in ipairs( gBadgesData ) do
            if badges[ Badge2NetworkVarName( info.name ) ] == true then
                table.insert( textures, info[ textureKey ] )
            end
        end
    end
    
    return textures
end
