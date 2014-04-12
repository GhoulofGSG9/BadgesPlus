-- temp cache of often used function
local StringFormat = string.format

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

local function OnConsoleBadge(sRequestedBadge)
	local sSavedBadge = Client.GetOptionString( "Badge", "" )
	if sRequestedBadge == nil or StringTrim(sRequestedBadge) == "" then
		Print( StringFormat( "Saved Badge: %s", sSavedBadge ))
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
