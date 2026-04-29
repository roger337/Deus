--!strict
-- Bar-locked-in lockpick minigame: a moving cursor must stop inside a sweet spot.
-- Difficulty shrinks the spot; Lockpicking skill grows it.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Parent.Theme)
local Skills = require(Shared.Config.Skills)
local Remotes = require(Shared.Remotes)

local Lockpick = {}

local player = Players.LocalPlayer
local activeTarget: Instance? = nil

local skillState: any = { Lockpicking = { rank = "Untrained" } }

local function buildGui()
    local pg = player:WaitForChild("PlayerGui")
    local existing = pg:FindFirstChild("LockpickUI")
    if existing then return existing :: ScreenGui end
    local sg = Instance.new("ScreenGui")
    sg.Name = "LockpickUI"
    sg.ResetOnSpawn = false
    sg.Enabled = false
    sg.Parent = pg
    return sg
end

local function attempt(difficulty: number, onResult: (boolean) -> ())
    local sg = buildGui()
    sg.Enabled = true

    -- clear any prior contents
    for _, c in ipairs(sg:GetChildren()) do c:Destroy() end

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(560, 200)
    panel.BackgroundColor3 = Theme.Panel
    panel.BorderSizePixel = 0
    panel.Parent = sg
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(16, 12)
    title.Size = UDim2.fromOffset(528, 24)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 18
    title.TextColor3 = Theme.Accent
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = string.format("LOCKPICK — Difficulty %d — [SPACE] to pick", difficulty)
    title.Parent = panel

    local trackBg = Instance.new("Frame")
    trackBg.Position = UDim2.fromOffset(16, 80)
    trackBg.Size = UDim2.fromOffset(528, 30)
    trackBg.BackgroundColor3 = Theme.Bg
    trackBg.BorderSizePixel = 0
    trackBg.Parent = panel

    local skillMult = Skills.Skills.Lockpicking.multipliers[skillState.Lockpicking.rank or "Untrained"]
    local zoneWidth = math.clamp(140 * (skillMult / difficulty), 30, 250)
    local zoneStart = math.random(0, math.floor(528 - zoneWidth))

    local zone = Instance.new("Frame")
    zone.Position = UDim2.fromOffset(zoneStart, 0)
    zone.Size = UDim2.fromOffset(zoneWidth, 30)
    zone.BackgroundColor3 = Theme.Good
    zone.BackgroundTransparency = 0.4
    zone.BorderSizePixel = 0
    zone.Parent = trackBg

    local cursor = Instance.new("Frame")
    cursor.Size = UDim2.fromOffset(4, 30)
    cursor.BackgroundColor3 = Theme.Accent
    cursor.BorderSizePixel = 0
    cursor.Parent = trackBg

    local hint = Instance.new("TextLabel")
    hint.Position = UDim2.fromOffset(16, 130)
    hint.Size = UDim2.fromOffset(528, 60)
    hint.BackgroundTransparency = 1
    hint.Font = Theme.Font
    hint.TextSize = 14
    hint.TextColor3 = Theme.TextDim
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.TextWrapped = true
    hint.Text = "Stop the cursor inside the lit zone. Press ESC to cancel."
    hint.Parent = panel

    local pos = 0
    local dir = 1
    local speed = 380 + difficulty * 60
    local running = true
    local conn: RBXScriptConnection? = nil
    local inputConn: RBXScriptConnection? = nil

    local function cleanup()
        running = false
        if conn then conn:Disconnect() end
        if inputConn then inputConn:Disconnect() end
        sg.Enabled = false
        for _, c in ipairs(sg:GetChildren()) do c:Destroy() end
    end

    conn = RunService.RenderStepped:Connect(function(dt)
        if not running then return end
        pos += dir * speed * dt
        if pos >= 528 - 4 then pos = 528 - 4; dir = -1 end
        if pos <= 0 then pos = 0; dir = 1 end
        cursor.Position = UDim2.fromOffset(pos, 0)
    end)

    inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not running then return end
        if input.KeyCode == Enum.KeyCode.Space then
            local ok = pos >= zoneStart and pos <= zoneStart + zoneWidth
            cleanup()
            onResult(ok)
        elseif input.KeyCode == Enum.KeyCode.Escape then
            cleanup()
            onResult(false)
        end
    end)
end

function Lockpick.start()
    local ev = Remotes.get("AttemptLockpick") :: RemoteEvent
    ev.OnClientEvent:Connect(function(target: Instance, difficulty: number)
        activeTarget = target
        attempt(difficulty, function(success)
            local replyEv = Remotes.get("AttemptLockpick") :: RemoteEvent
            replyEv:FireServer(target, success)
        end)
    end)

    local statsEv = Remotes.get("StatsUpdate") :: RemoteEvent
    statsEv.OnClientEvent:Connect(function(payload: any)
        if payload.skills then skillState = payload.skills end
    end)
end

return Lockpick
