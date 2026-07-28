print("✅ SwayzHub.lua loaded via loadstring! - Bread was here.")

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
if not Rayfield then
    warn("Rayfield failed to load – check internet.")
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Marketplace = game:GetService("MarketplaceService")

local function getExecutor()
    local execName = "Unknown"
    local success, result = pcall(function() return identifyexecutor() end)
    if success and result and result ~= "" then
        execName = result
    elseif syn and syn.get_executor then
        success, result = pcall(syn.get_executor)
        if success and result then execName = result end
    elseif getexecutorname then
        success, result = pcall(getexecutorname)
        if success and result then execName = result end
    end
    if execName == "Unknown" then
        if is_synapse_function then execName = "Synapse X"
        elseif is_scriptware then execName = "Script-Ware"
        elseif is_krnl then execName = "Krnl"
        end
    end
    return execName
end

local ExecutorName = getExecutor()

local Hub = Rayfield:CreateWindow({
    Name = "Swayz Hub 🟣",
    Icon = "sun",
    LoadingTitle = "Swayz Hub",
    LoadingSubtitle = "By Littlemail67",
    Theme = "Amethyst",
    ToggleUIKeybind = Enum.KeyCode.LeftShift,
    ConfigurationSaving = { Enabled = false },
})

local StatusTab = Hub:CreateTab("Status 📊", nil)
StatusTab:CreateLabel("👋 Hello, " .. LocalPlayer.Name .. "!")
StatusTab:CreateLabel("")
StatusTab:CreateLabel("🖥️ Executor: " .. ExecutorName)
StatusTab:CreateLabel("🎮 Game: " .. Marketplace:GetProductInfo(game.PlaceId).Name)
StatusTab:CreateLabel("🆔 Place ID: " .. game.PlaceId)

local GamesTab = Hub:CreateTab("Supported Games 🎮", nil)

GamesTab:CreateButton({
    Name = "Operation One | 🟣 Swayz",
    Callback = function()
        pcall(Hub.Destroy, Hub)
        task.wait(0.15)
        local success, err = pcall(function()
            -- CORRECT USERNAME: littlemail67 (no 'i')
            loadstring(game:HttpGet("https://raw.githubusercontent.com/littlemail67/Operation-One-Swayz/main/script.lua"))()
        end)
        if not success then
            Rayfield:Notify({
                Title = "Execution Failed",
                Content = "Error: " .. tostring(err),
                Duration = 4
            })
        end
    end
})

GamesTab:CreateLabel("More coming soon...")

local CreditsTab = Hub:CreateTab("Credits 📋", nil)
CreditsTab:CreateLabel("👑 Created by: Littlemail67")
CreditsTab:CreateLabel("")

CreditsTab:CreateButton({
    Name = "📋 Copy Discord Invite",
    Callback = function()
        local link = "https://discord.gg/3Xg9enfae"
        local copied = false
        pcall(function()
            if syn and syn.clipboard then syn.clipboard(link) copied = true
            elseif setclipboard then setclipboard(link) copied = true
            elseif toclipboard then toclipboard(link) copied = true
            end
        end)
        if copied then
            Rayfield:Notify({ Title = "Discord", Content = "Invite copied!", Duration = 3 })
        else
            Rayfield:Notify({ Title = "Discord", Content = "Link: " .. link, Duration = 5 })
        end
    end
})

CreditsTab:CreateButton({
    Name = "🚫 Close Hub",
    Callback = function() Hub:Destroy() end
})

Rayfield:Notify({
    Title = "Swayz Hub Loaded!",
    Content = "Welcome, " .. LocalPlayer.Name .. "! Press Left Shift to toggle.",
    Duration = 4,
})

print("🥖 Swayz Hub — Loaded successfully from GitHub.")
