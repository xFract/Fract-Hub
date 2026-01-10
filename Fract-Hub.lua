local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

-- Prevent Multiple Instances (Singleton Pattern)
-- 以前に実行されたFluentインスタンスがあれば破壊して重複を防ぐ
if getgenv().FluentInstance then
    pcall(function() getgenv().FluentInstance:Destroy() end)
end
getgenv().FluentInstance = Fluent

-- Removed external SaveManager/InterfaceManager to provide robust keyless autosave

local HttpService = game:GetService("HttpService")
local ConfigFolder = "FructHub"
local ConfigFile = "AutoSave.json"

-- Custom AutoSave Logic
local function SaveSettings()
    if not isfolder(ConfigFolder) then makefolder(ConfigFolder) end
    
    local settings = {}
    for key, option in pairs(Fluent.Options) do
        if option.Value ~= nil then
            settings[key] = option.Value
        end
    end
    
    writefile(ConfigFolder .. "/" .. ConfigFile, HttpService:JSONEncode(settings))
end

local function LoadSettings()
    local path = ConfigFolder .. "/" .. ConfigFile
    if isfile(path) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(path))
        end)
        
        if success then
            for key, value in pairs(result) do
                if Fluent.Options[key] then
                    -- Safely set value
                    pcall(function() Fluent.Options[key]:SetValue(value) end)
                end
            end
        end
    end
end

local autoSaveThread
local function AutoSave()
    if autoSaveThread then task.cancel(autoSaveThread) end
    autoSaveThread = task.delay(1, function()
        SaveSettings()
    end)
end

local Window = Fluent:CreateWindow({
    Title = "Fract-Hub",
    SubTitle = "",
    TabWidth = 160,
    Size = UDim2.fromOffset(580, 460),
    Acrylic = true,
    Theme = "Amethyst",
    MinimizeKey = Enum.KeyCode.LeftControl
})

-- Minimize to Icon Logic
local guiName = "FluentMinimizeGui"

-- Cleanup existing MinimizeGui to prevent duplication
local function cleanupLegacyGui(name)
    if game.CoreGui:FindFirstChild(name) then
        game.CoreGui:FindFirstChild(name):Destroy()
    end
    if game.Players.LocalPlayer.PlayerGui:FindFirstChild(name) then
        game.Players.LocalPlayer.PlayerGui:FindFirstChild(name):Destroy()
    end
end
cleanupLegacyGui(guiName)

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = guiName
-- Parent logic: protect_gui or gethui or PlayerGui
if syn and syn.protect_gui then
    syn.protect_gui(ScreenGui)
    ScreenGui.Parent = game.CoreGui
elseif getgenv().gethui then
    ScreenGui.Parent = getgenv().gethui()
else
    ScreenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
end

local MinimizeBtn = Instance.new("ImageButton")
MinimizeBtn.Name = "MinimizeButton"
MinimizeBtn.Size = UDim2.fromOffset(50, 50)
MinimizeBtn.Position = UDim2.new(1, -60, 0, 10) -- Top Right
MinimizeBtn.Image = "rbxassetid://76725250292577"
MinimizeBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MinimizeBtn.BackgroundTransparency = 0.2
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Visible = false -- Hidden by default
MinimizeBtn.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MinimizeBtn

-- Draggable Logic
local UserInputService = game:GetService("UserInputService")
local dragging
local dragInput
local dragStart
local startPos
local lastDragTime = 0

local function update(input)
    local delta = input.Position - dragStart
    MinimizeBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    lastDragTime = tick()
end

MinimizeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MinimizeBtn.Position
        
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

MinimizeBtn.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        update(input)
    end
end)

-- Restore Logic on Click
MinimizeBtn.MouseButton1Click:Connect(function()
    -- Prevent click if dragged recently (0.1s cooldown)
    if tick() - lastDragTime < 0.1 then return end
    
    local root = rawget(Window, "Root") or (game.CoreGui:FindFirstChild("Fluent") and game.CoreGui.Fluent:FindFirstChild("Frame"))
    if root then
        root.Visible = true
        MinimizeBtn.Visible = false
    end
end)

-- Monitor Window Visibility to Show/Hide Icon
task.spawn(function()
    while task.wait(0.2) do
        if Fluent.Unloaded then break end
        
        local root = rawget(Window, "Root") or (game.CoreGui:FindFirstChild("Fluent") and game.CoreGui.Fluent:FindFirstChild("Frame"))
        
        -- If UI is hidden, show button (unless already shown)
        if root and not root.Visible then
             if not MinimizeBtn.Visible then MinimizeBtn.Visible = true end
        else
             if MinimizeBtn.Visible then MinimizeBtn.Visible = false end
        end
    end
end)


local Tabs = {}

local Tab_tab_main = Window:AddTab({ Title = "Main", Icon = "" })
Tabs["tab_main"] = Tab_tab_main

local Tab_7a054e48 = Window:AddTab({ Title = "Lobby", Icon = "" })
Tabs["7a054e48"] = Tab_7a054e48

Tab_7a054e48:AddDropdown("SelectedGameMode", {
    Title = "Gamemode",
    Description = "",
    Values = {"Default", "Raid", "Endless"},
    Multi = false,
    Default = 1,
    Callback = function(Value)
print("Game Mode Selected:", Value)
        AutoSave()
    end
})

Tab_7a054e48:AddDropdown("SelectedPlayerNum", {
    Title = "Player Count",
    Description = "",
    Values = {"1", "2", "3", "4"},
    Multi = false,
    Default = 1,
    Callback = function(Value)
print("Player Count Selected:", Value)
        AutoSave()
    end
})

Tab_7a054e48:AddDropdown("SelectedMapNum", {
    Title = "Map",
    Description = "",
    Values = {"Summon Gate", "Summon Station-1", "Summon Station-2", "Statue`s Cave"},
    Multi = false,
    Default = 1,
    Callback = function(Value)
print("Map Selected:", Value)
        AutoSave()
    end
})

Tab_7a054e48:AddDropdown("SelectedDiffNum", {
    Title = "Difficulty",
    Description = "",
    Values = {"Normal", "Hard", "Nightmare"},
    Multi = false,
    Default = 1,
    Callback = function(Value)
print("Difficulty Selected:", Value)
        AutoSave()
    end
})

Tab_7a054e48:AddToggle("IsFriendsOnly", {
    Title = "Friends Only",
    Description = "",
    Default = false,
    Callback = function(Value)
print("Friends Only Toggled:", Value)
        AutoSave()
    end
})

Tab_7a054e48:AddToggle("AutoLobbyToggle", {
    Title = "Auto Create",
    Description = "",
    Default = false,
    Callback = function(Value)
local remote = game:GetService("ReplicatedStorage"):WaitForChild("BridgeNet2"):WaitForChild("dataRemoteEvent")
local diffMap = { ["Normal"] = 1, ["Hard"] = 2, ["Nightmare"] = 3 }

-- PlaceId Check
if game.PlaceId ~= 100744519298647 then return end

if Value then
    task.spawn(function()
        while Fluent.Options['AutoLobbyToggle'].Value do
            -- Fetch current values from UI Options
            local pNum = tonumber(Fluent.Options['SelectedPlayerNum'].Value) or 1
            local gMode = Fluent.Options['SelectedGameMode'].Value or "Default"
            local mNum = tonumber(Fluent.Options['SelectedMapNum'].Value) or 1
            
            local rawDiff = Fluent.Options['SelectedDiffNum'].Value
            local dNum = diffMap[rawDiff] or 1
            
            local fOnly = Fluent.Options['IsFriendsOnly'].Value

            -- Construct BridgeNet2 packet structure
            local args = {
                {
                    {
                        "Play",    -- Action
                        pNum,      -- SelectedPlayerNum
                        gMode,     -- SelectedGameMode
                        mNum,      -- SelectedMapNum
                        dNum,      -- SelectedDiffNum
                        fOnly,     -- IsFriendsOnly
                        true       -- Validation Flag
                    },
                    " " -- BridgeNet2 Identifier
                }
            }

            remote:FireServer(unpack(args))
            task.wait(2.5)
        end
    end)
end
        AutoSave()
    end
})

Window:SelectTab(1)

Fluent:Notify({
    Title = "Fluent",
    Content = "The script has been loaded.",
    Duration = 8
})

-- Load saved settings at startup
LoadSettings()

local function OnClose()
    SaveSettings()
end
