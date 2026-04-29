--!strict
-- Modal that opens when a player interacts with the Request Access terminal
-- in the lobby. The player types a team name and submits. Server validates
-- and queues for owner approval (or auto-approves pre-listed teams).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Remotes = require(Shared.Remotes)

local RequestAccessUI = {}

local player = Players.LocalPlayer
local sg: ScreenGui? = nil

local function destroy()
    if sg then sg:Destroy() end
    sg = nil
end

local function show()
    destroy()
    local pg = player:WaitForChild("PlayerGui")
    sg = Instance.new("ScreenGui")
    sg.Name = "RequestAccessUI"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 60
    sg.Parent = pg

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(540, 280)
    panel.BackgroundColor3 = Theme.Panel
    panel.BorderSizePixel = 0
    panel.Parent = sg
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Accent
    stroke.Thickness = 1
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(16, 12)
    title.Size = UDim2.fromOffset(508, 28)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 20
    title.TextColor3 = Theme.Accent
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "REQUEST TEAM ACCESS"
    title.Parent = panel

    local body = Instance.new("TextLabel")
    body.Position = UDim2.fromOffset(16, 48)
    body.Size = UDim2.fromOffset(508, 80)
    body.BackgroundTransparency = 1
    body.Font = Theme.Font
    body.TextSize = 14
    body.TextColor3 = Theme.Text
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.TextWrapped = true
    body.Text = "Enter your team name. The owner will review and grant access. " ..
        "Once granted, you and your team can come and go freely."
    body.Parent = panel

    local input = Instance.new("TextBox")
    input.Position = UDim2.fromOffset(16, 140)
    input.Size = UDim2.fromOffset(508, 36)
    input.BackgroundColor3 = Theme.Bg
    input.BorderSizePixel = 0
    input.Font = Theme.Font
    input.TextSize = 16
    input.TextColor3 = Theme.Text
    input.PlaceholderText = "team name"
    input.Text = ""
    input.ClearTextOnFocus = false
    input.Parent = panel
    local is = Instance.new("UIStroke")
    is.Color = Theme.Border
    is.Thickness = 1
    is.Parent = input

    local function styledButton(text: string, x: number, color: Color3?)
        local b = Instance.new("TextButton")
        b.AnchorPoint = Vector2.new(0, 1)
        b.Position = UDim2.fromOffset(x, 264)
        b.Size = UDim2.fromOffset(240, 36)
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

    local submit = styledButton("SUBMIT REQUEST", 16, Color3.fromRGB(40, 80, 40))
    local cancel = styledButton("CANCEL", 280)

    submit.MouseButton1Click:Connect(function()
        local team = input.Text:gsub("^%s*(.-)%s*$", "%1")
        if team == "" then return end
        local ev = Remotes.get("RequestAccess") :: RemoteEvent
        ev:FireServer(team)
        destroy()
    end)
    cancel.MouseButton1Click:Connect(destroy)

    UserInputService.InputBegan:Connect(function(input2, processed)
        if processed or not sg then return end
        if input2.KeyCode == Enum.KeyCode.Escape then destroy() end
    end)
end

function RequestAccessUI.start()
    local ev = Remotes.get("ShowRequestAccess") :: RemoteEvent
    ev.OnClientEvent:Connect(show)
end

return RequestAccessUI
