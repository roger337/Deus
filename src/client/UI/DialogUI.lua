--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Remotes = require(Shared.Remotes)

local DialogUI = {}

local player = Players.LocalPlayer

function DialogUI.start()
    local pg = player:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "DialogUI"
    sg.ResetOnSpawn = false
    sg.Enabled = false
    sg.Parent = pg

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 1)
    panel.Position = UDim2.new(0.5, 0, 1, -16)
    panel.Size = UDim2.fromOffset(820, 280)
    panel.BackgroundColor3 = Theme.Panel
    panel.BorderSizePixel = 0
    panel.Parent = sg
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = panel

    local speakerLbl = Instance.new("TextLabel")
    speakerLbl.Position = UDim2.fromOffset(16, 8)
    speakerLbl.Size = UDim2.fromOffset(400, 24)
    speakerLbl.BackgroundTransparency = 1
    speakerLbl.Font = Theme.Font
    speakerLbl.TextSize = 18
    speakerLbl.TextColor3 = Theme.Accent
    speakerLbl.TextXAlignment = Enum.TextXAlignment.Left
    speakerLbl.Parent = panel

    local textLbl = Instance.new("TextLabel")
    textLbl.Position = UDim2.fromOffset(16, 36)
    textLbl.Size = UDim2.fromOffset(788, 100)
    textLbl.BackgroundTransparency = 1
    textLbl.Font = Theme.Font
    textLbl.TextSize = 16
    textLbl.TextColor3 = Theme.Text
    textLbl.TextXAlignment = Enum.TextXAlignment.Left
    textLbl.TextYAlignment = Enum.TextYAlignment.Top
    textLbl.TextWrapped = true
    textLbl.Parent = panel

    local options = Instance.new("Frame")
    options.Position = UDim2.fromOffset(16, 140)
    options.Size = UDim2.fromOffset(788, 130)
    options.BackgroundTransparency = 1
    options.Parent = panel
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = options

    local function clearOptions()
        for _, child in ipairs(options:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
    end

    local function endDialog()
        sg.Enabled = false
        local ev = Remotes.get("EndDialog") :: RemoteEvent
        ev:FireServer()
    end

    local reqEv = Remotes.get("RequestDialog") :: RemoteEvent
    reqEv.OnClientEvent:Connect(function(payload: any)
        sg.Enabled = true
        speakerLbl.Text = payload.speaker or payload.npc
        textLbl.Text = payload.text
        clearOptions()
        for i, opt in ipairs(payload.options) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, 26)
            btn.BackgroundColor3 = Theme.Bg
            btn.BorderSizePixel = 0
            btn.TextColor3 = Theme.Text
            btn.Font = Theme.Font
            btn.TextSize = 14
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Text = string.format("  %d. %s", i, opt.text)
            local bs = Instance.new("UIStroke")
            bs.Color = Theme.Border
            bs.Thickness = 1
            bs.Parent = btn
            btn.Parent = options
            btn.MouseButton1Click:Connect(function()
                local ev = Remotes.get("ChooseDialogOption") :: RemoteEvent
                ev:FireServer(opt.index)
            end)
        end
    end)

    local endEv = Remotes.get("EndDialog") :: RemoteEvent
    endEv.OnClientEvent:Connect(function()
        sg.Enabled = false
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not sg.Enabled then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            endDialog()
        end
    end)
end

return DialogUI
