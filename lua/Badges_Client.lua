Script.Load("lua/BadgeManager.lua")

local ClientId2Badges = {}

Client.HookNetworkMessage("ClientBadges",
        function(msg) 
            //Print("received ClientBadges msg for client id = "..msg.clientId.." msg = "..ToString(msg) )
            ClientId2Badges[ msg.clientId ] = msg 
        end)

-- Badge mod
local clientIdToBadge = {}
local function OnReceiveBadge(message)
    clientIdToBadge[message.clientIndex] = "ui/badges/" .. kBadges[message.badge] .. ".dds"
end
addReceiveBadgeHook(OnReceiveBadge)
        
function Badges_GetBadgeTextures( clientId, usecase )

    local badges = ClientId2Badges[ clientId ]

    if badges then

        local textures = {}
        local textureKey = (usecase == "scoreboard" and "scoreboardTexture" or "unitStatusTexture")

        local badgeModTexture = clientIdToBadge[clientId]
        if badgeModTexture then
            table.insert(textures, badgeModTexture)
        end
        
        for _,info in ipairs(gBadgesData) do
            if badges[ Badge2NetworkVarName(info.name) ] == true then
                table.insert( textures, info[textureKey] )
            end
        end

        return textures

    else
        return {}
    end

end
