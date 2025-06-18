Print("Badges+ hotfix 344 loaded")

local gClientIdDevs = {}

function Badges_HasDevBadge(userId)
    return gClientIdDevs[userId]
end

local _Badges_SetBadge = Badges_SetBadge -- cache original function
function Badges_SetBadge(clientId, badgeid, column)
    local result = _Badges_SetBadge(clientId, badgeid, column)

    if result and (badgeid == gBadges.dev or badgeid == gBadges.community_dev) then
        local userId = Server.GetClientById(clientId):GetUserId()
        gClientIdDevs[userId] = true
    end
    
    return result
end