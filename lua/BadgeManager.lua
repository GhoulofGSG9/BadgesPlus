Script.Load("lua/Badges_Shared.lua")
Script.Load("lua/dkjson.lua") -- necessary because the library is not loaded when this script is loaded in ns2stats
local kBadgeServerUrl = "http://ns2c.herokuapp.com/"
local kPAX2012ProductId = 4931

-- Load all badge images. Custom badges will be loaded through here
do

    local function isOfficial(badgeFile)
        for i,info in ipairs(gBadgesData) do
            if info.unitStatusTexture == badgeFile then
                return true
            end
        end
        return false
    end
    
    local sBadges = { 'None' }
    local badgeFiles = { }
    Shared.GetMatchingFileNames("ui/badges/*.dds", false, badgeFiles)

    -- Texture for all badges is "ui/${name}.dds"
    for _, badgeFile in pairs(badgeFiles) do
        
        -- exclude official and _20.dds small versions of badges
        if not isOfficial(badgeFile) and not StringEndsWith(badgeFile, "_20.dds") then
            local _, _, sBadgeName = string.find(badgeFile, "ui/badges/(.*).dds")
            table.insert(sBadges, sBadgeName)
        end
        
    end
    
    kBadges = enum( sBadges )
end

-- reserved badges (can not be assigned by server)
local kReservedBadges = { kBadges.huze, kBadges.ensl_admin, kBadges.ensl_staff }

local kBadgeMessage = 
{
    clientIndex = "entityid",
    badge = "enum kBadges"
}

function BuildBadgeMessage(clientIndex, badge)
    local t = {}
    t.clientIndex       = clientIndex
    t.badge             = badge
    return t
end

Shared.RegisterNetworkMessage( "Badge", kBadgeMessage )

local function sBadgeExists(sBadge)
    return table.contains(kBadges, sBadge)
end

local function sBadgeReserved(sBadge)
    return table.contains(kReservedBadges, kBadges[sBadge])
end



if Client then

    local sServerBadges = {}
    local function getServerBadgeStrings(sClientBadges)
        table.adduniquetable(sServerBadges, sClientBadges)
    end

    function GetBadgeStrings(callback)

        Shared.SendHTTPRequest(kBadgeServerUrl.."q/badges/"..tostring(Client.GetSteamId()), "GET",
        function(response)
            
            local sClientBadges = json.decode(response)
            if sClientBadges == nil then
                sClientBadges = {}
            end
            getServerBadgeStrings(sClientBadges)
            callback(sClientBadges)
        end)
    end
    
    local receiveBadges = {}
    function addReceiveBadgeHook(func)
        table.insert(receiveBadges, func)
    end
    
    local function OnReceiveBadge(message)
        if message.clientIndex == -1 then
            local sBadge = kBadges[message.badge]
            table.insert(sServerBadges, sBadge)
            -- default to first badge if we haven't selected one
            if Client.GetOptionString("Badge", "") == "" then
                Print("Default Badge: " .. sBadge)
                Shared.ConsoleCommand("badge " .. sBadge)
            end
        else
            for i, func in ipairs(receiveBadges) do
                func(message)
            end
        end
    end
    Client.HookNetworkMessage("Badge", OnReceiveBadge)
    
    local function OnLoadComplete()
        local sSavedBadge = Client.GetOptionString("Badge", "")
        if sBadgeExists(sSavedBadge) and Client.GetIsConnected() then
            Client.SendNetworkMessage("Badge", { badge = kBadges[sSavedBadge] }, true)
        else 
            Client.SetOptionString("Badge", "") 
        end
    end
    Event.Hook("LoadComplete", OnLoadComplete)
    
    local function OnClientDisconnected()
        sServerBadges = {}
    end
    Event.Hook("ClientDisconnected", OnClientDisconnected)
    
    local function OnConsoleBadge(sRequestedBadge)
        local sSavedBadge = Client.GetOptionString("Badge", "")
        if sRequestedBadge == nil or StringTrim(sRequestedBadge) == "" then
            Print("Saved Badge: " .. sSavedBadge)
        elseif sRequestedBadge == "-" then
            Client.SetOptionString("Badge", "")
        elseif sRequestedBadge ~= sSavedBadge then
            Client.SetOptionString("Badge", sRequestedBadge)
            if sBadgeExists(sRequestedBadge) and Client.GetIsConnected() then
                Client.SendNetworkMessage("Badge", { badge = kBadges[sRequestedBadge] }, true)
            end
        end
    end
    Event.Hook("Console_badge", OnConsoleBadge)
    
    local function OnConsoleAllBadges()
        Print("--All Badges--")
        for _,sBadge in ipairs(kBadges) do
            Print(ToString(sBadge))
        end
    end
    Event.Hook("Console_allbadges", OnConsoleAllBadges)

    local function OnConsoleBadges()
        local function RequestCallback(sClientBadges)
            Print("--Available Badges--")
            for _,sBadge in ipairs(sClientBadges) do
                Print(sBadge)
            end
        end
        GetBadgeStrings(RequestCallback)
    end
    Event.Hook("Console_badges", OnConsoleBadges)

end



if Server then
    -- The currently selected badge for each player on the server
    local kPlayerBadges = {}
    -- Badges defined by the server operator or other mods
    local sServerBadges = {}
    
    function GiveBadge(userId, sBadgeName)
        local sClientBadges = sServerBadges[userId]
        if not sClientBadges then
            sClientBadges = {}
            sServerBadges[userId] = sClientBadges
        end
        if sBadgeExists(sBadgeName) and not sBadgeReserved(sBadgeName) then
            table.insertunique(sClientBadges, sBadgeName)
            return true
        end
        return false
    end
    
    -- Parse the server admin file
    local queryAddress = "q/badges/"
    do
        local function LoadConfigFile(fileName)
            Shared.Message("Loading Badge " .. "config://" .. fileName)
            local openedFile = io.open("config://" .. fileName, "r")
            if openedFile then
            
                local parsedFile = openedFile:read("*all")
                io.close(openedFile)
                return parsedFile
                
            end
            return nil
        end
        
        local function ParseJSONStruct(struct)
            return json.decode(struct) or {}
        end

        local SUID = LoadConfigFile("ServerUID.txt")
        if SUID then
            assert(SUID:len() == 32)
            queryAddress = "s/badges/" .. SUID .. "/"
            Print("Remote Config Server UUID: " .. SUID)
        end
    
        local serverAdmin = ParseJSONStruct(LoadConfigFile("ServerAdmin.json"))
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
                            table.insertunique(sGroupBadges, group.badge)
                        end
                        
                        -- Assign all badges for the group
                        for i, sGroupBadge in ipairs(sGroupBadges) do
                            local sGroupBadgeLower = sGroupBadge
                            if not GiveBadge(userId, sGroupBadgeLower) then
                                Print(groupName .. " is configured for a badge that non-existent or reserved badge: " .. sGroupBadge)
                            end
                        end
                    end
                    
                    -- Attempt to assign the group name otherwise
                    GiveBadge(userId, groupName)
                end
            end
        end
    end
    
    local function BroadcastBadge(id, kBadge)
        Server.SendNetworkMessage("Badge", BuildBadgeMessage(id, kBadge), true)
    end
    
    function setClientBadgeEnum(client, kBadge)
        local id = client:GetId()
        kPlayerBadges[id] = kBadge
        local player = client:GetControllingPlayer()
        player.currentBadge = kBadge
        BroadcastBadge(id, kBadge)
    end

    function getClientBadgeEnum(client)
        local kPlayerBadge = kPlayerBadges[client:GetId()]
        if kPlayerBadge then
            return kPlayerBadge
        else
            return kBadges.None
        end
    end
    
    local function getServerBadgeStrings(sClientBadges, client)
        local sServerDefinedBadges = sServerBadges[client:GetUserId()]
        if sServerDefinedBadges then
            table.addtable(sServerDefinedBadges, sClientBadges)
        end
    end
    
    function GetBadgeStrings(client, callback)
        local url = kBadgeServerUrl..queryAddress..tostring(client:GetUserId())
        
        Shared.SendHTTPRequest(url, "GET",
        function(response)
            
            local sClientBadges = json.decode(response)
            if sClientBadges == nil then
                sClientBadges = {}
            end
            getServerBadgeStrings(sClientBadges, client)
            callback(sClientBadges)
        end)
    end
    
    function foreachBadge(f)
        for id,kPlayerBadge in pairs(kPlayerBadges) do
            f(id, kPlayerBadge)
        end
    end

    local function OnRequestBadge(client, message)

        local kBadge = message.badge
        if client ~= nil and kBadge ~= nil then
            local function RequestCallback(sClientBadges)
                local authorized = table.contains(sClientBadges, kBadges[kBadge])
                if authorized then
                    setClientBadgeEnum(client, kBadge)
                else
                    if #sClientBadges > 1 then
                        setClientBadgeEnum(client, kBadges[sClientBadges[1]])
                    end
                end
            end
            GetBadgeStrings(client, RequestCallback)
        end
    end
    Server.HookNetworkMessage("Badge", OnRequestBadge)
    
    local function OnClientConnect(client)

        foreachBadge(BroadcastBadge)
        
        local function RequestCallback(sClientBadges)
            table.removeTable(kReservedBadges, sClientBadges)
            for i, sClientBadge in ipairs(sClientBadges) do
                Server.SendNetworkMessage(client, "Badge", BuildBadgeMessage(-1, kBadges[sClientBadge]), true)
            end
        end
        GetBadgeStrings(client, RequestCallback)
    end
    Event.Hook("ClientConnect", OnClientConnect)
    
    local function OnClientDisconnect(client) 
        kPlayerBadges[client:GetId()] = nil
    end
    Event.Hook("ClientDisconnect", OnClientDisconnect)
end