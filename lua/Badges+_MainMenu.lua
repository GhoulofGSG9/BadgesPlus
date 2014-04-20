Script.Load("lua/menu/GUIMainMenu.lua") --262 fix

local function SelectBadge(self, id, row)    
    for i = 1, #self.dlcIcons[row] do
        local dlcIcon = self.dlcIcons[row][i]
        if dlcIcon.id == id then
            dlcIcon:SetBorderWidth(1)
        else
            dlcIcon:SetBorderWidth(0)
        end
    end
end

local function GetTotalRows( badges )
	local i = 0
	for t, _ in pairs( badges ) do
		i = t
	end
	return i
end

originalMenuCreateProfile = Class_ReplaceMethod( "GUIMainMenu", "CreateProfile",
function(self)
    --first call original method
    originalMenuCreateProfile(self)
    
    --now let's do badges+ stuff
    LoadCSSFile("lua/menu/main_menu_badges.css")
    
    self.dlcIcons = {}
    self.badgePos = 0
    
    
    --create selectable badges - this only fits 8 buttons, profileBackground must be expanded for more to work
    local function callback( badges )
		self.totalRows = GetTotalRows( badges )
		self.badgeRow = self.totalRows
		
		if self.totalRows > 1 then 
            --next button
            self.switchbadgerow = CreateMenuElement( self.profileBackground, "Image" )
            self.switchbadgerow:SetCSSClass( "badge" )
            self.switchbadgerow:SetLeftOffset( 120 )
            self.switchbadgerow:SetBackgroundTexture( "ui/badges/down.dds" )
            
            local eventnextbadgerow =
            {
                OnClick = function(key, down)
                    repeat
						self.badgeRow = self.badgeRow + 1 
						if self.badgeRow > self.totalRows then self.badgeRow = 1 end
                    until self.dlcIcons[ self.badgeRow ] ~= nil and #self.dlcIcons[ self.badgeRow ] > 0
                    self.badgePos = 0
                    
                    for row, rowbadges in pairs( self.dlcIcons ) do
						if row == self.badgeRow then
							if #rowbadges > 6 then
								self.nextbadge:SetIsVisible( true )
							else
								self.nextbadge:SetIsVisible( false )
							end
						end
						
						for i, dlcIcon in ipairs( rowbadges ) do
							if row ~= self.badgeRow or i <= self.badgePos or i > self.badgePos + 6  then
								dlcIcon:SetIsVisible( false )
							else
								dlcIcon:SetIsVisible( true )
							end
						end
                    end
                end,
                
                OnMouseIn = function (self, buttonPressed)
                    MainMenu_OnMouseIn()
                end,
            }
            
            self.switchbadgerow:AddEventCallbacks( eventnextbadgerow )
        end
        
		for row, rowbadges in pairs( badges ) do
			for i, dlc in ipairs( rowbadges ) do
				local dlcIcon = CreateMenuElement(self.profileBackground, "Image")
				dlcIcon.id = dlc
				dlcIcon:SetCSSClass( "badge" )
				dlcIcon:SetLeftOffset( 156 + ( i - 1 ) % 6 * 36 )
				dlcIcon:EnableHighlighting()
				dlcIcon:SetBackgroundTexture( "ui/badges/".. dlc .. ".dds" )
				if row ~= self.badgeRow or i <= self.badgePos or i > self.badgePos + 6  then
					dlcIcon:SetIsVisible( false )
				end
				
				local guimainmenu = self
				function dlcIcon:OnSendKey(key, down)
					if down then
						SelectBadge( guimainmenu, dlcIcon.id, row)
						Shared.ConsoleCommand("badge \"" .. dlcIcon.id .. "\" " .. row )
					end
				end
				
				if not self.dlcIcons[ row ] then self.dlcIcons[ row ] = {} end
				table.insert( self.dlcIcons[ row ], dlcIcon)
			end
        end
        
		--next button
		self.nextbadge = CreateMenuElement(self.profileBackground, "Image")
		self.nextbadge:SetCSSClass("badge")
		self.nextbadge:SetLeftOffset(120 + 7 * 36)
		self.nextbadge:SetBackgroundTexture("ui/badges/next.dds")
		
		local eventnextbadge =
		{
			OnClick = function(key, down)
				self.badgePos = self.badgePos + 6
				local dlcIcons = self.dlcIcons[ self.badgeRow ]
				if self.badgePos > #dlcIcons  then
					self.badgePos = 0
				end
				for i, dlcIcon in ipairs( dlcIcons ) do
					if i <= self.badgePos or i > self.badgePos + 6  then
						dlcIcon:SetIsVisible(false)
					else
						dlcIcon:SetIsVisible(true)
					end
				end
			end,
			
			OnMouseIn = function (self, buttonPressed)
				MainMenu_OnMouseIn()
			end,
		}		
		self.nextbadge:AddEventCallbacks(eventnextbadge)
		
		if not self.dlcIcons[ self.badgeRow ] or #self.dlcIcons[ self.badgeRow ] <= 6 then self.nextbadge:SetIsVisible(false) end
    end
    
    GetBadgeStrings(callback)
end)