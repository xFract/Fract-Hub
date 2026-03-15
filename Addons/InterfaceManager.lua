local httpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

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
        AutoRejoin = false,
        LowPlayerHop = false,
        StaffDetector = false,
        WebhookURL = "",
    }
    
    InterfaceManager.AFKThread = nil
    InterfaceManager.IsRejoining = false
    InterfaceManager.IsHopping = false

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

    function InterfaceManager:Notify(title, content, subContent)
        if self.Library and self.Library.Notify then
            self.Library:Notify({
                Title = title,
                Content = content,
                SubContent = subContent,
                Duration = 6,
            })
        end
    end

    -- Discord Webhookへの通知送信
    function InterfaceManager:SendWebhook(title, description)
        local webhookUrl = self.Settings.WebhookURL
        if not webhookUrl or webhookUrl == "" then return end
        
        task.spawn(function()
            pcall(function()
                local payload = httpService:JSONEncode({
                    embeds = {{
                        title = title,
                        description = description,
                        color = 16711680, -- 赤色で警告を視覚化
                        footer = { text = "Fract-Hub Staff Detector" },
                        timestamp = DateTime.now():ToIsoDate()
                    }}
                })
                
                -- エクスプロイト環境のHTTPリクエスト関数を検出して使用
                local httpRequest = (syn and syn.request) or request or http_request or (http and http.request)
                if httpRequest then
                    httpRequest({
                        Url = webhookUrl,
                        Method = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body = payload
                    })
                end
            end)
        end)
    end

    -- サーバー移動（Low Player Hop設定対応）
    function InterfaceManager:ServerHop()
        if self.IsHopping then return end
        self.IsHopping = true
        
        task.spawn(function()
            local lowPlayerOnly = self.Settings.LowPlayerHop == true

            local success, result = pcall(function()
                local url = string.format(
                    "https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100",
                    game.PlaceId
                )
                local response = game:HttpGet(url)
                return httpService:JSONDecode(response)
            end)
            
            if not success or not result or not result.data then
                -- API取得失敗時はランダムサーバーへテレポート
                pcall(function()
                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                end)
                self.IsHopping = false
                return
            end
            
            local currentJobId = game.JobId
            local targetServer = nil
            
            for _, server in ipairs(result.data) do
                -- 自分がいるサーバーは除外
                if server.id ~= currentJobId and server.playing and server.maxPlayers then
                    if lowPlayerOnly then
                        -- 過疎サーバーを優先（プレイヤー数が最大人数の30%未満）
                        if server.playing < (server.maxPlayers * 0.3) then
                            targetServer = server
                            break
                        end
                    else
                        targetServer = server
                        break
                    end
                end
            end
            
            pcall(function()
                if targetServer then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, targetServer.id, Players.LocalPlayer)
                else
                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                end
            end)
            
            task.wait(5)
            self.IsHopping = false
        end)
    end

    -- プレイヤーがStaff（管理者相当）かどうかを自動判定
    function InterfaceManager:IsStaff(player)
        if not player or player == Players.LocalPlayer then return false end
        
        -- ゲームのCreatorがユーザー本人かどうか
        if game.CreatorType == Enum.CreatorType.User then
            if player.UserId == game.CreatorId then return true end
        end
        
        -- ゲームのCreatorがグループの場合、そのグループ内での役職ランクを確認
        if game.CreatorType == Enum.CreatorType.Group then
            local rankSuccess, rank = pcall(function()
                return player:GetRankInGroup(game.CreatorId)
            end)
            -- ランク200以上を管理者と推定（一般メンバーは通常1〜100程度）
            if rankSuccess and rank >= 200 then return true end
        end
        
        -- 公式認定バッジの有無（大規模ゲームの管理者に多い）
        local verifiedSuccess, verified = pcall(function()
            return player.HasVerifiedBadge
        end)
        if verifiedSuccess and verified then return true end
        
        return false
    end

    -- Auto Rejoin: エラー発生時の自動再接続
    function InterfaceManager:BindAutoRejoin()
        local function triggerRejoin()
            if not self.Settings.AutoRejoin or self.IsRejoining then return end
            self.IsRejoining = true
            task.wait(3)
            
            pcall(function()
                if #game.JobId > 0 then
                    TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Players.LocalPlayer)
                else
                    TeleportService:Teleport(game.PlaceId, Players.LocalPlayer)
                end
            end)
            
            task.wait(5)
            self.IsRejoining = false
        end
        
        -- CoreGuiのエラープロンプト監視
        local CoreGui = game:GetService("CoreGui")
        pcall(function()
            local promptOverlay = CoreGui:FindFirstChild("RobloxPromptGui"):FindFirstChild("promptOverlay")
            if promptOverlay then
                promptOverlay.ChildAdded:Connect(function(child)
                    if child.Name == "ErrorPrompt" then
                        triggerRejoin()
                    end
                end)
            end
        end)
        
        -- GuiServiceのエラーメッセージ監視
        pcall(function()
            game:GetService("GuiService").ErrorMessageChanged:Connect(function()
                triggerRejoin()
            end)
        end)
    end

    -- Staff Detector: サーバー内のStaff検知と自動Hop
    function InterfaceManager:BindStaffDetector()
        local function checkPlayer(player)
            if not self.Settings.StaffDetector then return end
            
            local isStaff = self:IsStaff(player)
            if not isStaff then return end
            
            -- Webhook通知
            self:SendWebhook(
                "⚠️ Staff Detected",
                string.format(
                    "**Player:** %s\n**UserId:** %d\n**Game:** %s (PlaceId: %d)\n**Action:** Auto Hop",
                    player.Name, player.UserId, game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name or "Unknown", game.PlaceId
                )
            )
            
            -- 即座にサーバー移動
            task.wait(1)
            self:ServerHop()
        end
        
        -- 新規参加プレイヤーの監視
        Players.PlayerAdded:Connect(checkPlayer)
        
        -- 既にサーバーにいるプレイヤーも確認
        task.spawn(function()
            for _, player in ipairs(Players:GetPlayers()) do
                checkPlayer(player)
            end
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
        
        -- Start Staff Detector Binder
        self:BindStaffDetector()
        
        -- Handle AutoMinimize if on initial load
        if Settings.AutoMinimize and Library.Window then
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

        -- Server & Safety セクション
        local ServerSection = tab:AddSection("Server & Safety")
        
        ServerSection:AddToggle("AutoRejoinToggle", {
            Title = "Auto Rejoin",
            Default = Settings.AutoRejoin,
            Callback = function(Value)
                Settings.AutoRejoin = Value
                InterfaceManager:SaveSettings()
            end
        })

        ServerSection:AddToggle("LowPlayerHopToggle", {
            Title = "Low Player Hop",
            Default = Settings.LowPlayerHop,
            Callback = function(Value)
                Settings.LowPlayerHop = Value
                InterfaceManager:SaveSettings()
            end
        })
         
        ServerSection:AddToggle("StaffDetectorToggle", {
            Title = "Staff Detector",
            Default = Settings.StaffDetector,
            Callback = function(Value)
                Settings.StaffDetector = Value
                InterfaceManager:SaveSettings()
            end
        })

        ServerSection:AddButton({
            Title = "Server Hop",
            Callback = function()
                InterfaceManager:ServerHop()
            end
        })

        ServerSection:AddInput("WebhookURLInput", {
            Title = "Discord Webhook URL",
            Default = Settings.WebhookURL,
            Numeric = false,
            Finished = true,
            Placeholder = "https://discord.com/api/webhooks/...",
            Callback = function(Value)
                Settings.WebhookURL = Value
                InterfaceManager:SaveSettings()
            end
        })
    end
end

return InterfaceManager
