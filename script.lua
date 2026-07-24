-- ============================================================
-- Load Rayfield
-- ============================================================
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success then
    warn("Rayfield failed to load.")
    return
end

-- ============================================================
-- Services
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Drawing = Drawing

-- ============================================================
-- Window Setup
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Operation One | Swayz 🟣",
    LoadingTitle = "Operation One",
    LoadingSubtitle = "By Littlemail451",  -- <--- UPDATED
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "OperationOne",
        FileName = "Config"
    },
    Discord = {
        Enabled = true,
        Invite = "3Xg9enfae"
    },
    Keybind = Enum.KeyCode.K,
    KeySystem = false,
})

-- ============================================================
-- CONFIG
-- ============================================================
local Settings = {
    ESP = {
        Enabled = true,
        TeamCheck = true,
        MaxDistance = 250,
        Boxes = true,
        Health = true,
        Names = true,
        Distance = true,
        Color = Color3.fromRGB(255, 0, 0),
    },
    Chams = {
        Rainbow = false,
        RainbowSpeed = 1.0,
    },
    NoRecoil = {
        Enabled = false,
        Intensity = 0,
    }
}

-- ============================================================
-- RAINBOW COLOR
-- ============================================================
local hue = 0
local function GetRainbowColor()
    hue = (hue + (Settings.Chams.RainbowSpeed * 0.005)) % 1
    return Color3.fromHSV(hue, 1, 1)
end

-- ============================================================
-- ESP DRAWING STORAGE
-- ============================================================
local ESPObjects = {}

local function ClearESP()
    for player, data in pairs(ESPObjects) do
        for _, obj in pairs(data) do
            if obj and obj.Visible ~= nil then
                obj.Visible = false
            end
        end
    end
    ESPObjects = {}
end

-- ============================================================
-- HELPERS
-- ============================================================
local function WorldToScreen(worldPos)
    local vec, onScreen = Camera:WorldToViewportPoint(worldPos)
    return Vector2.new(vec.X, vec.Y), onScreen
end

local function GetHealthColor(health, maxHealth)
    local ratio = math.clamp(health / maxHealth, 0, 1)
    return Color3.fromRGB(255 * (1 - ratio), 255 * ratio, 0)
end

local function GetValidEnemies()
    local enemies = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not player.Character then continue end
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end
        
        if Settings.ESP.TeamCheck then
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                continue
            end
        end
        table.insert(enemies, player)
    end
    return enemies
end

-- ============================================================
-- MAIN UPDATE
-- ============================================================
local function UpdateESP()
    if not Settings.ESP.Enabled then
        for _, data in pairs(ESPObjects) do
            for _, obj in pairs(data) do
                if obj and obj.Visible ~= nil then
                    obj.Visible = false
                end
            end
        end
        return
    end

    local currentColor = Settings.ESP.Color
    if Settings.Chams.Rainbow then
        currentColor = GetRainbowColor()
    end

    local enemies = GetValidEnemies()
    local currentPlayers = {}
    
    for _, enemy in ipairs(enemies) do
        local char = enemy.Character
        if not char then continue end
        
        local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso")
        local head = char:FindFirstChild("Head")
        local humanoid = char:FindFirstChild("Humanoid")
        if not root or not head or not humanoid then continue end
        
        local dist = (root.Position - Camera.CFrame.Position).Magnitude
        if dist > Settings.ESP.MaxDistance then continue end
        
        currentPlayers[enemy] = true
        
        if not ESPObjects[enemy] then
            ESPObjects[enemy] = {
                Box = Drawing.new("Square"),
                HealthBar = Drawing.new("Square"),
                HealthBarBg = Drawing.new("Square"),
                NameText = Drawing.new("Text"),
                DistText = Drawing.new("Text"),
            }
            ESPObjects[enemy].Box.Thickness = 1.5
            ESPObjects[enemy].Box.Filled = false
            ESPObjects[enemy].HealthBarBg.Thickness = 0
            ESPObjects[enemy].HealthBarBg.Filled = true
            ESPObjects[enemy].HealthBarBg.Transparency = 0.5
            ESPObjects[enemy].HealthBarBg.Color = Color3.fromRGB(0, 0, 0)
            ESPObjects[enemy].HealthBar.Thickness = 0
            ESPObjects[enemy].HealthBar.Filled = true
            ESPObjects[enemy].HealthBar.Transparency = 0
            ESPObjects[enemy].NameText.Size = 13
            ESPObjects[enemy].NameText.Center = true
            ESPObjects[enemy].NameText.Outline = true
            ESPObjects[enemy].NameText.OutlineColor = Color3.fromRGB(0, 0, 0)
            ESPObjects[enemy].DistText.Size = 12
            ESPObjects[enemy].DistText.Center = true
            ESPObjects[enemy].DistText.Outline = true
            ESPObjects[enemy].DistText.OutlineColor = Color3.fromRGB(0, 0, 0)
        end
        
        local data = ESPObjects[enemy]
        local screenRoot, rootVis = WorldToScreen(root.Position)
        local screenHead, headVis = WorldToScreen(head.Position)
        
        if not rootVis or not headVis then
            data.Box.Visible = false
            data.HealthBar.Visible = false
            data.HealthBarBg.Visible = false
            data.NameText.Visible = false
            data.DistText.Visible = false
            continue
        end
        
        local baseHeight = math.abs(screenHead.Y - screenRoot.Y)
        local height = baseHeight * 3.75
        local width = height * 0.7
        local topLeft = Vector2.new(
            screenRoot.X - width / 2,
            screenRoot.Y - height / 2
        )
        
        local healthColor = GetHealthColor(humanoid.Health, humanoid.MaxHealth)
        local boxColor = currentColor
        
        if Settings.ESP.Boxes then
            data.Box.Size = Vector2.new(width, height)
            data.Box.Position = topLeft
            data.Box.Color = boxColor
            data.Box.Transparency = 0.8
            data.Box.Visible = true
        else
            data.Box.Visible = false
        end
        
        if Settings.ESP.Health then
            local barWidth = 6
            local barHeight = height * math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barX = topLeft.X - barWidth - 5
            local barY = topLeft.Y + height - barHeight
            
            data.HealthBarBg.Size = Vector2.new(barWidth, height)
            data.HealthBarBg.Position = Vector2.new(barX, topLeft.Y)
            data.HealthBarBg.Transparency = 0.5
            data.HealthBarBg.Filled = true
            data.HealthBarBg.Color = Color3.fromRGB(0, 0, 0)
            data.HealthBarBg.Visible = true
            
            data.HealthBar.Size = Vector2.new(barWidth, math.max(barHeight, 1))
            data.HealthBar.Position = Vector2.new(barX, barY)
            data.HealthBar.Transparency = 0
            data.HealthBar.Filled = true
            data.HealthBar.Color = healthColor
            data.HealthBar.Visible = true
        else
            data.HealthBar.Visible = false
            data.HealthBarBg.Visible = false
        end
        
        if Settings.ESP.Names then
            data.NameText.Text = enemy.Name
            data.NameText.Position = Vector2.new(screenRoot.X, topLeft.Y - 16)
            data.NameText.Color = Color3.fromRGB(255, 255, 255)
            data.NameText.Visible = true
        else
            data.NameText.Visible = false
        end
        
        if Settings.ESP.Distance then
            data.DistText.Text = string.format("%dm", math.floor(dist))
            data.DistText.Position = Vector2.new(screenRoot.X, topLeft.Y + height + 2)
            data.DistText.Color = Color3.fromRGB(200, 200, 200)
            data.DistText.Visible = true
        else
            data.DistText.Visible = false
        end
    end
    
    for player, data in pairs(ESPObjects) do
        if not currentPlayers[player] then
            data.Box.Visible = false
            data.HealthBar.Visible = false
            data.HealthBarBg.Visible = false
            data.NameText.Visible = false
            data.DistText.Visible = false
            ESPObjects[player] = nil
        end
    end
end

-- ============================================================
-- NO RECOIL
-- ============================================================
local recoilConnection = nil
local oldTweenCreate = nil

local function EnableNoRecoil()
    if recoilConnection then return end
    
    if TweenService then
        oldTweenCreate = hookfunction(TweenService.Create, function(self, obj, info, props)
            if obj == Camera and props and props.CFrame then
                local newInfo = TweenInfo.new(
                    0,
                    info.EasingStyle,
                    info.EasingDirection,
                    0,
                    info.Reverses,
                    info.DelayTime
                )
                return oldTweenCreate(self, obj, newInfo, props)
            end
            return oldTweenCreate(self, obj, info, props)
        end)
    end
    
    recoilConnection = RunService.RenderStepped:Connect(function() end)
end

local function DisableNoRecoil()
    if recoilConnection then
        recoilConnection:Disconnect()
        recoilConnection = nil
    end
end

-- ============================================================
-- UI TABS
-- ============================================================
local ESPTab = Window:CreateTab("ESP 💀", nil)

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = Settings.ESP.Enabled,
    Flag = "ESPToggle",
    Callback = function(value) Settings.ESP.Enabled = value; if not value then ClearESP() end end,
})

ESPTab:CreateToggle({
    Name = "Team Check (Ignore Teammates)",
    CurrentValue = Settings.ESP.TeamCheck,
    Flag = "ESPTeamCheck",
    Callback = function(value) Settings.ESP.TeamCheck = value end,
})

ESPTab:CreateSlider({
    Name = "Max Distance",
    Range = {50, 500},
    Increment = 10,
    Suffix = " studs",
    CurrentValue = Settings.ESP.MaxDistance,
    Flag = "ESPMaxDist",
    Callback = function(value) Settings.ESP.MaxDistance = value end,
})

ESPTab:CreateColorPicker({
    Name = "ESP Color (when Rainbow off)",
    Color = Settings.ESP.Color,
    Flag = "ESPColor",
    Callback = function(value) Settings.ESP.Color = value end,
})

ESPTab:CreateToggle({
    Name = "Boxes (Container)",
    CurrentValue = Settings.ESP.Boxes,
    Flag = "ESPBoxes",
    Callback = function(value) Settings.ESP.Boxes = value end,
})

ESPTab:CreateToggle({
    Name = "Health Bars",
    CurrentValue = Settings.ESP.Health,
    Flag = "ESPHealth",
    Callback = function(value) Settings.ESP.Health = value end,
})

ESPTab:CreateToggle({
    Name = "Names",
    CurrentValue = Settings.ESP.Names,
    Flag = "ESPNames",
    Callback = function(value) Settings.ESP.Names = value end,
})

ESPTab:CreateToggle({
    Name = "Distance",
    CurrentValue = Settings.ESP.Distance,
    Flag = "ESPDistance",
    Callback = function(value) Settings.ESP.Distance = value end,
})

local RecoilTab = Window:CreateTab("No Recoil ❌", nil)

RecoilTab:CreateToggle({
    Name = "Enable No Recoil",
    CurrentValue = Settings.NoRecoil.Enabled,
    Flag = "NoRecoilToggle",
    Callback = function(value)
        Settings.NoRecoil.Enabled = value
        if value then EnableNoRecoil() else DisableNoRecoil() end
    end,
})

RecoilTab:CreateSlider({
    Name = "Recoil Reduction Intensity",
    Range = {0, 100},
    Increment = 5,
    Suffix = "%",
    CurrentValue = 0,
    Flag = "NoRecoilIntensity",
    Callback = function(value)
        Settings.NoRecoil.Intensity = value / 100
        if Settings.NoRecoil.Enabled then
            DisableNoRecoil()
            EnableNoRecoil()
        end
    end,
})

RecoilTab:CreateLabel("0% = Full removal (laser)")
RecoilTab:CreateLabel("100% = Default recoil")
RecoilTab:CreateLabel("")
RecoilTab:CreateLabel("⚠️ This does NOT lock your aim.")

local KeybindsTab = Window:CreateTab("Keybinds 🔑", nil)

KeybindsTab:CreateLabel("🎮 Menu Toggle: K")
KeybindsTab:CreateLabel("Press K to open/close the UI.")

KeybindsTab:CreateButton({
    Name = "📋 Copy Discord Invite",
    Callback = function()
        local link = "https://discord.gg/3Xg9enfae"
        local copied = false
        pcall(function()
            if syn and syn.clipboard then
                syn.clipboard(link)
                copied = true
            elseif setclipboard then
                setclipboard(link)
                copied = true
            elseif toclipboard then
                toclipboard(link)
                copied = true
            end
        end)
        if copied then
            Rayfield:Notify({ Title = "Discord Invite", Content = "Link copied to clipboard!", Duration = 3 })
        else
            Rayfield:Notify({ Title = "Discord Invite", Content = "Couldn't copy. Here's the link: " .. link, Duration = 5 })
        end
    end
})

local ChamsTab = Window:CreateTab("Chams 🌈", nil)

ChamsTab:CreateToggle({
    Name = "Rainbow Boxes",
    CurrentValue = Settings.Chams.Rainbow,
    Flag = "RainbowToggle",
    Callback = function(value) Settings.Chams.Rainbow = value end,
})

ChamsTab:CreateSlider({
    Name = "Rainbow Speed",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = Settings.Chams.RainbowSpeed,
    Flag = "RainbowSpeed",
    Callback = function(value) Settings.Chams.RainbowSpeed = value end,
})

-- ============================================================
-- RENDER LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    UpdateESP()
end)

-- ============================================================
-- CLEANUP
-- ============================================================
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            if obj and obj.Visible ~= nil then obj.Visible = false end
        end
        ESPObjects[player] = nil
    end
end)

-- ============================================================
-- LOAD & NOTIFY
-- ============================================================
Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title = "Operation One | Swayz 🟣",
    Content = "MASSIVE Container Boxes + Fixed Healthbars | Press K",
    Duration = 4,
})

print("Operation One | Swayz 🟣 — Loaded")
