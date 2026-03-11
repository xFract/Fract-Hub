if getgenv().Script_Maid then
    pcall(function()
        getgenv().Script_Maid:Destroy()
    end)
end

local Fluent = loadstring(game:HttpGet("https://raw.githubusercontent.com/xFract/Fract-Hub/master/dist/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xFract/Fract-Hub/master/Addons/InterfaceManager.lua"))()
local DashboardManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/xFract/Fract-Hub/master/Addons/DashboardManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Fract Hub",
    SubTitle = "Base Template",
    TabWidth = 160,
    Size = UDim2.fromOffset(520, 380),
    Acrylic = true,
    Theme = "Cyan",
    Logo = "rbxassetid://92450040427767",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {}
Tabs.Dashboard = Window:AddTab({ Title = "Dashboard", Icon = "layout-dashboard" })
Window:AddTabSection("Main")
Tabs.Main = Window:AddTab({ Title = "Main", Icon = "swords" })

Window:AddTabSection("Settings")
Tabs.Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
Tabs.Config = Window:AddTab({ Title = "Config", Icon = "save" })

DashboardManager:SetLibrary(Fluent)
DashboardManager:BuildDashboardTab(Tabs.Dashboard, {
    GameName = "Base Template",
    Developer = "xFract",
    Discord = "https://discord.gg/fracthub",
})

local Options = Fluent.Options
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- ===== Maid Class for Cleanup =====
local Maid = {}
Maid.__index = Maid
function Maid.new()
    return setmetatable({ _tasks = {} }, Maid)
end
function Maid:GiveTask(task)
    if not task then error("Task cannot be false or nil", 2) end
    local taskId = #self._tasks + 1
    self._tasks[taskId] = task
    return taskId
end
function Maid:DoCleaning()
    local tasks = self._tasks
    for index, task in pairs(tasks) do
        if typeof(task) == "RBXScriptConnection" then
            task:Disconnect()
        elseif type(task) == "function" then
            task()
        elseif typeof(task) == "Instance" then
            task:Destroy()
        elseif type(task) == "table" and type(task.Destroy) == "function" then
            task:Destroy()
        elseif type(task) == "table" and type(task.DoCleaning) == "function" then
            task:DoCleaning()
        end
        tasks[index] = nil
    end
end
function Maid:Destroy()
    self:DoCleaning()
end

local scriptMaid = Maid.new()
getgenv().Script_Maid = scriptMaid
scriptMaid:GiveTask(function()
    pcall(function()
        if Window then Window:Destroy() end
    end)
end)

local LocalPlayer = Players.LocalPlayer

-- ===== Folder Setup =====
local FOLDER_NAME = "NewGameHub/GameName"
getgenv().Script_FolderName = FOLDER_NAME
pcall(function()
    if not isfolder("NewGameHub") then makefolder("NewGameHub") end
    if not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end
end)

-- ===== Variables =====
local isFarming = false
local currentTarget = nil

-- ===== Utility Functions =====
local function getValidTarget()
    -- ターゲット取得ロジックのプレースホルダー
    -- フォルダ内のNPCモデルを走査し、LocalPlayerから最も近い生きたHumanoidを持つモデルを返す処理を想定
    return nil
end

local function teleportToTarget()
    if not currentTarget or not currentTarget:FindFirstChild("Humanoid") or currentTarget.Humanoid.Health <= 0 then
        currentTarget = getValidTarget()
    end
    
    if currentTarget then
        local character = LocalPlayer.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local targetRoot = currentTarget:FindFirstChild("HumanoidRootPart")
            if targetRoot then
                -- 例: ターゲットの後ろへテレポートする
                local newCFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
                newCFrame = CFrame.new(newCFrame.Position, targetRoot.Position)
                character.HumanoidRootPart.CFrame = newCFrame
                character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
                character.HumanoidRootPart.AssemblyAngularVelocity = Vector3.zero
            end
        end
    end
end

-- ===== UI Elements =====
local FarmSection = Tabs.Main:AddSection("Farm Settings")

local AutoFarmToggle = FarmSection:AddToggle("AutoFarm", {
    Title = "Auto Farm",
    Default = false
})

local PositionDropdown = FarmSection:AddDropdown("Position", {
    Title = "Position",
    Values = {"Above", "Below", "Behind", "Front"},
    Default = "Above",
    Multi = false
})

local DistanceSlider = FarmSection:AddSlider("Distance", {
    Title = "Distance",
    Default = 15,
    Min = 0,
    Max = 50,
    Rounding = 0
})

local CombatSection = Tabs.Main:AddSection("Combat Settings")

local AutoAttackToggle = CombatSection:AddToggle("AutoAttack", {
    Title = "Auto Attack",
    Default = false
})

local AutoSkillToggle = CombatSection:AddToggle("AutoSkill", {
    Title = "Auto Skill",
    Default = false
})

AutoFarmToggle:OnChanged(function()
    isFarming = Options.AutoFarm.Value
end)

-- ===== Core Loops =====
scriptMaid:GiveTask(RunService.Heartbeat:Connect(function()
    if isFarming then
        pcall(teleportToTarget)
    end
end))

local isThreadRunning = true
local attackThread = task.spawn(function()
    while task.wait(0.1) and isThreadRunning do
        if isFarming and currentTarget then
            -- 攻撃ロジックのプレースホルダー（RemoteEventの発火等）
            pcall(function()
                -- game:GetService("ReplicatedStorage").Events.Attack:FireServer()
            end)
        end
    end
end)

scriptMaid:GiveTask(function()
    isThreadRunning = false
    task.cancel(attackThread)
end)

-- ===== Settings & Config Saving =====
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({})

InterfaceManager:SetFolder("FractHub")
SaveManager:SetFolder("FractHub/BaseTemplate")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Config)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
