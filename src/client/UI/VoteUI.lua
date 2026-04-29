--!strict
-- Co-op vote prompt UI. Listens for OpenVote / VoteUpdate / CloseVote.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Remotes = require(Shared.Remotes)

local VoteUI = {}

local player = Players.LocalPlayer

local activeId: string? = nil
local sg: ScreenGui? = nil
local tallyLabels: { [string]: TextLabel } = {}
local timerLabel: TextLabel? = nil
local castedFor: string? = nil
local closeAt: number? = nil

local function destroyUI()
    if sg then sg:Destroy() end
    sg = nil
    activeId = nil
    tallyLabels = {}
    timerLabel = nil
    castedFor = nil
    closeAt = nil
end

local function buildUI(payload: any)
    destroyUI()
    activeId = payload.voteId
    closeAt = os.clock() + (payload.timeoutSec or 30)

    local pg = player:WaitForChild("PlayerGui")
    sg = Instance.new("ScreenGui")
    sg.Name = "VoteUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 50
    sg.Parent = pg

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0)
    panel.Position = UDim2.new(0.5, 0, 0, 80)
    panel.Size = UDim2.fromOffset(560, 240)
    panel.BackgroundColor3 = Theme.Panel
    panel.BorderSizePixel = 0
    panel.Parent = sg
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Accent
    stroke.Thickness = 1
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(16, 8)
    title.Size = UDim2.fromOffset(528, 24)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 16
    title.TextColor3 = Theme.Accent
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "TEAM VOTE"
    title.Parent = panel

    local prompt = Instance.new("TextLabel")
    prompt.Position = UDim2.fromOffset(16, 36)
    prompt.Size = UDim2.fromOffset(528, 60)
    prompt.BackgroundTransparency = 1
    prompt.Font = Theme.Font
    prompt.TextSize = 14
    prompt.TextColor3 = Theme.Text
    prompt.TextWrapped = true
    prompt.TextXAlignment = Enum.TextXAlignment.Left
    prompt.TextYAlignment = Enum.TextYAlignment.Top
    prompt.Text = payload.prompt or ""
    prompt.Parent = panel

    local optionsFrame = Instance.new("Frame")
    optionsFrame.Position = UDim2.fromOffset(16, 100)
    optionsFrame.Size = UDim2.fromOffset(528, 100)
    optionsFrame.BackgroundTransparency = 1
    optionsFrame.Parent = panel
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = optionsFrame

    for _, opt in ipairs(payload.options) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 28)
        row.BackgroundTransparency = 1
        row.Parent = optionsFrame

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -80, 1, 0)
        btn.BackgroundColor3 = Theme.Bg
        btn.BorderSizePixel = 0
        btn.Font = Theme.Font
        btn.TextSize = 14
        btn.TextColor3 = Theme.Text
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Text = "  " .. opt.label
        local bs = Instance.new("UIStroke")
        bs.Color = Theme.Border
        bs.Thickness = 1
        bs.Parent = btn
        btn.Parent = row
        btn.MouseButton1Click:Connect(function()
            if not activeId then return end
            castedFor = opt.id
            local ev = Remotes.get("CastVote") :: RemoteEvent
            ev:FireServer(activeId, opt.id)
            -- Visual feedback: dim other rows.
            for _, child in ipairs(optionsFrame:GetChildren()) do
                if child:IsA("Frame") then
                    local b = child:FindFirstChildWhichIsA("TextButton")
                    if b then
                        b.AutoButtonColor = false
                        b.TextColor3 = Theme.TextDim
                    end
                end
            end
            btn.TextColor3 = Theme.Accent
        end)

        local tally = Instance.new("TextLabel")
        tally.AnchorPoint = Vector2.new(1, 0.5)
        tally.Position = UDim2.new(1, 0, 0.5, 0)
        tally.Size = UDim2.fromOffset(72, 28)
        tally.BackgroundTransparency = 1
        tally.Font = Theme.Font
        tally.TextSize = 14
        tally.TextColor3 = Theme.Accent
        tally.Text = "0"
        tally.Parent = row
        tallyLabels[opt.id] = tally
    end

    local timer = Instance.new("TextLabel")
    timer.Position = UDim2.fromOffset(16, 210)
    timer.Size = UDim2.fromOffset(528, 20)
    timer.BackgroundTransparency = 1
    timer.Font = Theme.Font
    timer.TextSize = 12
    timer.TextColor3 = Theme.TextDim
    timer.TextXAlignment = Enum.TextXAlignment.Left
    timer.Text = ""
    timer.Parent = panel
    timerLabel = timer
end

function VoteUI.start()
    local openEv = Remotes.get("OpenVote") :: RemoteEvent
    openEv.OnClientEvent:Connect(buildUI)

    local updEv = Remotes.get("VoteUpdate") :: RemoteEvent
    updEv.OnClientEvent:Connect(function(payload: any)
        if payload.voteId ~= activeId then return end
        for optId, count in pairs(payload.tally) do
            local lbl = tallyLabels[optId]
            if lbl then lbl.Text = tostring(count) end
        end
    end)

    local closeEv = Remotes.get("CloseVote") :: RemoteEvent
    closeEv.OnClientEvent:Connect(function(payload: any)
        if not activeId or payload.voteId == activeId then
            destroyUI()
        end
    end)

    -- Timer ticker
    task.spawn(function()
        while true do
            task.wait(0.5)
            if timerLabel and closeAt then
                local remaining = math.max(0, closeAt - os.clock())
                timerLabel.Text = string.format("Closing in %.0fs", remaining)
            end
        end
    end)
end

return VoteUI
