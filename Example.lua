	local HttpService = game:GetService("HttpService")
	
	-- Fetch the latest commit SHA to completely bypass GitHub raw caching
	local function GetLatestSHA()
		local success, result = pcall(function()
			-- Append tick to bypass Roblox's own HttpGet cache for the API request
			local apiUrl = "https://api.github.com/repos/xFract/Fract-Hub/commits/master?v=" .. tostring(tick())
			local response = game:HttpGet(apiUrl)
			local data = HttpService:JSONDecode(response)
			return data.sha
		end)
		if success and result then
			return result
		end
		return "master" -- Fallback
	end

	local latestSha = GetLatestSHA()

	local function GetFractURL(filepath)
		return "https://raw.githubusercontent.com/xFract/Fract-Hub/" .. latestSha .. "/" .. filepath
	end

	local Fluent = loadstring(game:HttpGet(GetFractURL("dist/main.lua")))()
	-- dawid-scripts component can remain on master w/o dynamic cache busting as it doesn't change often
	local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
	local InterfaceManager = loadstring(game:HttpGet(GetFractURL("Addons/InterfaceManager.lua")))()
	local DashboardManager = loadstring(game:HttpGet(GetFractURL("Addons/DashboardManager.lua")))()

local Window = Fluent:CreateWindow({
    Title = "Fract Hub",
    SubTitle = "Solo Hunter",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 380),
    Acrylic = true,
    Theme = "Cyan",
    Logo = "rbxassetid://92450040427767", -- ここにRobloxにアップロードしたロゴの画像IDを入れてください
    MinimizeKey = Enum.KeyCode.LeftControl
})

	-- ダッシュボードを最初に自動生成（タブ一覧の先頭に配置）
	DashboardManager:SetLibrary(Fluent)
	DashboardManager:BuildDashboardTab(Window, {
	    GameName = "Solo Hunter",
	    Developer = "xFract",
	    Discord = "https://discord.gg/fracthub",
	})

	local Tabs = {}

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
    -- AutoLevel Tab Elements（テスト要素をAutoLevelタブに配置）
	local FarmPosSection = Tabs.AutoLevel:AddSection("Position & Distance")
    local DamageIncrement = FarmPosSection:AddSlider("DamageIncrement", {
        Title = "Farm Distance",
        Description = "Set the distance to farm",
        Default = 5,
        Min = 1,
        Max = 20,
        Rounding = 1,
        Suffix = "Studs",
        Callback = function(Value)
            print("Farm Distance:", Value)
        end
    })

	local DropdownSection = Tabs.AutoLevel:AddSection("Target Selection")
    local TargetDropdown = DropdownSection:AddDropdown("TargetMob", {
        Title = "Target Mob",
        Description = "Select the mob to target",
        Values = {"AcademyTeacher", "Curse", "DesertBandit", "DesertBoss", "Thief", "Warrior", "Skeleton", "Dragon", "Goblin", "Slime"},
        Default = "Thief",
        Multi = false,
        Callback = function(Value)
            print("Target:", Value)
        end
    })

	local AutoLevelSection = Tabs.AutoLevel:AddSection("Auto Level")
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

	local LootSection = Tabs.AutoLevel:AddSection("Looting")
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
