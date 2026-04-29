--!strict
-- Save slot selection. Shown to the player on join. Three slots; each
-- shows a summary (faction, kills, civilians killed) or "Empty". Each
-- slot has Continue / New Game buttons.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Remotes = require(Shared.Remotes)

local SlotSelectUI = {}

local player = Players.LocalPlayer

local function styleButton(b: TextButton, color: Color3?)
    b.BackgroundColor3 = color or Theme.Bg
    b.BorderSizePixel = 0
    b.TextColor3 = Theme.Text
    b.Font = Theme.Font
    b.TextSize = 14
    local s = Instance.new("UIStroke")
    s.Color = Theme.Border
    s.Thickness = 1
    s.Parent = b
end

local function show(payload: any)
    local pg = player:WaitForChild("PlayerGui")
    local existing = pg:FindFirstChild("SlotSelectUI")
    if existing then existing:Destroy() end
    local sg = Instance.new("ScreenGui")
    sg.Name = "SlotSelectUI"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.DisplayOrder = 80
    sg.Parent = pg

    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.1
    backdrop.BorderSizePixel = 0
    backdrop.Parent = sg

    local title = Instance.new("TextLabel")
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.Position = UDim2.new(0.5, 0, 0, 80)
    title.Size = UDim2.fromOffset(700, 60)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 36
    title.TextColor3 = Theme.Accent
    title.Text = "DEUS EX  |  SELECT SAVE"
    title.Parent = sg

    local container = Instance.new("Frame")
    container.AnchorPoint = Vector2.new(0.5, 0)
    container.Position = UDim2.new(0.5, 0, 0, 180)
    container.Size = UDim2.fromOffset(700, 460)
    container.BackgroundTransparency = 1
    container.Parent = sg
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 12)
    layout.Parent = container

    for slot = 1, 3 do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, 0, 0, 130)
        row.BackgroundColor3 = Theme.Panel
        row.BorderSizePixel = 0
        row.Parent = container
        local rs = Instance.new("UIStroke")
        rs.Color = Theme.Border
        rs.Thickness = 1
        rs.Parent = row

        local slotTitle = Instance.new("TextLabel")
        slotTitle.Position = UDim2.fromOffset(16, 8)
        slotTitle.Size = UDim2.fromOffset(680, 24)
        slotTitle.BackgroundTransparency = 1
        slotTitle.Font = Theme.Font
        slotTitle.TextSize = 18
        slotTitle.TextColor3 = Theme.Accent
        slotTitle.TextXAlignment = Enum.TextXAlignment.Left
        slotTitle.Text = string.format("SLOT %d", slot)
        slotTitle.Parent = row

        local summary = Instance.new("TextLabel")
        summary.Position = UDim2.fromOffset(16, 36)
        summary.Size = UDim2.fromOffset(680, 50)
        summary.BackgroundTransparency = 1
        summary.Font = Theme.Font
        summary.TextSize = 14
        summary.TextColor3 = Theme.Text
        summary.TextXAlignment = Enum.TextXAlignment.Left
        summary.TextYAlignment = Enum.TextYAlignment.Top
        summary.TextWrapped = true
        local entry = (payload.slots or {})[tostring(slot)]
        if entry then
            summary.Text = string.format(
                "Faction: %s   |   Kills: %d   |   Civilians killed: %d   |   Skill points: %d",
                tostring(entry.faction or "?"),
                entry.kills or 0,
                entry.civiliansKilled or 0,
                entry.skillPoints or 0
            )
        else
            summary.Text = "(empty)"
            summary.TextColor3 = Theme.TextDim
        end
        summary.Parent = row

        local continueBtn = Instance.new("TextButton")
        continueBtn.AnchorPoint = Vector2.new(1, 1)
        continueBtn.Position = UDim2.new(1, -180, 1, -16)
        continueBtn.Size = UDim2.fromOffset(160, 32)
        continueBtn.Text = "CONTINUE"
        styleButton(continueBtn)
        continueBtn.Parent = row
        if not entry then
            continueBtn.AutoButtonColor = false
            continueBtn.TextColor3 = Theme.TextDim
        end

        local newBtn = Instance.new("TextButton")
        newBtn.AnchorPoint = Vector2.new(1, 1)
        newBtn.Position = UDim2.new(1, -16, 1, -16)
        newBtn.Size = UDim2.fromOffset(160, 32)
        newBtn.Text = "NEW GAME"
        styleButton(newBtn, Color3.fromRGB(60, 30, 30))
        newBtn.Parent = row

        continueBtn.MouseButton1Click:Connect(function()
            if not entry then return end
            local ev = Remotes.get("SelectSaveSlot") :: RemoteEvent
            ev:FireServer(slot, false)
            sg:Destroy()
        end)
        newBtn.MouseButton1Click:Connect(function()
            local ev = Remotes.get("SelectSaveSlot") :: RemoteEvent
            ev:FireServer(slot, true)
            sg:Destroy()
        end)
    end
end

function SlotSelectUI.start()
    local ev = Remotes.get("ShowSlotSelect") :: RemoteEvent
    ev.OnClientEvent:Connect(show)
end

return SlotSelectUI
