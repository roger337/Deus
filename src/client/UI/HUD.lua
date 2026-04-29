--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Remotes = require(Shared.Remotes)
local Items = require(Shared.Config.Items)
local Objectives = require(Shared.Config.Objectives)

local HUD = {}

local player = Players.LocalPlayer

local function bar(parent: Instance, name: string, color: Color3): (Frame, Frame, TextLabel)
    local f = Instance.new("Frame")
    f.Name = name
    f.Size = UDim2.fromOffset(220, 18)
    f.BackgroundColor3 = Theme.Bg
    f.BorderSizePixel = 0
    f.Parent = parent
    local fg = Instance.new("Frame")
    fg.Name = "Fill"
    fg.Size = UDim2.fromScale(1, 1)
    fg.BackgroundColor3 = color
    fg.BorderSizePixel = 0
    fg.Parent = f
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.fromScale(1, 1)
    lbl.BackgroundTransparency = 1
    lbl.Font = Theme.Font
    lbl.TextSize = 14
    lbl.TextColor3 = Theme.Text
    lbl.Text = ""
    lbl.Parent = f
    return f, fg, lbl
end

function HUD.start()
    local pg = player:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "HUD"
    sg.ResetOnSpawn = false
    sg.Parent = pg

    -- Bottom-left stats panel
    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0, 1)
    panel.Position = UDim2.new(0, 16, 1, -16)
    panel.Size = UDim2.fromOffset(240, 110)
    panel.BackgroundColor3 = Theme.Panel
    panel.BackgroundTransparency = 0.2
    panel.BorderSizePixel = 0
    panel.Parent = sg

    local stroke = Instance.new("UIStroke")
    stroke.Color = Theme.Border
    stroke.Thickness = 1
    stroke.Parent = panel

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = panel
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingTop = UDim.new(0, 8)
    pad.Parent = panel

    local _, hpFg, hpLbl = bar(panel, "Health", Theme.Bad)
    local _, enFg, enLbl = bar(panel, "Energy", Color3.fromRGB(80, 200, 255))
    local skillLbl = Instance.new("TextLabel")
    skillLbl.Size = UDim2.fromOffset(220, 18)
    skillLbl.BackgroundTransparency = 1
    skillLbl.TextColor3 = Theme.Accent
    skillLbl.Font = Theme.Font
    skillLbl.TextSize = 14
    skillLbl.TextXAlignment = Enum.TextXAlignment.Left
    skillLbl.Parent = panel

    -- Bottom-right: equipped weapon + ammo
    local wPanel = Instance.new("Frame")
    wPanel.AnchorPoint = Vector2.new(1, 1)
    wPanel.Position = UDim2.new(1, -16, 1, -16)
    wPanel.Size = UDim2.fromOffset(240, 60)
    wPanel.BackgroundColor3 = Theme.Panel
    wPanel.BackgroundTransparency = 0.2
    wPanel.BorderSizePixel = 0
    wPanel.Parent = sg
    local wStroke = stroke:Clone()
    wStroke.Parent = wPanel
    local wLbl = Instance.new("TextLabel")
    wLbl.Size = UDim2.fromScale(1, 1)
    wLbl.BackgroundTransparency = 1
    wLbl.Font = Theme.Font
    wLbl.TextColor3 = Theme.Text
    wLbl.TextSize = 18
    wLbl.Parent = wPanel

    -- Top-right: objectives
    local objPanel = Instance.new("Frame")
    objPanel.AnchorPoint = Vector2.new(1, 0)
    objPanel.Position = UDim2.new(1, -16, 0, 16)
    objPanel.Size = UDim2.fromOffset(280, 200)
    objPanel.BackgroundColor3 = Theme.Panel
    objPanel.BackgroundTransparency = 0.2
    objPanel.BorderSizePixel = 0
    objPanel.Parent = sg
    local objStroke = stroke:Clone()
    objStroke.Parent = objPanel
    local objList = Instance.new("UIListLayout")
    objList.Padding = UDim.new(0, 4)
    objList.Parent = objPanel
    local objPad = Instance.new("UIPadding")
    objPad.PaddingLeft = UDim.new(0, 8)
    objPad.PaddingTop = UDim.new(0, 8)
    objPad.Parent = objPanel
    local objTitle = Instance.new("TextLabel")
    objTitle.Size = UDim2.fromOffset(260, 20)
    objTitle.BackgroundTransparency = 1
    objTitle.Font = Theme.Font
    objTitle.TextSize = 16
    objTitle.TextColor3 = Theme.Accent
    objTitle.TextXAlignment = Enum.TextXAlignment.Left
    objTitle.Text = "OBJECTIVES"
    objTitle.Parent = objPanel

    -- Top-center: notifications
    local notify = Instance.new("TextLabel")
    notify.AnchorPoint = Vector2.new(0.5, 0)
    notify.Position = UDim2.new(0.5, 0, 0, 30)
    notify.Size = UDim2.fromOffset(500, 32)
    notify.BackgroundColor3 = Theme.Bg
    notify.BackgroundTransparency = 0.2
    notify.TextColor3 = Theme.Accent
    notify.Font = Theme.Font
    notify.TextSize = 18
    notify.Text = ""
    notify.Visible = false
    notify.Parent = sg

    -- Crosshair
    local cross = Instance.new("Frame")
    cross.AnchorPoint = Vector2.new(0.5, 0.5)
    cross.Position = UDim2.fromScale(0.5, 0.5)
    cross.Size = UDim2.fromOffset(8, 8)
    cross.BackgroundColor3 = Color3.fromRGB(180, 220, 255)
    cross.BorderSizePixel = 0
    cross.Parent = sg

    local function ammoString(equipped: string?, inventory)
        if not equipped then return "" end
        local Weapons = require(Shared.Config.Weapons)
        local def = Weapons[equipped]
        if not def or not def.ammoType then return "" end
        local ammoId = "Ammo" .. def.ammoType
        local count = 0
        for _, st in ipairs(inventory) do
            if st.id == ammoId then count = st.count end
        end
        return string.format("  [%s rds]", count)
    end

    local lastInventory = {}
    local lastEquipped = nil

    local function updateAmmo()
        if lastEquipped then
            local Weapons = require(Shared.Config.Weapons)
            local def = Weapons[lastEquipped]
            wLbl.Text = (def and def.name or lastEquipped) .. ammoString(lastEquipped, lastInventory)
        else
            wLbl.Text = "Unarmed"
        end
    end

    local statsEv = Remotes.get("StatsUpdate") :: RemoteEvent
    statsEv.OnClientEvent:Connect(function(payload: any)
        if payload.health then
            hpFg.Size = UDim2.fromScale(math.clamp(payload.health / payload.maxHealth, 0, 1), 1)
            hpLbl.Text = string.format("HEALTH  %d / %d", payload.health, payload.maxHealth)
        end
        if payload.energy then
            enFg.Size = UDim2.fromScale(math.clamp(payload.energy / payload.maxEnergy, 0, 1), 1)
            enLbl.Text = string.format("ENERGY  %d / %d", payload.energy, payload.maxEnergy)
        end
        if payload.skillPoints then
            skillLbl.Text = string.format("SKILL POINTS  %d", payload.skillPoints)
        end
    end)

    local invEv = Remotes.get("InventoryUpdate") :: RemoteEvent
    invEv.OnClientEvent:Connect(function(payload: any)
        lastInventory = payload.inventory or {}
        lastEquipped = payload.equipped
        updateAmmo()
    end)

    local objEv = Remotes.get("ObjectiveUpdate") :: RemoteEvent
    objEv.OnClientEvent:Connect(function(state: any)
        for _, child in ipairs(objPanel:GetChildren()) do
            if child:IsA("TextLabel") and child ~= objTitle then child:Destroy() end
        end
        for id, info in pairs(state) do
            local def = Objectives[id]
            if not def then continue end
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.fromOffset(260, 36)
            lbl.BackgroundTransparency = 1
            lbl.Font = Theme.Font
            lbl.TextSize = 14
            lbl.TextColor3 = info.completed and Theme.Good or Theme.Text
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.TextYAlignment = Enum.TextYAlignment.Top
            lbl.TextWrapped = true
            local check = info.completed and "[X] " or "[ ] "
            lbl.Text = string.format("%s%s  (%d/%d)", check, def.title, info.progress, def.target)
            lbl.Parent = objPanel
        end
    end)

    local notifyEv = Remotes.get("Notify") :: RemoteEvent
    notifyEv.OnClientEvent:Connect(function(text: string)
        notify.Text = text
        notify.Visible = true
        task.delay(3, function()
            if notify.Text == text then
                notify.Visible = false
            end
        end)
    end)

    -- Damage flash
    local damageEv = Remotes.get("DamageFeedback") :: RemoteEvent
    local flash = Instance.new("Frame")
    flash.Size = UDim2.fromScale(1, 1)
    flash.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
    flash.BackgroundTransparency = 1
    flash.BorderSizePixel = 0
    flash.Parent = sg
    flash.ZIndex = 10
    damageEv.OnClientEvent:Connect(function()
        flash.BackgroundTransparency = 0.6
        task.delay(0.05, function() flash.BackgroundTransparency = 0.8 end)
        task.delay(0.15, function() flash.BackgroundTransparency = 1 end)
    end)

    -- Initial pull from server
    local getData = Remotes.get("GetPlayerData") :: RemoteFunction
    local ok, data = pcall(function() return getData:InvokeServer() end)
    if ok and data then
        hpFg.Size = UDim2.fromScale(math.clamp(data.health / data.maxHealth, 0, 1), 1)
        hpLbl.Text = string.format("HEALTH  %d / %d", data.health, data.maxHealth)
        enFg.Size = UDim2.fromScale(math.clamp(data.energy / data.maxEnergy, 0, 1), 1)
        enLbl.Text = string.format("ENERGY  %d / %d", data.energy, data.maxEnergy)
        skillLbl.Text = string.format("SKILL POINTS  %d", data.skillPoints)
        lastInventory = data.inventory or {}
        lastEquipped = data.equipped
        updateAmmo()
    end
end

return HUD
