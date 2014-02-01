local function SelectBadge(self, id)
    
    for i = 1, #self.dlcIcons do
        local dlcIcon = self.dlcIcons[i]
        if(dlcIcon.id == id) then
            dlcIcon:SetBorderWidth(1)
        else
            dlcIcon:SetBorderWidth(0)
        end
    end
end

local kBadgeServerURL = "http://www.ns2c.com"

originalMenuCreateProfile = Class_ReplaceMethod( "GUIMainMenu", "CreateProfile",
function(self)    
    self.profileBackground = CreateMenuElement(self.menuBackground, "Image")
    self.profileBackground:SetCSSClass("profile")


    local eventCallbacks =
    {
        // Trigger initial animation
        OnShow = function(self)
        
            // Passing updateChildren == false to prevent updating of children
            self:SetCSSClass("profile", false)
            
        end,
        
        // Destroy all animation and reset state
        OnHide = function(self) end
    }
    
    self.profileBackground:AddEventCallbacks(eventCallbacks)
    
    // Create avatar icon.
    self.avatar = CreateMenuElement(self.profileBackground, "Image")
    self.avatar:SetCSSClass("avatar")
    self.avatar:SetBackgroundTexture("*avatar")
    
    --Start Mod
    LoadCSSFile("lua/menu/main_menu_badges.css")
    
    self.dlcIcons = {}
    self.badgePos = 0
    
    // create selectable badges - this only fits 8 badges, profileBackground must be expanded for more to work
    local function callback(badges)   
        for i, dlc in ipairs(badges) do
            local dlcIcon = CreateMenuElement(self.profileBackground, "Image")
            dlcIcon.id = dlc
            dlcIcon:SetCSSClass("badge")
            dlcIcon:SetLeftOffset(120 + (i - 1) % 7 * 36)
            dlcIcon:EnableHighlighting()
            dlcIcon:SetBackgroundTexture("ui/badges/"..dlc..".dds")
            if i <= self.badgePos or i > self.badgePos + 7  then
                dlcIcon:SetIsVisible(false)
            end
            
            local guimainmenu = self
            function dlcIcon:OnSendKey(key, down)
                if down then
                    SelectBadge(guimainmenu, dlcIcon.id)
                    Shared.ConsoleCommand("badge \"" .. dlcIcon.id .. "\"")
                end
            end
            table.insert(self.dlcIcons, dlcIcon)
        end
        
        local badge = Client.GetOptionString("Badge", "")
        if badge == "" then
            badge = badges[1] -- default to first badge if none are selected
        end
        
        SelectBadge(self, badge)
        
        if #badges > 7 then 
            --next button
            self.nextbadge = CreateMenuElement(self.profileBackground, "Image")
            self.nextbadge:SetCSSClass("badge")
            self.nextbadge:SetLeftOffset(120 + 7 * 36)
            self.nextbadge:SetBackgroundTexture("ui/badges/next.dds")
            
            local eventnextbadge =
            {
                OnClick = function(key, down)
                    self.badgePos = self.badgePos + 7
                    if self.badgePos > #self.dlcIcons then
                        self.badgePos = 0
                    end
                    for i, dlcIcon in ipairs(self.dlcIcons) do
                        if i <= self.badgePos or i > self.badgePos + 7  then
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
        end    
    end
    
    GetBadgeStrings(callback)
    --End Mod

    self.playerName = CreateMenuElement(self.profileBackground, "Link")
    self.playerName:SetCSSClass("profile")
    
    self.rankLevel = CreateMenuElement(self.profileBackground, "Link")
    self.rankLevel:SetCSSClass("rank_level")

    local eventCallbacks =
    {
        OnClick = function (self, buttonPressed)
            Client.ShowWebpage("http://hive.naturalselection2.com/profile/".. Client.GetSteamId())
		end,
		
		OnMouseIn = function (self, buttonPressed)
            MainMenu_OnMouseIn()
        end,
    }
    
    self.playerName:AddEventCallbacks(eventCallbacks)
    self.rankLevel:AddEventCallbacks(eventCallbacks)
end)