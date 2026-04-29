--!strict
-- Multitool hack: type the displayed sequence within a time limit.
-- Sequence length grows with difficulty; Computer skill adds time.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Parent.Theme)
local Skills = require(Shared.Config.Skills)
local Remotes = require(Shared.Remotes)

local Hack = {}

local player = Players.LocalPlayer
local skillState: any = { Computer = { rank = "Untrained" } }

local CHARS = "ABCDEF0123456789"

local function buildGui()
    local pg = player:WaitForChild("PlayerGui")
    local existing = pg:FindFirstChild("HackUI")
    if existing then return existing :: ScreenGui end
    local sg = Instance.new("ScreenGui")
    sg.Name = "HackUI"
    sg.ResetOnSpawn = false
    sg.Enabled = false
    sg.Parent = pg
    return sg
end

local function randomSequence(n: number): string
    local s = ""
    for i = 1, n do
        local idx = math.random(1, #CHARS)
        s ..= string.sub(CHARS, idx, idx)
    end
    return s
end

local function attempt(difficulty: number, onResult: (boolean) -> ())
    local sg = buildGui()
    sg.Enabled = true
    for _, c in ipairs(sg:GetChildren()) do c:Destroy() end

    local len = 4 + difficulty * 2
    local skillMult = Skills.Skills.Computer.multipliers[skillState.Computer.rank or "Untrained"]
    local timeLimit = (5 + difficulty * 3) * skillMult
    local sequence = randomSequence(len)
    local typed = ""

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(640, 240)
    panel.BackgroundColor3 = Theme.Panel
    panel.BorderSizePixel = 0
    panel.Parent = sg
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(16, 12)
    title.Size = UDim2.fromOffset(608, 24)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 18
    title.TextColor3 = Theme.Accent
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = string.format("HACK TERMINAL - Difficulty %d", difficulty)
    title.Parent = panel

    local seqLbl = Instance.new("TextLabel")
    seqLbl.Position = UDim2.fromOffset(16, 50)
    seqLbl.Size = UDim2.fromOffset(608, 60)
    seqLbl.BackgroundColor3 = Theme.Bg
    seqLbl.BorderSizePixel = 0
    seqLbl.Font = Enum.Font.RobotoMono
    seqLbl.TextSize = 36
    seqLbl.TextColor3 = Theme.Text
    seqLbl.Text = sequence
    seqLbl.Parent = panel

    local typedLbl = Instance.new("TextLabel")
    typedLbl.Position = UDim2.fromOffset(16, 120)
    typedLbl.Size = UDim2.fromOffset(608, 60)
    typedLbl.BackgroundTransparency = 1
    typedLbl.Font = Enum.Font.RobotoMono
    typedLbl.TextSize = 36
    typedLbl.TextColor3 = Theme.Good
    typedLbl.Text = ""
    typedLbl.Parent = panel

    local timerLbl = Instance.new("TextLabel")
    timerLbl.Position = UDim2.fromOffset(16, 200)
    timerLbl.Size = UDim2.fromOffset(608, 24)
    timerLbl.BackgroundTransparency = 1
    timerLbl.Font = Theme.Font
    timerLbl.TextSize = 14
    timerLbl.TextColor3 = Theme.Bad
    timerLbl.TextXAlignment = Enum.TextXAlignment.Left
    timerLbl.Parent = panel

    local startTime = os.clock()
    local running = true
    local rsConn: RBXScriptConnection? = nil
    local inputConn: RBXScriptConnection? = nil

    local function cleanup()
        running = false
        if rsConn then rsConn:Disconnect() end
        if inputConn then inputConn:Disconnect() end
        sg.Enabled = false
        for _, c in ipairs(sg:GetChildren()) do c:Destroy() end
    end

    rsConn = RunService.Heartbeat:Connect(function()
        if not running then return end
        local remaining = timeLimit - (os.clock() - startTime)
        if remaining <= 0 then
            cleanup(); onResult(false); return
        end
        timerLbl.Text = string.format("Time remaining: %.1fs", remaining)
    end)

    inputConn = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not running then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            cleanup(); onResult(false); return
        end
        local kc = input.KeyCode
        local ch
        if kc.Value >= Enum.KeyCode.A.Value and kc.Value <= Enum.KeyCode.F.Value then
            ch = kc.Name
        elseif kc.Value >= Enum.KeyCode.Zero.Value and kc.Value <= Enum.KeyCode.Nine.Value then
            ch = string.sub(kc.Name, -1)
        end
        if not ch then return end
        local needed = string.sub(sequence, #typed + 1, #typed + 1)
        if ch == needed then
            typed ..= ch
            typedLbl.Text = typed
            if typed == sequence then
                cleanup(); onResult(true); return
            end
        else
            -- mistake clears progress
            typed = ""
            typedLbl.Text = ""
            typedLbl.TextColor3 = Theme.Bad
            task.delay(0.2, function() typedLbl.TextColor3 = Theme.Good end)
        end
    end)
end

function Hack.start()
    local ev = Remotes.get("AttemptHack") :: RemoteEvent
    ev.OnClientEvent:Connect(function(target: Instance, difficulty: number)
        attempt(difficulty, function(success)
            local replyEv = Remotes.get("AttemptHack") :: RemoteEvent
            replyEv:FireServer(target, success)
        end)
    end)

    local statsEv = Remotes.get("StatsUpdate") :: RemoteEvent
    statsEv.OnClientEvent:Connect(function(payload: any)
        if payload.skills then skillState = payload.skills end
    end)
end

return Hack
