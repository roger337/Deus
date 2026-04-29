--!strict
-- Fullscreen epilogue UI. Receives ShowEnding cues from EndingService and
-- displays the title + paragraphs of epilogue text on a tinted background,
-- one paragraph at a time. Locks input while playing.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Remotes = require(Shared.Remotes)

local EndingScreen = {}

local player = Players.LocalPlayer

local function show(payload: any)
    local pg = player:WaitForChild("PlayerGui")
    -- Tear down any existing instance.
    local existing = pg:FindFirstChild("EndingScreen")
    if existing then existing:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "EndingScreen"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 100
    sg.Parent = pg

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BorderSizePixel = 0
    backdrop.Parent = sg

    local color = payload.color or { 200, 200, 200 }
    local accent = Color3.fromRGB(color[1], color[2], color[3])

    local tint = Instance.new("Frame")
    tint.Size = UDim2.fromScale(1, 1)
    tint.BackgroundColor3 = accent
    tint.BackgroundTransparency = 0.85
    tint.BorderSizePixel = 0
    tint.Parent = backdrop

    local titleLbl = Instance.new("TextLabel")
    titleLbl.AnchorPoint = Vector2.new(0.5, 0)
    titleLbl.Position = UDim2.new(0.5, 0, 0, 80)
    titleLbl.Size = UDim2.fromOffset(900, 60)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Theme.Font
    titleLbl.TextSize = 36
    titleLbl.TextColor3 = accent
    titleLbl.TextStrokeTransparency = 0
    titleLbl.Text = payload.title or ""
    titleLbl.Parent = sg

    local body = Instance.new("TextLabel")
    body.AnchorPoint = Vector2.new(0.5, 0.5)
    body.Position = UDim2.fromScale(0.5, 0.5)
    body.Size = UDim2.fromOffset(900, 360)
    body.BackgroundTransparency = 1
    body.Font = Theme.Font
    body.TextSize = 22
    body.TextColor3 = Theme.Text
    body.TextWrapped = true
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Text = ""
    body.Parent = sg

    local hint = Instance.new("TextLabel")
    hint.AnchorPoint = Vector2.new(0.5, 1)
    hint.Position = UDim2.new(0.5, 0, 1, -60)
    hint.Size = UDim2.fromOffset(600, 20)
    hint.BackgroundTransparency = 1
    hint.Font = Theme.Font
    hint.TextSize = 14
    hint.TextColor3 = Theme.TextDim
    hint.Text = "[Space] continue"
    hint.Parent = sg

    local paragraphs = payload.epilogue or {}
    local idx = 0
    local advancing = false

    local function nextParagraph()
        if advancing then return end
        idx += 1
        if idx > #paragraphs then
            sg:Destroy()
            return
        end
        body.Text = paragraphs[idx]
        body.TextTransparency = 1
        advancing = true
        -- Quick fade-in
        for t = 0, 1, 0.05 do
            body.TextTransparency = 1 - t
            task.wait(0.02)
        end
        body.TextTransparency = 0
        advancing = false
    end

    nextParagraph()
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Space and sg.Parent then
            nextParagraph()
        end
    end)
end

function EndingScreen.start()
    local ev = Remotes.get("ShowEnding") :: RemoteEvent
    ev.OnClientEvent:Connect(show)
end

return EndingScreen
