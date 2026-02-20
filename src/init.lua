local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = game:GetService("Workspace").CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Root = script
local Creator = require(Root.Creator)
local ElementsTable = require(Root.Elements)
local Acrylic = require(Root.Acrylic)
local Components = Root.Components
local NotificationModule = require(Components.Notification)

local New = Creator.New

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end


local function getTarget()
	if RunService:IsStudio() then
		return LocalPlayer.PlayerGui
	elseif gethui then
		return gethui()
	elseif syn and syn.protect_gui then
		return game:GetService("CoreGui")
	end
	return game:GetService("CoreGui")
end

local TargetParent = getTarget()

if getgenv then
	if getgenv().Fluent_UnloadOld then
		pcall(function() getgenv().Fluent_UnloadOld() end)
	end
	if getgenv().FluentInstance then
		pcall(function() getgenv().FluentInstance:Destroy() end)
		getgenv().FluentInstance = nil
	end
end

local function ForceCleanupGUI()
	local core = game:GetService("CoreGui")
	local player = game:GetService("Players").LocalPlayer
	local playerGui = player:FindFirstChild("PlayerGui")
	
	for _, child in ipairs(core:GetChildren()) do
		if child.Name == "Fluent" or child.Name == "FluentUI" or child.Name == "FluentMinimizeGui" then pcall(function() child:Destroy() end) end
	end
	
	if playerGui then
		for _, child in ipairs(playerGui:GetChildren()) do
			if child.Name == "Fluent" or child.Name == "FluentUI" or child.Name == "FluentMinimizeGui" then pcall(function() child:Destroy() end) end
		end
	end
	
	if getgenv and getgenv().gethui then
		local hui = getgenv().gethui()
		if hui then 
			for _, child in ipairs(hui:GetChildren()) do
				if child.Name == "Fluent" or child.Name == "FluentUI" or child.Name == "FluentMinimizeGui" then pcall(function() child:Destroy() end) end
			end
		end
	end
end

ForceCleanupGUI()
task.wait(0.1)
ForceCleanupGUI()
task.wait(0.1)

local GUI = New("ScreenGui", {
	Name = "FluentUI",
	Parent = TargetParent,
})
ProtectGui(GUI)
NotificationModule:Init(GUI)

local Library = {
	Version = "1.1.0",

	OpenFrames = {},
	Options = {},
	Themes = require(Root.Themes).Names,

	Window = nil,
	WindowFrame = nil,
	Unloaded = false,

	Theme = "Cyan",
	DialogOpen = false,
	UseAcrylic = false,
	Acrylic = false,
	Transparency = true,
	MinimizeKeybind = nil,
	MinimizeKey = Enum.KeyCode.LeftControl,

	GUI = GUI,
}

function Library:SafeCallback(Function, ...)
	if not Function then
		return
	end

	local Success, Event = pcall(Function, ...)
	if not Success then
		local _, i = Event:find(":%d+: ")

		if not i then
			return Library:Notify({
				Title = "Interface",
				Content = "Callback error",
				SubContent = Event,
				Duration = 5,
			})
		end

		return Library:Notify({
			Title = "Interface",
			Content = "Callback error",
			SubContent = Event:sub(i + 1),
			Duration = 5,
		})
	end
end

function Library:Round(Number, Factor)
	if Factor == 0 then
		return math.floor(Number)
	end
	Number = tostring(Number)
	return Number:find("%.") and tonumber(Number:sub(1, Number:find("%.") + Factor)) or Number
end

local Icons = require(Root.Icons).assets
function Library:GetIcon(Name)
	if Name ~= nil and Icons["lucide-" .. Name] then
		return Icons["lucide-" .. Name]
	end
	return nil
end

local Elements = {}
Elements.__index = Elements
Elements.__namecall = function(Table, Key, ...)
	return Elements[Key](...)
end

for _, ElementComponent in ipairs(ElementsTable) do
	Elements["Add" .. ElementComponent.__type] = function(self, Idx, Config)
		ElementComponent.Container = self.Container
		ElementComponent.Type = self.Type
		ElementComponent.ScrollFrame = self.ScrollFrame
		ElementComponent.Library = Library

		return ElementComponent:New(Idx, Config)
	end
end

Library.Elements = Elements

function Library:CreateWindow(Config)
	assert(Config.Title, "Window - Missing Title")

	if Library.Window then
		print("You cannot create more than one window.")
		return
	end

	Library.MinimizeKey = Config.MinimizeKey or Enum.KeyCode.LeftControl
	Library.UseAcrylic = Config.Acrylic or false
	Library.Acrylic = Config.Acrylic or false
	Library.Theme = Config.Theme or "Cyan"
	if Config.Acrylic then
		Acrylic.init()
	end

	local Window = require(Components.Window)({
		Parent = GUI,
		Size = Config.Size,
		Title = Config.Title,
		SubTitle = Config.SubTitle,
		TabWidth = Config.TabWidth,
		Logo = Config.Logo,
	})

	Library.Window = Window
	Library:SetTheme(Config.Theme)

	return Window
end

function Library:SetTheme(Value)
	if Library.Window and table.find(Library.Themes, Value) then
		Library.Theme = Value
		Creator.UpdateTheme()
	end
end

function Library:Destroy()
	Library.Unloaded = true
	if Library.Window then
		if Library.UseAcrylic then
			Library.Window.AcrylicPaint.Model:Destroy()
		end
	end
	Creator.Disconnect()
	if Library.GUI then
		Library.GUI:Destroy()
	end
end

function Library:ToggleAcrylic(Value)
	if Library.Window then
		if Library.UseAcrylic then
			Library.Acrylic = Value
			Library.Window.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
			if Value then
				Acrylic.Enable()
			else
				Acrylic.Disable()
			end
		end
	end
end

function Library:ToggleTransparency(Value)
	if Library.Window then
		Library.Window.AcrylicPaint.Frame.Background.BackgroundTransparency = Value and 0.35 or 0
	end
end

function Library:Notify(Config)
	return NotificationModule:New(Config)
end

if getgenv then
	getgenv().Fluent = Library
	getgenv().FluentInstance = Library
	getgenv().Fluent_UnloadOld = function()
		if not Library.Unloaded then
			Library:Destroy()
		end
	end
end

return Library
