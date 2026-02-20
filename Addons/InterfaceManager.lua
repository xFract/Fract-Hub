local httpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local InterfaceManager = {} do
	InterfaceManager.Folder = "FluentSettings"
    InterfaceManager.Settings = {
        Theme = "Cyan",
        Acrylic = false,
        Transparency = false,
        MenuKeybind = "LeftControl",
        AutoMinimize = false,
        AutoExecute = false,
        AntiAFK = false,
        AutoRejoin = false,
        PrivateServerLink = "",
    }
    
    InterfaceManager.AFKThread = nil
    InterfaceManager.IsRejoining = false

    function InterfaceManager:SetFolder(folder)
		self.Folder = folder;
		self:BuildFolderTree()
	end

    function InterfaceManager:SetLibrary(library)
		self.Library = library
	end

    function InterfaceManager:BuildFolderTree()
		local paths = {}

		local parts = self.Folder:split("/")
		for idx = 1, #parts do
			paths[#paths + 1] = table.concat(parts, "/", 1, idx)
		end

		table.insert(paths, self.Folder)
		table.insert(paths, self.Folder .. "/settings")

		for i = 1, #paths do
			local str = paths[i]
			if not isfolder(str) then
				makefolder(str)
			end
		end
	end

    function InterfaceManager:SaveSettings()
        writefile(self.Folder .. "/options.json", httpService:JSONEncode(InterfaceManager.Settings))
    end

    function InterfaceManager:LoadSettings()
        local path = self.Folder .. "/options.json"
        if isfile(path) then
            local data = readfile(path)
            local success, decoded = pcall(httpService.JSONDecode, httpService, data)

            if success then
                for i, v in next, decoded do
                    InterfaceManager.Settings[i] = v
                end
            end
        end
    end

    function InterfaceManager:SetAntiAFK(enabled)
        local Settings = self.Settings
        Settings.AntiAFK = (enabled == true)
        
        if self.AFKThread then 
            task.cancel(self.AFKThread)
            self.AFKThread = nil 
        end
        
        if Settings.AntiAFK then
            self.AFKThread = task.spawn(function()
                while Settings.AntiAFK do
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new())
                    task.wait(60)
                end
            end)
        end
    end

    function InterfaceManager:BindAutoRejoin()
        local function triggerRejoin()
            if not self.Settings.AutoRejoin or self.IsRejoining then return end
            self.IsRejoining = true
            task.wait(2)

            local ts = game:GetService("TeleportService")
            local link = self.Settings.PrivateServerLink or ""

            if link ~= "" then
                -- Try to extract JobId/PrivateServerLink from URL if they pasted a link
                -- or if it's just raw code, we use TeleportToPrivateServer
                -- But Roblox's API for client-sided VIP server jumping usually relies on TeleportToPlaceInstance for JobId or we can just try invoking the URI
                if link:match("privateServerLinkCode=") then
                    local code = link:match("privateServerLinkCode=([^&]+)")
                    ts:TeleportToPrivateServer(game.PlaceId, code, {Players.LocalPlayer})
                else
                    -- Fallback: If it's just a JobId or VIP access code string
                    ts:TeleportToPrivateServer(game.PlaceId, link, {Players.LocalPlayer})
                end
            elseif #game.JobId > 0 then
                ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
            else
                ts:Teleport(game.PlaceId, Players.LocalPlayer)
            end
            task.wait(5)
            self.IsRejoining = false
        end

        local CoreGui = game:GetService("CoreGui")
        local success, promptOverlay = pcall(function()
            return CoreGui:FindFirstChild("RobloxPromptGui"):FindFirstChild("promptOverlay")
        end)

        if success and promptOverlay then
            promptOverlay.ChildAdded:Connect(function(child)
                if child.Name == 'ErrorPrompt' then
                    triggerRejoin()
                end
            end)
        end
        game:GetService("GuiService").ErrorMessageChanged:Connect(function()
            triggerRejoin()
        end)
    end

    function InterfaceManager:BindTeleportAutoExecute()
        local Settings = self.Settings
        local queued = false
        if not Players.LocalPlayer then return end
        
        Players.LocalPlayer.OnTeleport:Connect(function()
            if queued or not Settings.AutoExecute then return end
            local q = (syn and syn.queue_on_teleport) or queue_on_teleport or (fluxus and fluxus.queue_on_teleport)
            if q then
                q([[repeat task.wait() until game:IsLoaded(); loadstring(game:HttpGet("https://fructhub.vercel.app/api/loader-script"))()]])
                queued = true
            end
        end)
    end

    function InterfaceManager:BuildInterfaceSection(tab)
        assert(self.Library, "Must set InterfaceManager.Library")
		local Library = self.Library
        local Settings = InterfaceManager.Settings

        InterfaceManager:LoadSettings()
        
        -- Start AutoExecute Binder
        self:BindTeleportAutoExecute()
        
        -- Start AutoRejoin Binder
        self:BindAutoRejoin()
        
        -- Handle AutoMinimize if on initial load
        if Settings.AutoMinimize and Library.Window then
            -- We spawn this to let the UI finish setting up first if needed
            task.spawn(function()
                if not Library.Window.Minimized then
                    Library.Window:Minimize()
                end
            end)
        end
        -- Handle AntiAFK initial state
        if Settings.AntiAFK then
            self:SetAntiAFK(true)
        end

		local section = tab:AddSection("Interface")

		local InterfaceTheme = section:AddDropdown("InterfaceTheme", {
			Title = "Theme",
			Description = "Changes the interface theme.",
			Values = Library.Themes,
			Default = Settings.Theme,
			Callback = function(Value)
				Library:SetTheme(Value)
                Settings.Theme = Value
                InterfaceManager:SaveSettings()
			end
		})

        InterfaceTheme:SetValue(Settings.Theme)
	
		if Library.UseAcrylic then
			section:AddToggle("AcrylicToggle", {
				Title = "Acrylic",
				Description = "The blurred background requires graphic quality 8+",
				Default = Settings.Acrylic,
				Callback = function(Value)
					Library:ToggleAcrylic(Value)
                    Settings.Acrylic = Value
                    InterfaceManager:SaveSettings()
				end
			})
		end
	
		section:AddToggle("TransparentToggle", {
			Title = "Transparency",
			Description = "Makes the interface transparent.",
			Default = Settings.Transparency,
			Callback = function(Value)
				Library:ToggleTransparency(Value)
				Settings.Transparency = Value
                InterfaceManager:SaveSettings()
			end
		})
	
		local MenuKeybind = section:AddKeybind("MenuKeybind", { Title = "Minimize Bind", Default = Settings.MenuKeybind })
		MenuKeybind:OnChanged(function()
			Settings.MenuKeybind = MenuKeybind.Value
            InterfaceManager:SaveSettings()
		end)
		Library.MinimizeKeybind = MenuKeybind
        
        -- Other Section for Additional Modules
        local OtherSection = tab:AddSection("Other")
        
        OtherSection:AddToggle("AutoMinimizeToggle", { 
            Title = "Auto Minimize", 
            Description = "Starts the hub minimized.", 
            Default = Settings.AutoMinimize, 
            Callback = function(Value) 
                Settings.AutoMinimize = Value
                InterfaceManager:SaveSettings()
            end 
        })
        
        OtherSection:AddToggle("AutoExecuteToggle", { 
            Title = "Auto Execute", 
            Description = "Re-executes the script upon teleport.", 
            Default = Settings.AutoExecute, 
            Callback = function(Value) 
                Settings.AutoExecute = Value
                InterfaceManager:SaveSettings()
            end 
        })
        
        OtherSection:AddToggle("AntiAfkToggle", { 
            Title = "Anti AFK", 
            Description = "Prevents being kicked for idling.", 
            Default = Settings.AntiAFK, 
            Callback = function(Value) 
                InterfaceManager:SetAntiAFK(Value)
                InterfaceManager:SaveSettings()
            end 
        })
        
        OtherSection:AddToggle("AutoRejoinToggle", { 
            Title = "Auto Rejoin", 
            Description = "Automatically rejoins the server if you get kicked or disconnected.", 
            Default = Settings.AutoRejoin, 
            Callback = function(Value) 
                Settings.AutoRejoin = Value
                InterfaceManager:SaveSettings()
            end 
        })

        OtherSection:AddInput("PrivateServerLink", {
            Title = "Private Server Code / Link",
            Description = "Paste your VIP server link or code here for Auto Rejoin.",
            Default = Settings.PrivateServerLink,
            Numeric = false,
            Finished = true,
            Placeholder = "VIP Server Link/Code",
            Callback = function(Value)
                Settings.PrivateServerLink = Value
                InterfaceManager:SaveSettings()
            end
        })

        OtherSection:AddButton({
            Title = "Rejoin",
            Description = "Rejoins the current server (Public or Private).",
            Callback = function()
                local ts = game:GetService("TeleportService")
                if #game.JobId > 0 then
                    ts:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
                else
                    ts:Teleport(game.PlaceId, Players.LocalPlayer)
                end
            end
        })

        OtherSection:AddButton({
            Title = "Server Hop",
            Description = "Joins a different public server.",
            Callback = function()
                game:GetService("TeleportService"):Teleport(game.PlaceId, Players.LocalPlayer)
            end
        })
    end
end

return InterfaceManager