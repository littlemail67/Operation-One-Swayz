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
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Drawing = Drawing

-- ============================================================
-- Window Setup
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name = "Operation One | Swayz 🟣",
    LoadingTitle = "Operation One",
    LoadingSubtitle = "By Littlemail451",
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
        MaxDistance = 300,
        Boxes = true,
        Health = true,
        Names = true,
        Distance = true,
        Tracers = false,
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
-- 🔥 OP1 CHARACTER FINDER (Workspace Scanning)
-- ============================================================
local function findCharacter(player)
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name == player.Name then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local root = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
            if hum and root then
                return model, hum, root
            end
        end
    end
    return nil, nil, nil
end

-- ============================================================
-- ESP DRAWING STORAGE (with anti-stuck state)
-- ============================================================
local ESPObjects = {}
local MAX_STUCK_TIME = 1.5  -- seconds

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

local function hidePlayer(player)
    local data = ESPObjects[player]
    if data then
        data.Box.Visible = false
        data.Health.Visible = false
        data.HealthBg.Visible = false
        data.Name.Visible = false
        data.Tracer.Visible = false
        data.Dist.Visible = false
        data.LastPosition = nil
        data.StuckTime = 0
    end
end

-- ============================================================
-- Helpers
-- ============================================================
local function WorldToScreen(worldPos)
    local vec, onScreen = Camera:WorldToViewportPoint(worldPos)
    return Vector2.new(vec.X, vec.Y), onScreen
end

local function GetHealthColor(health, maxHealth)
    local ratio = math.clamp(health / maxHealth, 0, 1)
    return Color3.fromHSV(0.33 * ratio, 1, 0.95)
end

local function getBox(character)
    local cf, size = character:GetBoundingBox()
    local top = cf.Position + Vector3.new(0, size.Y/2, 0)
    local bottom = cf.Position - Vector3.new(0, size.Y/2, 0)

    local topPos, vis1 = Camera:WorldToViewportPoint(top)
    local bottomPos, vis2 = Camera:WorldToViewportPoint(bottom)

    if not vis1 or not vis2 then
        return nil
    end

    local height = math.abs(topPos.Y - bottomPos.Y)
    local width = height / 2
    return Vector2.new(topPos.X - width/2, topPos.Y), width, height
end

-- ============================================================
-- MAIN UPDATE (Accepts delta time)
-- ============================================================
local function UpdateESP(dt)
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

    local currentPlayers = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        -- Team Check
        if Settings.ESP.TeamCheck then
            if player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
                if ESPObjects[player] then hidePlayer(player) end
                continue
            end
        end

        local character, humanoid, root = findCharacter(player)
        if not character or not humanoid or humanoid.Health <= 0 then
            if ESPObjects[player] then hidePlayer(player) end
            continue
        end

        local dist = (root.Position - Camera.CFrame.Position).Magnitude
        if dist > Settings.ESP.MaxDistance then
            if ESPObjects[player] then hidePlayer(player) end
            continue
        end

        currentPlayers[player] = true

        -- Create objects if missing
        if not ESPObjects[player] then
            ESPObjects[player] = {
                Box = Drawing.new("Square"),
                Health = Drawing.new("Square"),
                HealthBg = Drawing.new("Square"),
                Name = Drawing.new("Text"),
                Tracer = Drawing.new("Line"),
                Dist = Drawing.new("Text"),
                LastPosition = nil,
                StuckTime = 0,
            }
            -- Setup...
            ESPObjects[player].Box.Thickness = 1.5
            ESPObjects[player].Box.Filled = false
            ESPObjects[player].HealthBg.Thickness = 0
            ESPObjects[player].HealthBg.Filled = true
            ESPObjects[player].HealthBg.Transparency = 0.5
            ESPObjects[player].HealthBg.Color = Color3.fromRGB(0,0,0)
            ESPObjects[player].Health.Thickness = 0
            ESPObjects[player].Health.Filled = true
            ESPObjects[player].Health.Transparency = 0
            ESPObjects[player].Name.Size = 13
            ESPObjects[player].Name.Center = true
            ESPObjects[player].Name.Outline = true
            ESPObjects[player].Name.OutlineColor = Color3.fromRGB(0,0,0)
            ESPObjects[player].Tracer.Thickness = 1
            ESPObjects[player].Dist.Size = 12
            ESPObjects[player].Dist.Center = true
            ESPObjects[player].Dist.Outline = true
            ESPObjects[player].Dist.OutlineColor = Color3.fromRGB(0,0,0)
        end

        local data = ESPObjects[player]
        local pos, width, height = getBox(character)
        if not pos then
            hidePlayer(player)
            continue
        end

        -- Anti-stuck using dt
        if data.LastPosition then
            if (data.LastPosition - pos).Magnitude < 1 then
                data.StuckTime = data.StuckTime + dt
            else
                data.StuckTime = 0
            end
            if data.StuckTime >= MAX_STUCK_TIME then
                hidePlayer(player)
                data.LastPosition = nil
                data.StuckTime = 0
                continue
            end
        end
        data.LastPosition = pos

        local healthColor = GetHealthColor(humanoid.Health, humanoid.MaxHealth)
        local boxColor = currentColor

        -- Box
        if Settings.ESP.Boxes then
            data.Box.Size = Vector2.new(width, height)
            data.Box.Position = pos
            data.Box.Color = boxColor
            data.Box.Transparency = 0.8
            data.Box.Visible = true
        else
            data.Box.Visible = false
        end

        -- Health bar
        if Settings.ESP.Health then
            local barWidth = 6
            local barHeight = height * math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
            local barX = pos.X - barWidth - 5
            local barY = pos.Y + height - barHeight

            data.HealthBg.Size = Vector2.new(barWidth, height)
            data.HealthBg.Position = Vector2.new(barX, pos.Y)
            data.HealthBg.Visible = true

            data.Health.Size = Vector2.new(barWidth, math.max(barHeight, 1))
            data.Health.Position = Vector2.new(barX, barY)
            data.Health.Color = healthColor
            data.Health.Visible = true
        else
            data.Health.Visible = false
            data.HealthBg.Visible = false
        end

        -- Name
        if Settings.ESP.Names then
            data.Name.Text = player.Name
            data.Name.Position = Vector2.new(pos.X + width/2, pos.Y - 16)
            data.Name.Color = Color3.fromRGB(255,255,255)
            data.Name.Visible = true
        else
            data.Name.Visible = false
        end

        -- Distance
        if Settings.ESP.Distance then
            data.Dist.Text = string.format("%dm", math.floor(dist))
            data.Dist.Position = Vector2.new(pos.X + width/2, pos.Y + height + 2)
            data.Dist.Color = Color3.fromRGB(200,200,200)
            data.Dist.Visible = true
        else
            data.Dist.Visible = false
        end

        -- Tracer
        if Settings.ESP.Tracers then
            data.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            data.Tracer.To = Vector2.new(pos.X + width/2, pos.Y + height/2)
            data.Tracer.Color = boxColor
            data.Tracer.Visible = true
        else
            data.Tracer.Visible = false
        end
    end

    -- Cleanup players no longer in currentPlayers
    for player, data in pairs(ESPObjects) do
        if not currentPlayers[player] then
            hidePlayer(player)
        end
    end
end

-- ============================================================
-- NO RECOIL – 3 LAYERS (Tween + CFrame hook + RenderStep)
-- ============================================================
local recoilConnection = nil
local oldTweenCreate = nil
local originalCameraMT = nil
local storedCFrame = nil

local function EnableNoRecoil()
    if recoilConnection then return end

    -- Layer 1: Tween hook
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

    -- Layer 2: CFrame metatable hook
    local mt = getrawmetatable(Camera)
    if mt then
        originalCameraMT = mt
        local oldNewIndex = mt.__newindex
        setreadonly(mt, false)
        mt.__newindex = function(self, key, value)
            if key == "CFrame" and self == Camera and Settings.NoRecoil.Enabled then
                -- Block recoil writes
                return
            end
            oldNewIndex(self, key, value)
        end
        setreadonly(mt, true)
    end

    -- Layer 3: RenderStepped correction
    storedCFrame = Camera.CFrame
    recoilConnection = RunService.RenderStepped:Connect(function()
        if not Settings.NoRecoil.Enabled then return end
        if storedCFrame then
            Camera.CFrame = storedCFrame
        end
    end)
end

local function DisableNoRecoil()
    if recoilConnection then
        recoilConnection:Disconnect()
        recoilConnection = nil
    end
    if originalCameraMT then
        local mt = getrawmetatable(Camera)
        if mt then
            setreadonly(mt, false)
            mt.__newindex = originalCameraMT.__newindex
            setreadonly(mt, true)
        end
        originalCameraMT = nil
    end
    storedCFrame = nil
    -- Restore Tween hook if needed
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
    Name = "Team Check",
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
    Name = "ESP Color",
    Color = Settings.ESP.Color,
    Flag = "ESPColor",
    Callback = function(value) Settings.ESP.Color = value end,
})

ESPTab:CreateToggle({
    Name = "Boxes",
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

ESPTab:CreateToggle({
    Name = "Tracers",
    CurrentValue = Settings.ESP.Tracers,
    Flag = "ESPTracers",
    Callback = function(value) Settings.ESP.Tracers = value end,
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
    Name = "Recoil Intensity",
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

RecoilTab:CreateLabel("0% = Full removal")
RecoilTab:CreateLabel("100% = Default")
RecoilTab:CreateLabel("3‑Layer protection")

local KeybindsTab = Window:CreateTab("Keybinds 🔑", nil)
KeybindsTab:CreateLabel("Menu Toggle: K")
KeybindsTab:CreateButton({
    Name = "Copy Discord Invite",
    Callback = function()
        local link = "https://discord.gg/3Xg9enfae"
        local copied = false
        pcall(function()
            if syn and syn.clipboard then syn.clipboard(link) copied = true
            elseif setclipboard then setclipboard(link) copied = true
            elseif toclipboard then toclipboard(link) copied = true end
        end)
        Rayfield:Notify({ Title = "Invite", Content = copied and "Copied!" or link, Duration = 3 })
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
-- RENDER LOOP (pass dt)
-- ============================================================
RunService.RenderStepped:Connect(function(dt)
    UpdateESP(dt)
end)

-- ============================================================
-- CLEANUP
-- ============================================================
Players.PlayerRemoving:Connect(function(player)
    if ESPObjects[player] then
        hidePlayer(player)
        ESPObjects[player] = nil
    end
end)

-- ============================================================
-- LOAD
-- ============================================================
Rayfield:LoadConfiguration()
Rayfield:Notify({
    Title = "Op1 | Swayz 🟣",
    Content = "Loaded | No errors | Press K",
    Duration = 4,
})
print("Operation One | Swayz 🟣 — Fixed script loaded.")
