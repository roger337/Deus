--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Skills = require(Shared.Config.Skills)
local Remotes = require(Shared.Remotes)

local SkillsUI = {}

local player = Players.LocalPlayer
local visible = false
local state = { skills = {}, skillPoints = 0 }

function SkillsUI.start()
    local pg = player:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "SkillsUI"
    sg.ResetOnSpawn = false
    sg.Enabled = false
    sg.Parent = pg

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(640, 520)
    panel.BackgroundColor3 = Theme.Panel
    panel.BorderSizePixel = 0
    panel.Parent = sg
    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(16, 12)
    title.Size = UDim2.fromOffset(400, 28)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 22
    title.TextColor3 = Theme.Accent
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "SKILLS"
    title.Parent = panel

    local pointsLbl = Instance.new("TextLabel")
    pointsLbl.AnchorPoint = Vector2.new(1, 0)
    pointsLbl.Position = UDim2.new(1, -16, 0, 16)
    pointsLbl.Size = UDim2.fromOffset(280, 24)
    pointsLbl.BackgroundTransparency = 1
    pointsLbl.Font = Theme.Font
    pointsLbl.TextSize = 16
    pointsLbl.TextColor3 = Theme.Accent
    pointsLbl.TextXAlignment = Enum.TextXAlignment.Right
    pointsLbl.Parent = panel

    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.fromOffset(16, 50)
    list.Size = UDim2.fromOffset(608, 460)
    list.BackgroundColor3 = Theme.Bg
    list.BorderSizePixel = 0
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.ScrollBarThickness = 4
    list.Parent = panel
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = list

    local function refresh()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("Frame") then child:Destroy() end
        end
        pointsLbl.Text = string.format("Skill Points: %d", state.skillPoints)
        for id, def in pairs(Skills.Skills) do
            local cur = (state.skills :: any)[id]
            local rank = cur and cur.rank or "Untrained"
            local nextRank = Skills.nextRank(rank)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, -8, 0, 50)
            row.BackgroundColor3 = Theme.Bg
            row.BorderSizePixel = 0
            row.Parent = list
            local rs = Instance.new("UIStroke")
            rs.Color = Theme.Border
            rs.Thickness = 1
            rs.Parent = row

            local nameLbl = Instance.new("TextLabel")
            nameLbl.Position = UDim2.fromOffset(12, 6)
            nameLbl.Size = UDim2.fromOffset(200, 18)
            nameLbl.BackgroundTransparency = 1
            nameLbl.Font = Theme.Font
            nameLbl.TextSize = 16
            nameLbl.TextColor3 = Theme.Text
            nameLbl.TextXAlignment = Enum.TextXAlignment.Left
            nameLbl.Text = def.name
            nameLbl.Parent = row

            local descLbl = Instance.new("TextLabel")
            descLbl.Position = UDim2.fromOffset(12, 24)
            descLbl.Size = UDim2.fromOffset(380, 18)
            descLbl.BackgroundTransparency = 1
            descLbl.Font = Theme.Font
            descLbl.TextSize = 12
            descLbl.TextColor3 = Theme.TextDim
            descLbl.TextXAlignment = Enum.TextXAlignment.Left
            descLbl.Text = def.description
            descLbl.Parent = row

            local rankLbl = Instance.new("TextLabel")
            rankLbl.Position = UDim2.fromOffset(220, 6)
            rankLbl.Size = UDim2.fromOffset(160, 18)
            rankLbl.BackgroundTransparency = 1
            rankLbl.Font = Theme.Font
            rankLbl.TextSize = 14
            rankLbl.TextColor3 = Theme.Accent
            rankLbl.TextXAlignment = Enum.TextXAlignment.Left
            rankLbl.Text = "Rank: " .. rank
            rankLbl.Parent = row

            local btn = Instance.new("TextButton")
            btn.AnchorPoint = Vector2.new(1, 0.5)
            btn.Position = UDim2.new(1, -12, 0.5, 0)
            btn.Size = UDim2.fromOffset(180, 30)
            btn.BackgroundColor3 = Theme.Bg
            btn.BorderSizePixel = 0
            btn.TextColor3 = Theme.Text
            btn.Font = Theme.Font
            btn.TextSize = 14
            local bs = Instance.new("UIStroke")
            bs.Color = Theme.Border
            bs.Thickness = 1
            bs.Parent = btn
            btn.Parent = row

            if nextRank then
                local cost = def.costs[nextRank]
                btn.Text = string.format("Upgrade to %s (%d)", nextRank, cost)
                btn.MouseButton1Click:Connect(function()
                    local ev = Remotes.get("AllocateSkill") :: RemoteEvent
                    ev:FireServer(id)
                end)
            else
                btn.Text = "MAXED"
                btn.TextColor3 = Theme.Good
            end
        end
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.K then
            visible = not visible
            sg.Enabled = visible
            if visible then refresh() end
        end
    end)

    local statsEv = Remotes.get("StatsUpdate") :: RemoteEvent
    statsEv.OnClientEvent:Connect(function(payload: any)
        if payload.skills then state.skills = payload.skills end
        if payload.skillPoints then state.skillPoints = payload.skillPoints end
        if visible then refresh() end
    end)
end

return SkillsUI
