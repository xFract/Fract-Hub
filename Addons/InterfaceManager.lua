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
        PerformanceMode = false,
        FPSCap = 60,
    }
    
    InterfaceManager.AFKThread = nil

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

    function InterfaceManager:SetPerformanceMode(enabled)
        local Settings = self.Settings
        Settings.PerformanceMode = (enabled == true)
        
        if not Settings.PerformanceMode then return end
        
        task.spawn(function()
            -- 照明の最適化
            pcall(function()
                local Lighting = game:GetService("Lighting")
                Lighting.GlobalShadows = false
                Lighting.FogEnd = 9e9
                Lighting.ShadowSoftness = 0
            end)
            
            -- パーツとエフェクトの最適化
            pcall(function()
                for _, obj in pairs(workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        obj.Material = Enum.Material.SmoothPlastic
                    elseif obj:IsA("Decal") or obj:IsA("Texture") then
                        obj.Transparency = 1
                    elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                        obj.Enabled = false
                    end
                end
            end)
        end)
    end

    function InterfaceManager:SetFPSCap(value)
        local Settings = self.Settings
        Settings.FPSCap = value
        
        if type(setfpscap) == "function" then
            setfpscap(value)
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
        
        -- Handle Performance Mode initial state
        if Settings.PerformanceMode then
            self:SetPerformanceMode(true)
        end
        
        -- Handle FPS Cap initial state
        if type(setfpscap) == "function" then
            self:SetFPSCap(Settings.FPSCap or 60)
        end

		local section = tab:AddSection("Interface")

		local InterfaceTheme = section:AddDropdown("InterfaceTheme", {
			Title = "Theme",
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
            Default = Settings.AutoMinimize, 
            Callback = function(Value) 
                Settings.AutoMinimize = Value
                InterfaceManager:SaveSettings()
            end 
        })
        
        OtherSection:AddToggle("AutoExecuteToggle", { 
            Title = "Auto Execute", 
            Default = Settings.AutoExecute, 
            Callback = function(Value) 
                Settings.AutoExecute = Value
                InterfaceManager:SaveSettings()
            end 
        })
        
        OtherSection:AddToggle("AntiAfkToggle", { 
            Title = "Anti AFK", 
            Default = Settings.AntiAFK, 
            Callback = function(Value) 
                InterfaceManager:SetAntiAFK(Value)
                InterfaceManager:SaveSettings()
            end 
        })
        
        OtherSection:AddToggle("PerformanceModeToggle", { 
            Title = "Performance Mode", 
            Default = Settings.PerformanceMode, 
            Callback = function(Value) 
                InterfaceManager:SetPerformanceMode(Value)
                InterfaceManager:SaveSettings()
            end 
        })

        OtherSection:AddSlider("FPSCapSlider", {
            Title = "FPS Cap",
            Default = Settings.FPSCap or 60,
            Min = 15,
            Max = 240,
            Rounding = 0,
            Callback = function(Value)
                InterfaceManager:SetFPSCap(Value)
                InterfaceManager:SaveSettings()
            end
        })
    end
end

return InterfaceManager