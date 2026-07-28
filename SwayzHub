-- ==================== SWAYZ HUB — WITH LUCIDE SUN ICON ====================
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
if not Rayfield then
    warn("Rayfield failed to load – check internet.")
    return
end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Marketplace = game:GetService("MarketplaceService")

-- ==================== EXECUTOR DETECTION ====================
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

-- ==================== CREATE WINDOW — LUCIDE SUN ICON ====================
local Hub = Rayfield:CreateWindow({
    Name = "Swayz Hub 🟣",
    Icon = "sun",                      -- <--- LUCIDE ICON (works 100%)
    LoadingTitle = "Swayz Hub",
    LoadingSubtitle = "By Littlemail67",
    Theme = "Amethyst",
    ToggleUIKeybind = Enum.KeyCode.LeftShift,
    ConfigurationSaving = {
        Enabled = false,
    },
})

-- ==================== TAB 1: STATUS (COMPACT) ====================
local StatusTab = Hub:CreateTab("Status 📊", nil)

StatusTab:CreateLabel("👋 Hello, " .. LocalPlayer.Name .. "!")
StatusTab:CreateLabel("")
StatusTab:CreateLabel("🖥️ Executor: " .. ExecutorName)
StatusTab:CreateLabel("🎮 Game: " .. Marketplace:GetProductInfo(game.PlaceId).Name)
StatusTab:CreateLabel("🆔 Place ID: " .. game.PlaceId)

-- ==================== TAB 2: SUPPORTED GAMES (COMPACT) ====================
local GamesTab = Hub:CreateTab("Supported Games 🎮", nil)

GamesTab:CreateButton({
    Name = "Operation One | 🟣 Swayz",
    Callback = function()
        -- Destroy hub safely
        local success, err = pcall(function()
            Hub:Destroy()
        end)
        if not success then
            pcall(function()
                for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
                    if v.Name == "Rayfield" or string.find(v.Name, "Swayz") then
                        v:Destroy()
                    end
                end
            end)
        end
        task.wait(0.15)

        -- Execute the Operation One script
        local execSuccess, execErr = pcall(function()
            local scriptContent = game:HttpGet("https://raw.githubusercontent.com/littlemail67/Operation-One-Swayz/main/script.lua")
            if scriptContent and scriptContent ~= "" then
                loadstring(scriptContent)()
            else
                error("Script returned empty content")
            end
        end)

        if not execSuccess then
            pcall(function()
                Rayfield:Notify({
                    Title = "Execution Failed",
                    Content = "Operation One error: " .. tostring(execErr),
                    Duration = 4
                })
            end)
        end
    end
})

GamesTab:CreateLabel("More coming soon...")

-- ==================== TAB 3: CREDITS (COMPACT) ====================
local CreditsTab = Hub:CreateTab("Credits 📋", nil)

CreditsTab:CreateLabel("👑 Created by: Littlemail67")
CreditsTab:CreateLabel("")

CreditsTab:CreateButton({
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
                Title = "Discord",
                Content = "Invite copied to clipboard!",
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "Discord",
                Content = "Here's the link: " .. link,
                Duration = 5
            })
        end
    end
})

CreditsTab:CreateButton({
    Name = "🚫 Close Hub",
    Callback = function()
        Hub:Destroy()
    end
})

-- ==================== STARTUP NOTIFICATION ====================
Rayfield:Notify({
    Title = "Swayz Hub Loaded!",
    Content = "Welcome, " .. LocalPlayer.Name .. "! Press Left Shift to toggle.",
    Duration = 4,
})

print("🥖 Swayz Hub — Sun icon shining bright.")
