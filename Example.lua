local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/xFract/Fract-Hub/master/dist/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Maru Hub",
    SubTitle = "Solo Hunter",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Cyan",
    Logo = "rbxassetid://92450040427767", -- ここにRobloxにアップロードしたロゴの画像IDを入れてください
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Items = Window:AddTab({ Title = "Items", Icon = "sword" }),
    AutoJoin = Window:AddTab({ Title = "Auto Join", Icon = "log-in" }),
    Stats = Window:AddTab({ Title = "Stats", Icon = "bar-chart-2" }),
    Shop = Window:AddTab({ Title = "Shop", Icon = "shopping-cart" }),
    Teleport = Window:AddTab({ Title = "Teleport", Icon = "compass" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options

do
    -- Main Tab Elements
    local AutoAttack = Tabs.Main:AddToggle("AutoAttack", {
        Title = "Auto Attack", 
        Description = "Automatically attacks mobs",
        Default = false 
    })

    AutoAttack:OnChanged(function()
        print("Auto Attack:", Options.AutoAttack.Value)
    end)

    local DamageIncrement = Tabs.Main:AddSlider("DamageIncrement", {
        Title = "Damage Increment",
        Description = "If too many value will lag",
        Default = 5,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Callback = function(Value)
            print("Damage Increment:", Value)
        end
    })

    local AutoFarm = Tabs.Main:AddToggle("AutoFarm", {
        Title = "Auto Farm", 
        Description = "Automatically teleports to mobs",
        Default = false 
    })

    local AutoLootChests = Tabs.Main:AddToggle("AutoLootChests", {
        Title = "Auto Loot Chests", 
        Description = "Automatically loots chests",
        Default = false 
    })

    local AutoLootDrops = Tabs.Main:AddToggle("AutoLootDrops", {
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

InterfaceManager:SetFolder("MaruHub")
SaveManager:SetFolder("MaruHub/SoloHunter")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Maru Hub",
    Content = "Script loaded successfully.",
    Duration = 8
})

SaveManager:LoadAutoloadConfig()
