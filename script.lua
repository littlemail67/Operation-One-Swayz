-- ==== Initialization ====
local RunService = game:GetService("RunService")
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
_G.ESPColor = _G.ESPColor or Color3.new(1, 1, 1)
_G.espSkeletons = false
_G.ESP_ENABLED = false

local Window = Rayfield:CreateWindow({
   Name = "Operation One | Swayz 🟣",
   Icon = 0,
   LoadingTitle = "Operation One | Swayz 🟣",
   LoadingSubtitle = "By Littlemail67",
   ShowText = "Rayfield",
   Theme = "Default",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = false,
   DisableBuildWarnings = false,
   ConfigurationSaving = {
      Enabled = true,
      FolderName = nil,
      FileName = "operation one swayz"
   },
})

Rayfield:Notify({
   Title = "Operation One | Swayz 🟣 Loaded!",
   Content = "All systems ready",
   Duration = 5,
})

-- ==================== NO RECOIL ====================
local NoRecoilSettings = {
    Enabled = false,
    ActiveKey = Enum.UserInputType.MouseButton1,
    Sens = 1.0,
    Smoothness = 0.12
}
local targetX, targetY, targetZ = 0, 0, 0
local isFiring = false
local recoveryTime = 0

local function syncCamera()
    local x, y, z = workspace.CurrentCamera.CFrame:ToEulerAnglesYXZ()
    targetX, targetY, targetZ = x, y, z
end
syncCamera()

game:GetService("RunService"):BindToRenderStep("DynamicZeroRecoil", Enum.RenderPriority.Camera.Value + 1, function(dt)
    if not NoRecoilSettings.Enabled then return end
    
    local UIS = game:GetService("UserInputService")
    local LocalPlayer = game:GetService("Players").LocalPlayer
    local Camera = workspace.CurrentCamera
    
    if UIS.MouseBehavior == Enum.MouseBehavior.Default then syncCamera() return end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChildOfClass("Humanoid") or char.Humanoid.Health <= 0 then
         syncCamera()
         return 
     end

    local delta = UIS:GetMouseDelta()
    local _, _, realZ = Camera.CFrame:ToEulerAnglesYXZ()
    local flip = (Camera.CFrame.UpVector.Y < 0) and -1 or 1

    if UIS:IsMouseButtonPressed(NoRecoilSettings.ActiveKey) then
        isFiring = true
        recoveryTime = 0.35
        
        targetY = targetY - math.rad(delta.X * NoRecoilSettings.Sens * 0.48 * flip)
        targetX = targetX - math.rad(delta.Y * NoRecoilSettings.Sens * 0.48)
        targetX = math.clamp(targetX, math.rad(-85), math.rad(85))
        
        Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(targetX, targetY, realZ)
    else
        if isFiring then
            if recoveryTime > 0 then
                recoveryTime = recoveryTime - dt
                
                if delta.Magnitude > 0 then
                    targetY = targetY - math.rad(delta.X * NoRecoilSettings.Sens * 0.48 * flip)
                    targetX = targetX - math.rad(delta.Y * NoRecoilSettings.Sens * 0.48)
                    targetX = math.clamp(targetX, math.rad(-85), math.rad(85))
                end
                
                Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.fromEulerAnglesYXZ(targetX, targetY, targetZ)
            else
                syncCamera()
                isFiring = false
            end
        else
            syncCamera()
        end
    end
end)

-- ==================== TABS (Order: Aim → No Recoil → ESP → Chams → Keybinds) ====================

-- 1. AIM TAB
local AimTab = Window:CreateTab("Aim💀", nil)
local AimSection = AimTab:CreateSection("AimBot")

-- ==================== AIMBOT ====================
local UserInputService = game:GetService("UserInputService")
local isMobile = UserInputService.TouchEnabled

local AimbotSettings = {
    Enabled = false,
    Smoothness = 0,
    FOV = 150,
    AimOffsetY = 0,
    AimPart = "Head",
    RandomPart = nil,
    FOVCircle = nil,
    Connection = nil,
    WasRMBPressed = false,
    AlwaysOn = false,
    UseCameraAim = false,
    MobileScopeActive = false,
}

if isMobile then
    local function deactivateAimbotIfActive()
        if AimbotSettings.Enabled and AimbotSettings.MobileScopeActive then
            AimbotSettings.MobileScopeActive = false
            AimbotSettings.WasRMBPressed = false
        end
    end

    pcall(function()
        local scopeButton = LocalPlayer:WaitForChild("PlayerGui", 5):WaitForChild("Game", 5):WaitForChild("Right", 5):WaitForChild("Center", 5):WaitForChild("ScopeButton", 5)
        scopeButton.Activated:Connect(function()
            AimbotSettings.MobileScopeActive = not AimbotSettings.MobileScopeActive
            if AimbotSettings.MobileScopeActive then
                AimbotSettings.WasRMBPressed = false
            end
        end)
    end)

    pcall(function()
        local reloadButton = LocalPlayer:WaitForChild("PlayerGui", 5):WaitForChild("Game", 5):WaitForChild("Right", 5):WaitForChild("Center", 5):WaitForChild("ReloadButton", 5)
        reloadButton.Activated:Connect(deactivateAimbotIfActive)
    end)

    pcall(function()
        local backpackItems = LocalPlayer:WaitForChild("PlayerGui", 5):WaitForChild("Game", 5):WaitForChild("Right", 5):WaitForChild("Bottom", 5):WaitForChild("BackpackItems", 5)
        for _, item in ipairs(backpackItems:GetChildren()) do
            if item:IsA("ImageButton") or item:IsA("TextButton") then
                item.Activated:Connect(deactivateAimbotIfActive)
            end
        end
        backpackItems.ChildAdded:Connect(function(item)
            if item:IsA("ImageButton") or item:IsA("TextButton") then
                item.Activated:Connect(deactivateAimbotIfActive)
            end
        end)
    end)
end

local function getViewmodelPartPosition(model, partName)
    if partName == "Head" then
        local head = model:FindFirstChild("head")
        if head and head:IsA("BasePart") then return head.Position end
    elseif partName == "Torso" then
        local torso = model:FindFirstChild("torso")
        if torso and torso:IsA("BasePart") then return torso.Position end
    end
    return nil
end

local aimPartOptions = {"Head", "Torso"}

local function getClosestPartToCenter(partName)
    local Camera = workspace.CurrentCamera
    local center = Camera.ViewportSize / 2
    local bestDist = AimbotSettings.FOV
    local bestTarget = nil
    local bestWorldPos = nil
    local viewmodels = workspace:FindFirstChild("Viewmodels")
    if not viewmodels then return nil, nil end

    for _, model in ipairs(viewmodels:GetChildren()) do
        if not model:IsA("Model") then continue end
        if model.Name == "LocalViewmodel" then continue end

        local partPos = getViewmodelPartPosition(model, partName)
        if not partPos then continue end

        local screenPos, onScreen = Camera:WorldToScreenPoint(partPos)
        if not onScreen then continue end

        screenPos = Vector2.new(screenPos.X, screenPos.Y + AimbotSettings.AimOffsetY)

        local dist = (screenPos - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            bestTarget = screenPos
            bestWorldPos = partPos
        end
    end
    return bestTarget, bestWorldPos
end

local function aimbotLoop()
    local UIS = game:GetService("UserInputService")
    local Camera = workspace.CurrentCamera

    AimbotSettings.Connection = RunService.RenderStepped:Connect(function(dt)
        if not AimbotSettings.Enabled then return end

        local rmbPressed
        if AimbotSettings.AlwaysOn then
            rmbPressed = true
        elseif isMobile then
            rmbPressed = AimbotSettings.MobileScopeActive
        else
            rmbPressed = UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        end

        if not rmbPressed then
            AimbotSettings.WasRMBPressed = false
            AimbotSettings.RandomPart = nil
            return
        end

        if not AimbotSettings.WasRMBPressed then
            AimbotSettings.WasRMBPressed = true
        end

        local currentPart = AimbotSettings.AimPart
        local screenTarget, worldTarget = getClosestPartToCenter(currentPart)
        if not screenTarget then return end

        local center = Camera.ViewportSize / 2
        local smoothness = AimbotSettings.Smoothness
        local factor = (smoothness <= 0) and 1 or math.clamp(1 - (smoothness / 10), 0.05, 1)

        if AimbotSettings.UseCameraAim and worldTarget then
            local desiredLook = CFrame.lookAt(Camera.CFrame.Position, worldTarget)
            local newCF = Camera.CFrame:Lerp(desiredLook, factor)
            Camera.CFrame = newCF
        else
            local delta = screenTarget - center
            mousemoverel(delta.X * factor, delta.Y * factor)
        end
    end)
end

local AimbotToggle = AimTab:CreateToggle({
    Name = "Enable AimBot",
    CurrentValue = false,
    Callback = function(Value)
        AimbotSettings.Enabled = Value
        if Value then
            if not AimbotSettings.Connection then
                aimbotLoop()
            end
            if not AimbotSettings.FOVCircle then
                AimbotSettings.FOVCircle = Drawing.new("Circle")
                AimbotSettings.FOVCircle.Visible = false
                AimbotSettings.FOVCircle.Color = Color3.new(1,1,1)
                AimbotSettings.FOVCircle.Thickness = 1
                AimbotSettings.FOVCircle.Filled = false
                AimbotSettings.FOVCircle.Transparency = 1
                AimbotSettings.FOVCircle.Position = workspace.CurrentCamera.ViewportSize / 2
                AimbotSettings.FOVCircle.Radius = AimbotSettings.FOV
            end
            AimbotSettings.FOVCircle.Visible = true
        else
            if AimbotSettings.Connection then
                AimbotSettings.Connection:Disconnect()
                AimbotSettings.Connection = nil
            end
            if AimbotSettings.FOVCircle then
                AimbotSettings.FOVCircle.Visible = false
            end
            AimbotSettings.WasRMBPressed = false
            AimbotSettings.RandomPart = nil
        end
    end,
})

local AlwaysOnToggle = AimTab:CreateToggle({
    Name = "Always Active",
    CurrentValue = false,
    Callback = function(Value)
        AimbotSettings.AlwaysOn = Value
    end,
})

local CameraAimToggle = AimTab:CreateToggle({
    Name = "Aim Assist",
    CurrentValue = false,
    Callback = function(Value)
        AimbotSettings.UseCameraAim = Value
    end,
})

local AimPartSection = AimTab:CreateSection("Target Part")
local aimParts = {"Head", "Torso"}
for _, part in ipairs(aimParts) do
    AimTab:CreateButton({
        Name = "🎯 " .. part,
        Callback = function()
            AimbotSettings.AimPart = part
            Rayfield:Notify({
                Title = "Target Part",
                Content = "Locking onto: " .. part,
                Duration = 1.5,
            })
        end,
    })
end

local SmoothnessSlider = AimTab:CreateSlider({
    Name = "Smoothness",
    Range = {0, 10},
    Increment = 0.1,
    Suffix = "",
    CurrentValue = 0,
    Callback = function(Value)
        AimbotSettings.Smoothness = Value
    end,
})

local FOVSlider = AimTab:CreateSlider({
    Name = "Field of View (FOV)",
    Range = {30, 750},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 150,
    Callback = function(Value)
        AimbotSettings.FOV = Value
        if AimbotSettings.FOVCircle then
            AimbotSettings.FOVCircle.Radius = Value
        end
    end,
})

-- Vertical Offset slider REMOVED

RunService.RenderStepped:Connect(function()
    if AimbotSettings.FOVCircle and AimbotSettings.FOVCircle.Visible then
        AimbotSettings.FOVCircle.Position = workspace.CurrentCamera.ViewportSize / 2
    end
end)

-- ==================== NO RECOIL TAB ====================
local RecoilTab = Window:CreateTab("No Recoil❌", nil)
local RecoilSection = RecoilTab:CreateSection("Recoil Control")

local NoRecoilToggle = RecoilTab:CreateToggle({
   Name = "Enable No Recoil",
   CurrentValue = false,
   Callback = function(Value)
      NoRecoilSettings.Enabled = Value
      if Value then syncCamera() end
   end,
})

-- ==================== ESP TAB ====================
local tracerStartPos = "bottom"
local ESPTab = Window:CreateTab("ESP👀", nil)
local Section = ESPTab:CreateSection("Main ESP")

_G.ESP_SETTINGS = {
    MainEnabled = false,
    Tracers = true,
    TracerStart = "Bottom",
    HealthBar = true,
    Color = Color3.new(1,1,1),
    Skeletons = false,
}

_G.ESP_Table = {}

local function setupESP()
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local ESP = _G.ESP_Table
    local TEAM_CHECK = true
    local MAX_STUCK_TIME = 1.5

    local function newDrawing(type, props)
        local obj = Drawing.new(type)
        for k,v in pairs(props) do obj[k] = v end
        return obj
    end

    local function hide(ui)
        ui.Box.Visible = false
        ui.Tracer.Visible = false
        ui.Health.Visible = false
        ui.Name.Visible = false
    end

    local function createESP(player)
        if player == LocalPlayer or ESP[player] then return end
        ESP[player] = {
            Player = player,
            Box = newDrawing("Square", {Thickness = 1, Filled = false, Color = _G.ESP_SETTINGS.Color, Visible = false}),
            Tracer = newDrawing("Line", {Thickness = 1, Color = _G.ESP_SETTINGS.Color, Visible = false}),
            Health = newDrawing("Line", {Thickness = 3, Visible = false}),
            Name = newDrawing("Text", {Size = 13, Center = true, Outline = true, Font = 2, Visible = false}),
            LastPosition = nil,
            StuckTime = 0
        }
    end

    for _,player in ipairs(Players:GetPlayers()) do createESP(player) end
    Players.PlayerAdded:Connect(createESP)

    local function findCharacter(player)
        for _,model in ipairs(workspace:GetChildren()) do
            if model:IsA("Model") and model.Name == player.Name then
                local hum = model:FindFirstChildOfClass("Humanoid")
                local root = model:FindFirstChild("HumanoidRootPart")
                if hum and root then return model, hum, root end
            end
        end
        return nil
    end

    local function getBox(character)
        local cf, size = character:GetBoundingBox()
        local top = cf.Position + Vector3.new(0, size.Y/2, 0)
        local bottom = cf.Position - Vector3.new(0, size.Y/2, 0)
        local topPos, vis1 = Camera:WorldToViewportPoint(top)
        local bottomPos, vis2 = Camera:WorldToViewportPoint(bottom)
        if not vis1 or not vis2 then return nil end
        local height = math.abs(topPos.Y - bottomPos.Y)
        local width = height / 2
        return Vector2.new(topPos.X - width/2, topPos.Y), width, height
    end

    local function getTracerStart()
        local viewport = Camera.ViewportSize
        local pos = tracerStartPos
        if pos == "bottom" then return Vector2.new(viewport.X/2, viewport.Y)
        elseif pos == "middle" then return Vector2.new(viewport.X/2, viewport.Y/2)
        elseif pos == "top" then return Vector2.new(viewport.X/2, 0)
        elseif pos == "left" then return Vector2.new(0, viewport.Y/2)
        elseif pos == "right" then return Vector2.new(viewport.X, viewport.Y/2)
        else return Vector2.new(viewport.X/2, viewport.Y)
        end
    end

    RunService.RenderStepped:Connect(function(dt)
        if not (_G.ESP_SETTINGS.MainEnabled or _G.ESP_SETTINGS.Tracers or _G.ESP_SETTINGS.HealthBar) then
            for _,ui in pairs(ESP) do hide(ui) end
            return
        end

        for player,ui in pairs(ESP) do
            pcall(function()
                if TEAM_CHECK and player.Team == LocalPlayer.Team then hide(ui) return end
                local character, humanoid, root = findCharacter(player)
                if not character or not humanoid or humanoid.Health <= 0 then hide(ui) return end
                local pos, width, height = getBox(character)
                if not pos then hide(ui) return end
                if ui.LastPosition and (ui.LastPosition - pos).Magnitude < 1 then
                    ui.StuckTime = ui.StuckTime + dt
                else
                    ui.StuckTime = 0
                end
                if ui.StuckTime >= MAX_STUCK_TIME then hide(ui) return end
                ui.LastPosition = pos

                ui.Box.Visible = _G.ESP_SETTINGS.MainEnabled
                if _G.ESP_SETTINGS.MainEnabled then
                    ui.Box.Size = Vector2.new(width, height)
                    ui.Box.Position = pos
                    ui.Box.Color = _G.ESP_SETTINGS.Color
                end

                ui.Name.Visible = _G.ESP_SETTINGS.MainEnabled
                if _G.ESP_SETTINGS.MainEnabled then
                    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    ui.Name.Text = myRoot and player.Name .. " [" .. math.floor((myRoot.Position - root.Position).Magnitude) .. "m]" or player.Name
                    ui.Name.Position = Vector2.new(pos.X + width/2, pos.Y - 15)
                end

                if _G.ESP_SETTINGS.Tracers then
                    ui.Tracer.From = getTracerStart()
                    ui.Tracer.To = Vector2.new(pos.X + width/2, pos.Y)
                    ui.Tracer.Color = _G.ESP_SETTINGS.Color
                    ui.Tracer.Visible = true
                else
                    ui.Tracer.Visible = false
                end

                if _G.ESP_SETTINGS.HealthBar then
                    local hp = humanoid.Health / humanoid.MaxHealth
                    local healthHeight = height * hp
                    ui.Health.From = Vector2.new(pos.X - 5, pos.Y + height)
                    ui.Health.To = Vector2.new(pos.X - 5, pos.Y + height - healthHeight)
                    ui.Health.Color = Color3.fromRGB(255 - (255*hp), 255*hp, 0)
                    ui.Health.Visible = true
                else
                    ui.Health.Visible = false
                end
            end)
        end
    end)
end

setupESP()

local MainESPToggle = ESPTab:CreateToggle({
   Name = "Toggle ESP",
   CurrentValue = false,
   Callback = function(Value)
      _G.ESP_SETTINGS.MainEnabled = Value
   end,
})

local ESPOptionsSection = ESPTab:CreateSection("Visual Options")

local TracersToggle = ESPTab:CreateToggle({
   Name = "Show Tracers",
   CurrentValue = true,
   Callback = function(Value)
      _G.ESP_SETTINGS.Tracers = Value
   end,
})

local HealthToggle = ESPTab:CreateToggle({
   Name = "Show Health Bars",
   CurrentValue = true,
   Callback = function(Value)
      _G.ESP_SETTINGS.HealthBar = Value
   end,
})

-- ==================== Viewmodel ESP & Skeletons ====================
local ViewmodelSection = ESPTab:CreateSection("Model ESP")

local SkeletonsToggle = ESPTab:CreateToggle({
   Name = "Skeleton Overlay",
   CurrentValue = false,
   Callback = function(Value)
      _G.espSkeletons = Value
      _G.ESP_ENABLED = Value
      _G.ESP_SETTINGS.Skeletons = Value
   end,
})

local cloneref_support = cloneref ~= nil
local gethui_support = gethui ~= nil
local runservice = cloneref_support and cloneref(game:GetService("RunService")) or game:GetService("RunService")

local bones = {
    { "torso", "head" }, { "torso", "shoulder1" }, { "torso", "shoulder2" },
    { "shoulder1", "arm1" }, { "shoulder2", "arm2" }, { "torso", "hip1" },
    { "torso", "hip2" }, { "hip1", "leg1" }, { "hip2", "leg2" }
}
local required_bones = { "torso", "head", "shoulder1", "shoulder2", "arm1", "arm2", "hip1", "hip2", "leg1", "leg2" }

_G.esp_list = {}
_G.skeleton_list = {}

local viewmodels = workspace:FindFirstChild("Viewmodels")
local camera = workspace.CurrentCamera

workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function() camera = workspace.CurrentCamera end)

_G.TeammateHighlights = _G.TeammateHighlights or {}
workspace.ChildAdded:Connect(function(child)
    if child:IsA("Highlight") then
        _G.TeammateHighlights[child] = true
    end
end)
workspace.ChildRemoved:Connect(function(child)
    if child:IsA("Highlight") then
        _G.TeammateHighlights[child] = nil
    end
end)

local function is_teammate(model)
     for highlight in pairs(_G.TeammateHighlights) do
        if highlight.Adornee == model then return true end
    end
    return false
end

local function is_valid(model)
    if not model or not model.Parent or model.Name == "LocalViewmodel" or not viewmodels or model.Parent ~= viewmodels then return false end
    local torso = model:FindFirstChild("torso")
    return torso and torso:IsA("BasePart")
end

local function rand_str(len)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = {}
    for i = 1, len do result[i] = chars:sub(math.random(1, #chars), math.random(1, #chars)) end
    return table.concat(result)
end

local screen_gui = Instance.new("ScreenGui")
screen_gui.Name = rand_str(12)
screen_gui.Parent = gethui_support and gethui() or game:GetService("CoreGui")

local function remove_skeleton(character)
    local data = _G.skeleton_list[character]
    if not data then return end
    for _, line in ipairs(data.lines) do line:Remove() end
    _G.skeleton_list[character] = nil
end

local function create_skeleton(character)
    if not character or _G.skeleton_list[character] or not is_valid(character) then return end
    local char_bones = {}
    for _, name in ipairs(required_bones) do
        local b = character:FindFirstChild(name)
        if not b or not b:IsA("BasePart") then return end
        char_bones[name] = b
    end
    
    local lines = {}
    for i = 1, #bones do
        local line = Drawing.new("Line")
        line.Visible = false
        line.Color = _G.ESPColor
        line.Thickness = 1
        line.Transparency = 1
        lines[i] = line
    end
    _G.skeleton_list[character] = { lines = lines, bones = char_bones }
end

local function create_esp(character)
    if not character or not is_valid(character) or _G.esp_list[character] then return end
    
    local folder = Instance.new("Folder", screen_gui)
    local box = Instance.new("Frame", folder)
    local stroke = Instance.new("UIStroke", box)
    
    box.BackgroundTransparency = 1
    box.BorderSizePixel = 0
    stroke.Color = _G.ESPColor
    stroke.Thickness = 1
    
    _G.esp_list[character] = { folder = folder, box = box }
end

runservice.RenderStepped:Connect(function()
    for character, data in pairs(_G.esp_list) do
        local box = data.box
        local folder = data.folder
        
        if not character or not character.Parent or not is_valid(character) then
            box.Visible = false
            folder:Destroy()
            _G.esp_list[character] = nil
            remove_skeleton(character)
            continue
        end
        
        local torso = character:FindFirstChild("torso")
        if not torso or torso.Transparency >= 1 or is_teammate(character) then
            box.Visible = false
            continue
        end
        
        local pos, on_screen = camera:WorldToScreenPoint(torso.Position)
        
        if on_screen and (camera.CFrame.Position - torso.Position).Magnitude <= 3571.4 then
            if _G.espSkeletons then
                if not _G.skeleton_list[character] then create_skeleton(character) end
                local skel = _G.skeleton_list[character]
                
                if skel then
                    local min_x, min_y = math.huge, math.huge
                    local max_x, max_y = -math.huge, -math.huge
                    
                    for i, conn in ipairs(bones) do
                        local b1, b2 = skel.bones[conn[1]], skel.bones[conn[2]]
                        if b1 and b2 then
                            local p1 = camera:WorldToViewportPoint(b1.Position)
                            local p2 = camera:WorldToViewportPoint(b2.Position)
                            local s1 = camera:WorldToScreenPoint(b1.Position)
                            local s2 = camera:WorldToScreenPoint(b2.Position)
                            
                            if s1.Z > 0 then
                                if s1.X < min_x then min_x = s1.X end
                                if s1.X > max_x then max_x = s1.X end
                                if s1.Y < min_y then min_y = s1.Y end
                                if s1.Y > max_y then max_y = s1.Y end
                            end
                            if s2.Z > 0 then
                                if s2.X < min_x then min_x = s2.X end
                                if s2.X > max_x then max_x = s2.X end
                                if s2.Y < min_y then min_y = s2.Y end
                                if s2.Y > max_y then max_y = s2.Y end
                            end
                            
                            if p1.Z > 0 and p2.Z > 0 then
                                skel.lines[i].From = Vector2.new(p1.X, p1.Y)
                                skel.lines[i].To = Vector2.new(p2.X, p2.Y)
                                skel.lines[i].Visible = true
                            else
                                skel.lines[i].Visible = false
                            end
                        else
                            skel.lines[i].Visible = false
                        end
                    end
                    
                    if _G.ESP_ENABLED and min_x ~= math.huge then
                        local pad = 4
                        box.Visible = true
                        box.Position = UDim2.fromOffset(min_x - pad, min_y - pad)
                        box.Size = UDim2.fromOffset(max_x - min_x + pad * 2, max_y - min_y + pad * 2)
                    else
                        box.Visible = false
                    end
                end
            else
                remove_skeleton(character)
                box.Visible = false
            end
        else
            box.Visible = false
            remove_skeleton(character)
        end
    end
end)

if viewmodels then
    for _, v in ipairs(viewmodels:GetChildren()) do
        if v:IsA("Model") then task.delay(0.1, create_esp, v) end
    end
    viewmodels.ChildAdded:Connect(function(v)
        if v:IsA("Model") then task.delay(0.2, create_esp, v) end
    end)
    viewmodels.ChildRemoved:Connect(function(v)
        if _G.esp_list[v] then _G.esp_list[v].folder:Destroy() _G.esp_list[v] = nil end
        remove_skeleton(v)
    end)
end

-- ==================== ESP COLOUR PICKER ====================
_G.ESPColor = _G.ESPColor or Color3.new(1, 1, 1)

local ColorSection = ESPTab:CreateSection("Color Settings")

local ESPColorPicker = ESPTab:CreateColorPicker({
   Name = "Pick ESP Color",
   Color = _G.ESPColor,
   Callback = function(Value)
      _G.ESPColor = Value
      _G.ESP_SETTINGS.Color = Value
      for _, ui in pairs(_G.ESP_Table) do
         if ui.Box then ui.Box.Color = Value end
         if ui.Tracer then ui.Tracer.Color = Value end
      end
      for _, skel in pairs(_G.skeleton_list) do
         for _, line in ipairs(skel.lines) do
            line.Color = Value
         end
      end
      for _, data in pairs(_G.esp_list) do
         data.box.UIStroke.Color = Value
      end
   end,
})

-- ==================== CHAMS TAB ====================
local ChamsTab = Window:CreateTab("Chams 🌈", nil)
local ChamsSection = ChamsTab:CreateSection("Rainbow Boxes")

ChamsTab:CreateToggle({
    Name = "Enable Rainbow",
    CurrentValue = false,
    Callback = function(Value)
        _G.RainbowEnabled = Value
    end,
})

ChamsTab:CreateSlider({
    Name = "Cycle Speed",
    Range = {0.1, 5},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1.0,
    Callback = function(Value)
        _G.RainbowSpeed = Value
    end,
})

ChamsTab:CreateLabel("🌈 Applies to box outlines and FOV circle.")
ChamsTab:CreateLabel("Health bars stay health-based.")

_G.RainbowEnabled = false
_G.RainbowSpeed = 1.0

local rainbowHue = 0
RunService.RenderStepped:Connect(function(dt)
    if _G.RainbowEnabled then
        rainbowHue = (rainbowHue + dt * _G.RainbowSpeed * 0.5) % 1
        local rainbowColor = Color3.fromHSV(rainbowHue, 1, 1)
        _G.ESP_SETTINGS.Color = rainbowColor
        _G.ESPColor = rainbowColor
        for _, ui in pairs(_G.ESP_Table) do
            if ui.Box then ui.Box.Color = rainbowColor end
            if ui.Tracer then ui.Tracer.Color = rainbowColor end
        end
        for _, skel in pairs(_G.skeleton_list) do
            for _, line in ipairs(skel.lines) do
                line.Color = rainbowColor
            end
        end
        for _, data in pairs(_G.esp_list) do
            data.box.UIStroke.Color = rainbowColor
        end
        if AimbotSettings.FOVCircle then
            AimbotSettings.FOVCircle.Color = rainbowColor
        end
    end
end)

-- ==================== KEYBINDS TAB ====================
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
            Rayfield:Notify({
                Title = "Discord Invite",
                Content = "Link copied to clipboard!",
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "Discord Invite",
                Content = "Couldn't copy. Here's the link: " .. link,
                Duration = 5
            })
        end
    end
})

KeybindsTab:CreateButton({
    Name = "🚫 Unload Cheat",
    Callback = function()
        Rayfield:Notify({
            Title = "Unloading...",
            Content = "Disabling everything and removing the GUI.",
            Duration = 2
        })

        NoRecoilSettings.Enabled = false
        pcall(function() RunService:UnbindFromRenderStep("DynamicZeroRecoil") end)

        _G.ESP_SETTINGS.MainEnabled = false
        _G.ESP_SETTINGS.Tracers = false
        _G.ESP_SETTINGS.HealthBar = false
        _G.espSkeletons = false
        _G.ESP_ENABLED = false

        for player, ui in pairs(_G.ESP_Table) do
            if ui.Box then ui.Box:Remove() end
            if ui.Tracer then ui.Tracer:Remove() end
            if ui.Health then ui.Health:Remove() end
            if ui.Name then ui.Name:Remove() end
        end
        _G.ESP_Table = {}

        for char, data in pairs(_G.skeleton_list) do
            for _, line in ipairs(data.lines) do
                line:Remove()
            end
        end
        _G.skeleton_list = {}

        for char, data in pairs(_G.esp_list) do
            data.folder:Destroy()
        end
        _G.esp_list = {}

        AimbotSettings.Enabled = false
        if AimbotSettings.Connection then
            AimbotSettings.Connection:Disconnect()
            AimbotSettings.Connection = nil
        end
        if AimbotSettings.FOVCircle then
            AimbotSettings.FOVCircle:Remove()
            AimbotSettings.FOVCircle = nil
        end
        AimbotSettings.WasRMBPressed = false
        AimbotSettings.RandomPart = nil

        Rayfield:Destroy()

        task.wait(0.5)
        print("Cheat fully unloaded")
    end
})

print("Operation One | Swayz 🟣 — Loaded")
