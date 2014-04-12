Script.Load("lua/Badges_Shared.lua")

-- Load all badge images. Custom badges will be loaded through here
do

    local function isOfficial( badgeFile )
        for i,info in ipairs( gBadgesData ) do
            if info.unitStatusTexture == badgeFile then
                return true
            end
        end
        return false
    end
    
    local sBadges = { 'None' }
    local badgeFiles = { }
    Shared.GetMatchingFileNames( "ui/badges/*.dds", false, badgeFiles )

    -- Texture for all badges is "ui/${name}.dds"
    for _, badgeFile in pairs( badgeFiles ) do
        
        -- exclude official and _20.dds small versions of badges
        if not isOfficial( badgeFile ) and not StringEndsWith( badgeFile, "_20.dds" ) then
            local _, _, sBadgeName = string.find(badgeFile, "ui/badges/(.*).dds")
            table.insert( sBadges, sBadgeName )
        end
        
    end
    
    kBadges = enum( sBadges )
end

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

if Client then

    local sServerBadges = {}
	
	function GetBadgeStrings( callback )        
        local sClientBadges = sServerBadges
        callback( sClientBadges )        
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
            if Client.GetOptionString("Badge", "") == "" or Client.GetOptionString("Badge", "") == sBadge then
                Client.SetOptionString("Badge", "")
                Shared.ConsoleCommand("badge \"" .. sBadge .. "\"")
            end 
        else
            for i, func in ipairs(receiveBadges) do
                func(message)
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
    
    local function OnConsoleBadge(sRequestedBadge)
        local sSavedBadge = Client.GetOptionString( "Badge", "" )
        if sRequestedBadge == nil or StringTrim(sRequestedBadge) == "" then
            Print( "Saved Badge: " .. sSavedBadge )
        elseif sRequestedBadge == "-" then
            Client.SetOptionString( "Badge", "" )
        elseif sRequestedBadge ~= sSavedBadge then
            Client.SetOptionString( "Badge", sRequestedBadge )
            if sBadgeExists(sRequestedBadge) and Client.GetIsConnected() then
                Client.SendNetworkMessage( "Badge", { badge = kBadges[sRequestedBadge] }, true)
            end
        end
    end
    Event.Hook( "Console_badge", OnConsoleBadge )
    
    local function OnConsoleAllBadges()
        Print( "--All Badges--" )
        for _,sBadge in ipairs( kBadges ) do
            Print( ToString( sBadge ) )
        end
    end
    Event.Hook( "Console_allbadges", OnConsoleAllBadges )

    local function OnConsoleBadges()
        local function RequestCallback(sClientBadges)
            Print( "--Available Badges--" )
            for _,sBadge in ipairs( sClientBadges ) do
                Print( sBadge )
            end
        end
        GetBadgeStrings( RequestCallback )
    end
    Event.Hook( "Console_badges", OnConsoleBadges )

end



if Server then
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
            Shared.Message( "Loading Badge " .. "config://" .. fileName )
            local openedFile = io.open( "config://" .. fileName, "r" )
            if openedFile then
            
                local parsedFile = openedFile:read("*all")
                io.close(openedFile)
                return parsedFile
                
            end
            return nil
        end
        
        local function ParseJSONStruct( struct )
            return json.decode( struct ) or {}
        end
    
        local serverAdmin = ParseJSONStruct( LoadConfigFile("ServerAdmin.json") )
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
                        for i, sGroupBadge in ipairs( sGroupBadges ) do
                            if not GiveBadge( userId, sGroupBadge ) then
                                Print( groupName .. " is configured for a badge that non-existent or reserved badge: " .. sGroupBadge )
                            end
                        end
                    end
                    
                    -- Attempt to assign the group name otherwise
                    GiveBadge(userId, groupName)
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
                    local authorized = table.contains( sClientBadges, kBadges[ kBadge ] ) 
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
end