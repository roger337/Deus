--!strict
-- Dramatic full-width banner for tie-breaker duels.
-- Listens for ShowDuelBanner / CloseDuelBanner from DuelService.
--
-- ShowDuelBanner payload:
--   { stage: "start" | "victory",
--     sides: { [optionId]: {playerName, ...} }?,
--     winnerOption: string?,
--     winnerLabel: string? }

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Remotes = require(Shared.Remotes)

local DuelBannerUI = {}

local player = Players.LocalPlayer
local sg: ScreenGui? = nil

local function destroy()
    if sg then sg:Destroy() end
    sg = nil
end

local function fadeIn(frame: Frame)
    frame.BackgroundTransparency = 1
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") then child.TextTransparency = 1 end
    end
    TweenService:Create(frame, TweenInfo.new(0.4), { BackgroundTransparency = 0.1 }):Play()
    for _, child in ipairs(frame:GetDescendants()) do
        if child:IsA("TextLabel") then
            TweenService:Create(child, TweenInfo.new(0.6), { TextTransparency = 0 }):Play()
        end
    end
end

local function showStart(payload: any)
    destroy()
    local pg = player:WaitForChild("PlayerGui")
    sg = Instance.new("ScreenGui")
    sg.Name = "DuelBanner"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 90
    sg.Parent = pg

    local stripe = Instance.new("Frame")
    stripe.AnchorPoint = Vector2.new(0.5, 0.5)
    stripe.Position = UDim2.fromScale(0.5, 0.5)
    stripe.Size = UDim2.new(1, 0, 0, 220)
    stripe.BackgroundColor3 = Color3.fromRGB(80, 0, 0)
    stripe.BorderSizePixel = 0
    stripe.Parent = sg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 80, 80)
    stroke.Thickness = 2
    stroke.Parent = stripe

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.Position = UDim2.new(0.5, 0, 0, 16)
    title.Size = UDim2.fromOffset(800, 56)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 48
    title.TextColor3 = Color3.fromRGB(255, 200, 200)
    title.TextStrokeTransparency = 0
    title.Text = "VOTE TIED  —  DUEL"
    title.Parent = stripe

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint = Vector2.new(0.5, 0)
    sub.Position = UDim2.new(0.5, 0, 0, 80)
    sub.Size = UDim2.fromOffset(900, 28)
    sub.BackgroundTransparency = 1
    sub.Font = Theme.Font
    sub.TextSize = 18
    sub.TextColor3 = Color3.fromRGB(255, 220, 220)
    sub.Text = "Tied voters, report to the arena. Last side standing wins the vote."
    sub.Parent = stripe

    -- Render team summaries if provided
    if payload.sides then
        local container = Instance.new("Frame")
        container.AnchorPoint = Vector2.new(0.5, 0)
        container.Position = UDim2.new(0.5, 0, 0, 120)
        container.Size = UDim2.fromOffset(900, 80)
        container.BackgroundTransparency = 1
        container.Parent = stripe

        local layout = Instance.new("UIListLayout")
        layout.FillDirection = Enum.FillDirection.Horizontal
        layout.Padding = UDim.new(0, 24)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.VerticalAlignment = Enum.VerticalAlignment.Center
        layout.Parent = container

        for optId, names in pairs(payload.sides) do
            local cell = Instance.new("Frame")
            cell.Size = UDim2.fromOffset(280, 70)
            cell.BackgroundColor3 = Color3.fromRGB(40, 0, 0)
            cell.BorderSizePixel = 0
            cell.Parent = container
            local cs = Instance.new("UIStroke")
            cs.Color = Color3.fromRGB(255, 100, 100)
            cs.Thickness = 1
            cs.Parent = cell

            local opt = Instance.new("TextLabel")
            opt.Position = UDim2.fromOffset(8, 4)
            opt.Size = UDim2.fromOffset(264, 22)
            opt.BackgroundTransparency = 1
            opt.Font = Theme.Font
            opt.TextSize = 16
            opt.TextColor3 = Color3.fromRGB(255, 200, 200)
            opt.TextXAlignment = Enum.TextXAlignment.Left
            opt.Text = "[ " .. optId .. " ]"
            opt.Parent = cell

            local roster = Instance.new("TextLabel")
            roster.Position = UDim2.fromOffset(8, 26)
            roster.Size = UDim2.fromOffset(264, 40)
            roster.BackgroundTransparency = 1
            roster.Font = Theme.Font
            roster.TextSize = 13
            roster.TextColor3 = Color3.fromRGB(220, 220, 220)
            roster.TextXAlignment = Enum.TextXAlignment.Left
            roster.TextYAlignment = Enum.TextYAlignment.Top
            roster.TextWrapped = true
            roster.Text = table.concat(names, ", ")
            roster.Parent = cell
        end
    end

    fadeIn(stripe)
end

local function showVictory(payload: any)
    destroy()
    local pg = player:WaitForChild("PlayerGui")
    sg = Instance.new("ScreenGui")
    sg.Name = "DuelBanner"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 90
    sg.Parent = pg

    local stripe = Instance.new("Frame")
    stripe.AnchorPoint = Vector2.new(0.5, 0.5)
    stripe.Position = UDim2.fromScale(0.5, 0.5)
    stripe.Size = UDim2.new(1, 0, 0, 160)
    stripe.BackgroundColor3 = Color3.fromRGB(0, 60, 30)
    stripe.BorderSizePixel = 0
    stripe.Parent = sg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 220, 140)
    stroke.Thickness = 2
    stroke.Parent = stripe

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.Position = UDim2.new(0.5, 0, 0, 24)
    title.Size = UDim2.fromOffset(900, 56)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 44
    title.TextColor3 = Color3.fromRGB(220, 255, 220)
    title.TextStrokeTransparency = 0
    title.Text = "DUEL DECIDED"
    title.Parent = stripe

    local sub = Instance.new("TextLabel")
    sub.AnchorPoint = Vector2.new(0.5, 0)
    sub.Position = UDim2.new(0.5, 0, 0, 88)
    sub.Size = UDim2.fromOffset(900, 36)
    sub.BackgroundTransparency = 1
    sub.Font = Theme.Font
    sub.TextSize = 22
    sub.TextColor3 = Color3.fromRGB(220, 255, 220)
    sub.Text = string.format("Winner: %s", payload.winnerLabel or payload.winnerOption or "?")
    sub.Parent = stripe

    fadeIn(stripe)
    task.delay(4, function()
        if sg and sg.Name == "DuelBanner" then
            destroy()
        end
    end)
end

function DuelBannerUI.start()
    local showEv = Remotes.get("ShowDuelBanner") :: RemoteEvent
    showEv.OnClientEvent:Connect(function(payload: any)
        if payload.stage == "start" then
            showStart(payload)
        elseif payload.stage == "victory" then
            showVictory(payload)
        end
    end)
    local closeEv = Remotes.get("CloseDuelBanner") :: RemoteEvent
    closeEv.OnClientEvent:Connect(destroy)
end

return DuelBannerUI
