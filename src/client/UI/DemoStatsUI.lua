--!strict
-- "Demo complete" summary that shows when the player exits the Demo Range.
-- Shows their stats and offers a Request Access shortcut.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Remotes = require(Shared.Remotes)

local DemoStatsUI = {}

local player = Players.LocalPlayer
local sg: ScreenGui? = nil

local function destroy()
    if sg then sg:Destroy() end
    sg = nil
end

local function fmtTime(seconds: number): string
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%d:%02d", m, s)
end

local function show(payload: any)
    destroy()
    local pg = player:WaitForChild("PlayerGui")
    sg = Instance.new("ScreenGui")
    sg.Name = "DemoStatsUI"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 75
    sg.Parent = pg

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(560, 460)
    panel.BackgroundColor3 = Theme.Panel
    panel.BorderSizePixel = 0
    panel.Parent = sg
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(120, 220, 120)
    stroke.Thickness = 1
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(16, 12)
    title.Size = UDim2.fromOffset(528, 32)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 22
    title.TextColor3 = Color3.fromRGB(120, 220, 120)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "DEMO COMPLETE"
    title.Parent = panel

    local sub = Instance.new("TextLabel")
    sub.Position = UDim2.fromOffset(16, 46)
    sub.Size = UDim2.fromOffset(528, 22)
    sub.BackgroundTransparency = 1
    sub.Font = Theme.Font
    sub.TextSize = 14
    sub.TextColor3 = Theme.TextDim
    sub.TextXAlignment = Enum.TextXAlignment.Left
    sub.Text = string.format("Time on range: %s", fmtTime(payload.elapsedSec or 0))
    sub.Parent = panel

    local rows = {
        { "Hostiles eliminated",  payload.kills or 0 },
        { "Hostiles knocked out", payload.knockouts or 0 },
        { "Civilians killed",     payload.civiliansKilled or 0 },
        { "Locks picked",         payload.locksPicked or 0 },
        { "Terminals hacked",     payload.terminalsHacked or 0 },
        { "Hits taken",           payload.hitsTaken or 0 },
    }

    for i, row in ipairs(rows) do
        local r = Instance.new("Frame")
        r.Position = UDim2.fromOffset(16, 90 + (i - 1) * 36)
        r.Size = UDim2.fromOffset(528, 32)
        r.BackgroundColor3 = Theme.Bg
        r.BorderSizePixel = 0
        r.Parent = panel
        local rs = Instance.new("UIStroke")
        rs.Color = Theme.Border
        rs.Thickness = 1
        rs.Parent = r

        local lbl = Instance.new("TextLabel")
        lbl.Position = UDim2.fromOffset(12, 0)
        lbl.Size = UDim2.fromScale(0.7, 1)
        lbl.BackgroundTransparency = 1
        lbl.Font = Theme.Font
        lbl.TextSize = 14
        lbl.TextColor3 = Theme.Text
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Text = row[1]
        lbl.Parent = r

        local val = Instance.new("TextLabel")
        val.AnchorPoint = Vector2.new(1, 0)
        val.Position = UDim2.new(1, -12, 0, 0)
        val.Size = UDim2.fromScale(0.3, 1)
        val.BackgroundTransparency = 1
        val.Font = Theme.Font
        val.TextSize = 16
        val.TextColor3 = Theme.Accent
        val.TextXAlignment = Enum.TextXAlignment.Right
        val.Text = tostring(row[2])
        val.Parent = r
    end

    local cta = Instance.new("TextLabel")
    cta.Position = UDim2.fromOffset(16, 318)
    cta.Size = UDim2.fromOffset(528, 60)
    cta.BackgroundTransparency = 1
    cta.Font = Theme.Font
    cta.TextSize = 14
    cta.TextColor3 = Theme.TextDim
    cta.TextXAlignment = Enum.TextXAlignment.Left
    cta.TextYAlignment = Enum.TextYAlignment.Top
    cta.TextWrapped = true
    cta.Text = "Ready for the campaign? Request team access from the lobby terminal. " ..
        "Once your team is approved you can come and go freely."
    cta.Parent = panel

    local function styledButton(text: string, x: number, color: Color3?)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(0, 1)
        b.Position = UDim2.fromOffset(x, 444)
        b.Size = UDim2.fromOffset(252, 36)
        b.BackgroundColor3 = color or Theme.Bg
        b.BorderSizePixel = 0
        b.Font = Theme.Font
        b.TextSize = 14
        b.TextColor3 = Theme.Text
        b.Text = text
        local s = Instance.new("UIStroke")
        s.Color = Theme.Border
        s.Thickness = 1
        s.Parent = b
        b.Parent = panel
        return b
    end

    local request = styledButton("REQUEST ACCESS", 16, Color3.fromRGB(40, 80, 40))
    local close = styledButton("CLOSE", 292)

    request.MouseButton1Click:Connect(function()
        local ev = Remotes.get("ShowRequestAccess") :: RemoteEvent
        -- Have to flip to client-side: ShowRequestAccess is server->client.
        -- The proper UX is for the player to walk to the lobby terminal,
        -- but as a shortcut we mimic an "open request UI" by firing the
        -- existing UI directly via local module require.
        local RequestAccessUI = require(script.Parent.RequestAccessUI)
        if RequestAccessUI._show then RequestAccessUI._show() end
        destroy()
    end)
    close.MouseButton1Click:Connect(destroy)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not sg then return end
        if input.KeyCode == Enum.KeyCode.Escape then destroy() end
    end)
end

function DemoStatsUI.start()
    local ev = Remotes.get("ShowDemoStats") :: RemoteEvent
    ev.OnClientEvent:Connect(show)
end

return DemoStatsUI
