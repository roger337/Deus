--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Augs = require(Shared.Config.Augmentations)
local Remotes = require(Shared.Remotes)

local AugUI = {}

local player = Players.LocalPlayer
local visible = false
local state = { augs = {} }

function AugUI.start()
    local pg = player:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "AugUI"
    sg.ResetOnSpawn = false
    sg.Enabled = false
    sg.Parent = pg

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(720, 540)
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
    title.Text = "NANO-AUGMENTATIONS"
    title.Parent = panel

    local closeHint = Instance.new("TextLabel")
    closeHint.AnchorPoint = Vector2.new(1, 0)
    closeHint.Position = UDim2.new(1, -16, 0, 16)
    closeHint.Size = UDim2.fromOffset(160, 24)
    closeHint.BackgroundTransparency = 1
    closeHint.Font = Theme.Font
    closeHint.TextSize = 14
    closeHint.TextColor3 = Theme.TextDim
    closeHint.Text = "U to close"
    closeHint.Parent = panel

    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.fromOffset(16, 50)
    list.Size = UDim2.fromOffset(688, 480)
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
        local sortedSlots = {}
        for _, s in ipairs(Augs.Slots) do table.insert(sortedSlots, s) end

        for _, slot in ipairs(sortedSlots) do
            local header = Instance.new("Frame")
            header.Size = UDim2.new(1, -8, 0, 24)
            header.BackgroundTransparency = 1
            header.Parent = list
            local hl = Instance.new("TextLabel")
            hl.Size = UDim2.fromScale(1, 1)
            hl.BackgroundTransparency = 1
            hl.Font = Theme.Font
            hl.TextSize = 16
            hl.TextColor3 = Theme.Accent
            hl.TextXAlignment = Enum.TextXAlignment.Left
            hl.Text = "[ " .. slot:upper() .. " ]"
            hl.Parent = header

            for _, augId in ipairs(Augs.augsForSlot(slot)) do
                local def = Augs.Augs[augId]
                local s = (state.augs :: any)[augId] or { installed = false, level = 0, active = false }

                local row = Instance.new("Frame")
                row.Size = UDim2.new(1, -8, 0, 60)
                row.BackgroundColor3 = Theme.Bg
                row.BorderSizePixel = 0
                row.Parent = list
                local rs = Instance.new("UIStroke")
                rs.Color = s.installed and Theme.Accent or Theme.Border
                rs.Thickness = 1
                rs.Parent = row

                local name = Instance.new("TextLabel")
                name.Position = UDim2.fromOffset(12, 4)
                name.Size = UDim2.fromOffset(280, 18)
                name.BackgroundTransparency = 1
                name.Font = Theme.Font
                name.TextSize = 16
                name.TextColor3 = Theme.Text
                name.TextXAlignment = Enum.TextXAlignment.Left
                name.Text = def.name
                name.Parent = row

                local desc = Instance.new("TextLabel")
                desc.Position = UDim2.fromOffset(12, 22)
                desc.Size = UDim2.fromOffset(380, 18)
                desc.BackgroundTransparency = 1
                desc.Font = Theme.Font
                desc.TextSize = 12
                desc.TextColor3 = Theme.TextDim
                desc.TextXAlignment = Enum.TextXAlignment.Left
                desc.Text = def.description
                desc.Parent = row

                local levelLbl = Instance.new("TextLabel")
                levelLbl.Position = UDim2.fromOffset(12, 40)
                levelLbl.Size = UDim2.fromOffset(380, 18)
                levelLbl.BackgroundTransparency = 1
                levelLbl.Font = Theme.Font
                levelLbl.TextSize = 12
                levelLbl.TextColor3 = Theme.Accent
                levelLbl.TextXAlignment = Enum.TextXAlignment.Left
                if s.installed then
                    levelLbl.Text = string.format("Level %d/4 - %s", s.level, def.levels[s.level])
                else
                    levelLbl.Text = "Not installed"
                end
                levelLbl.Parent = row

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

                if not s.installed then
                    btn.Text = "Install (1 canister)"
                    btn.MouseButton1Click:Connect(function()
                        local ev = Remotes.get("InstallAugmentation") :: RemoteEvent
                        ev:FireServer(augId)
                    end)
                elseif def.active then
                    btn.Text = s.active and "Active (toggle off)" or "Inactive (toggle on)"
                    btn.TextColor3 = s.active and Theme.Good or Theme.Text
                    btn.MouseButton1Click:Connect(function()
                        local ev = Remotes.get("ToggleAugmentation") :: RemoteEvent
                        ev:FireServer(augId)
                    end)
                else
                    btn.Text = "Passive"
                    btn.TextColor3 = Theme.Good
                end
            end
        end
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.U then
            visible = not visible
            sg.Enabled = visible
            if visible then refresh() end
        end
    end)

    local statsEv = Remotes.get("StatsUpdate") :: RemoteEvent
    statsEv.OnClientEvent:Connect(function(payload: any)
        if payload.augs then state.augs = payload.augs end
        if visible then refresh() end
    end)
end

return AugUI
