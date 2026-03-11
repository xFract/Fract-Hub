	local function GetURL(script_url)
		return script_url .. "?v=" .. tostring(math.floor(tick()))
	end

	local Fluent = loadstring(game:HttpGet(GetURL("https://raw.githubusercontent.com/xFract/Fract-Hub/master/dist/main.lua")))()
	local SaveManager = loadstring(game:HttpGet(GetURL("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua")))()
	local InterfaceManager = loadstring(game:HttpGet(GetURL("https://raw.githubusercontent.com/xFract/Fract-Hub/master/Addons/InterfaceManager.lua")))()

local Window = Fluent:CreateWindow({
    Title = "Fract Hub",
    SubTitle = "Solo Hunter",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Cyan",
    Logo = "rbxassetid://92450040427767", -- ここにRobloxにアップロードしたロゴの画像IDを入れてください
    MinimizeKey = Enum.KeyCode.LeftControl
})

	Window:AddTabSection("Dashboard")
	local Tabs = {
		Main = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" })
	}

	Window:AddTabSection("Farming")
	Tabs.AutoLevel = Window:AddTab({ Title = "Auto Level", Icon = "trending-up" })
	Tabs.TitleChanger = Window:AddTab({ Title = "Title Changer", Icon = "award" })

	Window:AddTabSection("Boss Farm")
	Tabs.BossFarm = Window:AddTab({ Title = "Boss Farm", Icon = "skull" })

	Window:AddTabSection("Combat")
	Tabs.Combat = Window:AddTab({ Title = "Combat", Icon = "sword" })

	Window:AddTabSection("Artifacts")
	Tabs.Artifacts = Window:AddTab({ Title = "Artifacts", Icon = "gem" })

	Window:AddTabSection("MISC")
	Tabs.Misc = Window:AddTab({ Title = "MISC", Icon = "sliders" })
	Tabs.Rerolls = Window:AddTab({ Title = "Rerolls", Icon = "dices" })
	
	Window:AddTabSection("Settings")
	Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })

local Options = Fluent.Options

do
    -- Main Tab Elements
	local FarmPosSection = Tabs.Main:AddSection("Position & Distance")
    local DamageIncrement = FarmPosSection:AddSlider("DamageIncrement", {
        Title = "Farm Distance",
        Description = "Set the distance to farm",
        Default = 5,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Callback = function(Value)
            print("Farm Distance:", Value)
        end
    })

	local AutoLevelSection = Tabs.Main:AddSection("Auto Level")
    local AutoFarm = AutoLevelSection:AddToggle("AutoFarm", {
        Title = "Auto Level", 
        Description = "Automatically levels up",
        Default = false 
    })

    local AutoAttack = AutoLevelSection:AddToggle("AutoAttack", {
        Title = "Auto Attack", 
        Description = "Automatically attacks mobs",
        Default = false 
    })

    AutoAttack:OnChanged(function()
        print("Auto Attack:", Options.AutoAttack.Value)
    end)

	local LootSection = Tabs.Main:AddSection("Looting")
    local AutoLootChests = LootSection:AddToggle("AutoLootChests", {
        Title = "Auto Loot Chests", 
        Description = "Automatically loots chests",
        Default = false 
    })

    local AutoLootDrops = LootSection:AddToggle("AutoLootDrops", {
        Title = "Auto Loot Drops", 
        Description = "Automatically loots drops",
        Default = false 
    })
end

-- Addons Configuration
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FractHub")
SaveManager:SetFolder("FractHub/SoloHunter")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fract Hub",
    Content = "Script loaded successfully.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
