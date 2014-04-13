-- temp cache of often used function
local StringFormat = string.format

local function OnConsoleBadges()
	local function RequestCallback(sClientBadges)
		Print( "--Available Badges--" )
		for _, sBadgeRows in pairs( sClientBadges ) do
			for _, sBadge in ipairs( sBadgeRows ) do
				Print( sBadge )
			end
		end
	end
	GetBadgeStrings( RequestCallback )
end
Event.Hook( "Console_badges", OnConsoleBadges )

local function OnConsoleBadge( sRequestedBadge, Row)
	Row = tonumber( Row )
	if not Row or Row < 0 or Row > 10 then Row = 3 end
	
	local sSavedBadge = Client.GetOptionString( StringFormat( "Badge%s", Row ), "" )
	
	if not sRequestedBadge or StringTrim( sRequestedBadge ) == "" then
		Print( StringFormat( "Saved Badge: %s", sSavedBadge ))
	elseif sRequestedBadge == "-" then
		Client.SetOptionString( StringFormat("Badge%s", Row ), "" )
	elseif sRequestedBadge ~= sSavedBadge and GetClientOwnBadge( sRequestedBadge, Row ) then
		Client.SetOptionString( StringFormat( "Badge%s", Row ), sRequestedBadge )
		Client.SendNetworkMessage( "Badge", { badge = kBadges[ sRequestedBadge ], badgerow = Row }, true)
	elseif sRequestedBadge == sSavedBadge then
		Print( "You allready have selected the requested badge" )
	else
		Print( "Either you don't own the requested badge at this server or it doesn't exist." )
	end
end
Event.Hook( "Console_badge", OnConsoleBadge )

local function OnConsoleAllBadges()
	Print( "--All Badges--" )
	for _, sBadge in ipairs( kBadges ) do
		Print( ToString( sBadge ) )
	end
end
Event.Hook( "Console_allbadges", OnConsoleAllBadges )
