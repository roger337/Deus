--!strict
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Items = require(Shared.Config.Items)
local Weapons = require(Shared.Config.Weapons)
local WeaponMods = require(Shared.Config.WeaponMods)
local Remotes = require(Shared.Remotes)

local InventoryUI = {}

local player = Players.LocalPlayer
local visible = false
local data = { inventory = {}, equipped = nil }

local function styleButton(b: TextButton)
    b.BackgroundColor3 = Theme.Bg
    b.BorderSizePixel = 0
    b.TextColor3 = Theme.Text
    b.Font = Theme.Font
    b.TextSize = 14
    local s = Instance.new("UIStroke")
    s.Color = Theme.Border
    s.Thickness = 1
    s.Parent = b
end

function InventoryUI.start()
    local pg = player:WaitForChild("PlayerGui")
    local sg = Instance.new("ScreenGui")
    sg.Name = "InventoryUI"
    sg.ResetOnSpawn = false
    sg.Enabled = false
    sg.Parent = pg

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(720, 480)
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
    title.Text = "INVENTORY"
    title.Parent = panel

    local closeHint = Instance.new("TextLabel")
    closeHint.AnchorPoint = Vector2.new(1, 0)
    closeHint.Position = UDim2.new(1, -16, 0, 16)
    closeHint.Size = UDim2.fromOffset(120, 24)
    closeHint.BackgroundTransparency = 1
    closeHint.Font = Theme.Font
    closeHint.TextSize = 14
    closeHint.TextColor3 = Theme.TextDim
    closeHint.Text = "TAB to close"
    closeHint.Parent = panel

    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.fromOffset(16, 50)
    list.Size = UDim2.fromOffset(360, 400)
    list.BackgroundColor3 = Theme.Bg
    list.BorderSizePixel = 0
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ScrollBarThickness = 4
    list.Parent = panel
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 4)
    listLayout.Parent = list

    local detail = Instance.new("Frame")
    detail.Position = UDim2.fromOffset(396, 50)
    detail.Size = UDim2.fromOffset(308, 400)
    detail.BackgroundColor3 = Theme.Bg
    detail.BorderSizePixel = 0
    detail.Parent = panel
    local detailStroke = Instance.new("UIStroke")
    detailStroke.Color = Theme.Border
    detailStroke.Thickness = 1
    detailStroke.Parent = detail

    local detailName = Instance.new("TextLabel")
    detailName.Position = UDim2.fromOffset(12, 12)
    detailName.Size = UDim2.fromOffset(284, 24)
    detailName.BackgroundTransparency = 1
    detailName.Font = Theme.Font
    detailName.TextSize = 18
    detailName.TextColor3 = Theme.Accent
    detailName.TextXAlignment = Enum.TextXAlignment.Left
    detailName.Parent = detail

    local detailDesc = Instance.new("TextLabel")
    detailDesc.Position = UDim2.fromOffset(12, 40)
    detailDesc.Size = UDim2.fromOffset(284, 160)
    detailDesc.BackgroundTransparency = 1
    detailDesc.Font = Theme.Font
    detailDesc.TextSize = 14
    detailDesc.TextColor3 = Theme.Text
    detailDesc.TextXAlignment = Enum.TextXAlignment.Left
    detailDesc.TextYAlignment = Enum.TextYAlignment.Top
    detailDesc.TextWrapped = true
    detailDesc.Parent = detail

    local equipBtn = Instance.new("TextButton")
    equipBtn.Position = UDim2.fromOffset(12, 320)
    equipBtn.Size = UDim2.fromOffset(140, 32)
    equipBtn.Text = "EQUIP"
    styleButton(equipBtn)
    equipBtn.Parent = detail

    local useBtn = Instance.new("TextButton")
    useBtn.Position = UDim2.fromOffset(160, 320)
    useBtn.Size = UDim2.fromOffset(140, 32)
    useBtn.Text = "USE"
    styleButton(useBtn)
    useBtn.Parent = detail

    local dropBtn = Instance.new("TextButton")
    dropBtn.Position = UDim2.fromOffset(12, 358)
    dropBtn.Size = UDim2.fromOffset(288, 32)
    dropBtn.Text = "DROP 1"
    styleButton(dropBtn)
    dropBtn.Parent = detail

    local selected: string? = nil

    -- Mod sub-panel: shown when a weapon is selected. Lists installed mods
    -- and a button to install a compatible mod from inventory.
    local modsPanel = Instance.new("Frame")
    modsPanel.Position = UDim2.fromOffset(12, 220)
    modsPanel.Size = UDim2.fromOffset(284, 90)
    modsPanel.BackgroundTransparency = 1
    modsPanel.Visible = false
    modsPanel.Parent = detail
    local modsLayout = Instance.new("UIListLayout")
    modsLayout.Padding = UDim.new(0, 2)
    modsLayout.Parent = modsPanel

    local installModBtn = Instance.new("TextButton")
    installModBtn.Position = UDim2.fromOffset(160, 358)
    installModBtn.Size = UDim2.fromOffset(140, 32)
    installModBtn.Text = "INSTALL MOD"
    styleButton(installModBtn)
    installModBtn.Visible = false
    installModBtn.Parent = detail

    -- Modal popup for picking a compatible mod from inventory.
    local function openModPicker(weaponId: string)
        local wdef = Weapons[weaponId]
        if not wdef then return end
        local picker = Instance.new("Frame")
        picker.AnchorPoint = Vector2.new(0.5, 0.5)
        picker.Position = UDim2.fromScale(0.5, 0.5)
        picker.Size = UDim2.fromOffset(320, 360)
        picker.BackgroundColor3 = Theme.Panel
        picker.ZIndex = 5
        picker.Parent = sg
        local ps = Instance.new("UIStroke")
        ps.Color = Theme.Border
        ps.Thickness = 1
        ps.Parent = picker
        local title = Instance.new("TextLabel")
        title.Position = UDim2.fromOffset(12, 8)
        title.Size = UDim2.fromOffset(296, 24)
        title.BackgroundTransparency = 1
        title.Font = Theme.Font
        title.TextSize = 16
        title.TextColor3 = Theme.Accent
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "INSTALL MOD: " .. wdef.name
        title.ZIndex = 6
        title.Parent = picker

        local listFrame = Instance.new("ScrollingFrame")
        listFrame.Position = UDim2.fromOffset(12, 36)
        listFrame.Size = UDim2.fromOffset(296, 280)
        listFrame.BackgroundColor3 = Theme.Bg
        listFrame.BorderSizePixel = 0
        listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
        listFrame.CanvasSize = UDim2.new()
        listFrame.ScrollBarThickness = 4
        listFrame.ZIndex = 6
        listFrame.Parent = picker
        local lay = Instance.new("UIListLayout")
        lay.Padding = UDim.new(0, 2)
        lay.Parent = listFrame

        -- Find compatible mods present in inventory.
        local found = false
        for _, stack in ipairs(data.inventory) do
            if string.sub(stack.id, 1, 9) ~= "WeaponMod" then continue end
            local modId = string.sub(stack.id, 10)
            if not WeaponMods.compatible(modId, wdef.slot) then continue end
            local mod = WeaponMods.Mods[modId]
            if not mod then continue end
            found = true
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, -4, 0, 50)
            b.TextXAlignment = Enum.TextXAlignment.Left
            b.Text = string.format("  %s  (x%d)\n  %s", mod.name, stack.count, mod.description)
            b.TextWrapped = true
            b.ZIndex = 6
            styleButton(b)
            b.Parent = listFrame
            b.MouseButton1Click:Connect(function()
                local ev = Remotes.get("InstallWeaponMod") :: RemoteEvent
                ev:FireServer(weaponId, stack.id)
                picker:Destroy()
            end)
        end
        if not found then
            local empty = Instance.new("TextLabel")
            empty.Size = UDim2.fromOffset(296, 80)
            empty.BackgroundTransparency = 1
            empty.Font = Theme.Font
            empty.TextSize = 14
            empty.TextColor3 = Theme.TextDim
            empty.TextWrapped = true
            empty.ZIndex = 6
            empty.Text = "No compatible mods in inventory. Look for pickups in the field — Versalife, Area 51, and the warehouses tend to have them."
            empty.Parent = listFrame
        end

        local closeBtn = Instance.new("TextButton")
        closeBtn.Position = UDim2.fromOffset(12, 322)
        closeBtn.Size = UDim2.fromOffset(296, 30)
        closeBtn.Text = "Close"
        closeBtn.ZIndex = 6
        styleButton(closeBtn)
        closeBtn.Parent = picker
        closeBtn.MouseButton1Click:Connect(function() picker:Destroy() end)
    end
    installModBtn.MouseButton1Click:Connect(function()
        if selected and Weapons[selected] then
            openModPicker(selected)
        end
    end)

    local function findStack(itemId: string)
        for _, s in ipairs(data.inventory) do
            if s.id == itemId then return s end
        end
        return nil
    end

    local function refreshModsPanel()
        for _, c in ipairs(modsPanel:GetChildren()) do
            if c:IsA("TextLabel") then c:Destroy() end
        end
        if not selected then
            modsPanel.Visible = false
            installModBtn.Visible = false
            return
        end
        local wdef = Weapons[selected]
        if not wdef then
            modsPanel.Visible = false
            installModBtn.Visible = false
            return
        end
        modsPanel.Visible = true
        installModBtn.Visible = true
        local title = Instance.new("TextLabel")
        title.Size = UDim2.fromOffset(284, 18)
        title.BackgroundTransparency = 1
        title.Font = Theme.Font
        title.TextSize = 13
        title.TextColor3 = Theme.Accent
        title.TextXAlignment = Enum.TextXAlignment.Left
        title.Text = "INSTALLED MODS"
        title.Parent = modsPanel
        local stack = findStack(selected)
        local mods = (stack and stack.mods) or {}
        if #mods == 0 then
            local none = Instance.new("TextLabel")
            none.Size = UDim2.fromOffset(284, 18)
            none.BackgroundTransparency = 1
            none.Font = Theme.Font
            none.TextSize = 12
            none.TextColor3 = Theme.TextDim
            none.TextXAlignment = Enum.TextXAlignment.Left
            none.Text = "  (none)"
            none.Parent = modsPanel
        else
            for _, modId in ipairs(mods) do
                local mod = WeaponMods.Mods[modId]
                if not mod then continue end
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.fromOffset(284, 16)
                lbl.BackgroundTransparency = 1
                lbl.Font = Theme.Font
                lbl.TextSize = 12
                lbl.TextColor3 = Theme.Good
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.Text = "  + " .. mod.name
                lbl.Parent = modsPanel
            end
        end
    end

    local function refreshDetail()
        if not selected then
            detailName.Text = ""
            detailDesc.Text = "Select an item."
            modsPanel.Visible = false
            installModBtn.Visible = false
            return
        end
        local def = Items[selected]
        local wdef = Weapons[selected]
        if def then
            detailName.Text = def.name
            detailDesc.Text = def.description
            equipBtn.Visible = (def.category == "Weapon") or wdef ~= nil
            useBtn.Visible = def.useEffect ~= nil
        elseif wdef then
            detailName.Text = wdef.name
            detailDesc.Text = wdef.description
            equipBtn.Visible = true
            useBtn.Visible = false
        else
            detailName.Text = selected
            detailDesc.Text = ""
        end
        refreshModsPanel()
    end

    local function refresh()
        for _, child in ipairs(list:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, stack in ipairs(data.inventory) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -8, 0, 28)
            local def = Items[stack.id]
            local wdef = Weapons[stack.id]
            local name = (def and def.name) or (wdef and wdef.name) or stack.id
            local stackText = stack.count > 1 and string.format(" x%d", stack.count) or ""
            local equippedTag = (data.equipped == stack.id) and "  [EQUIPPED]" or ""
            btn.Text = "  " .. name .. stackText .. equippedTag
            btn.TextXAlignment = Enum.TextXAlignment.Left
            styleButton(btn)
            btn.Parent = list
            btn.MouseButton1Click:Connect(function()
                selected = stack.id
                refreshDetail()
            end)
        end
        refreshDetail()
    end

    equipBtn.MouseButton1Click:Connect(function()
        if not selected then return end
        local ev = Remotes.get("EquipItem") :: RemoteEvent
        ev:FireServer(selected)
    end)
    useBtn.MouseButton1Click:Connect(function()
        if not selected then return end
        local ev = Remotes.get("UseItem") :: RemoteEvent
        ev:FireServer(selected)
    end)
    dropBtn.MouseButton1Click:Connect(function()
        if not selected then return end
        local ev = Remotes.get("DropItem") :: RemoteEvent
        ev:FireServer(selected)
    end)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Tab then
            visible = not visible
            sg.Enabled = visible
        elseif input.KeyCode == Enum.KeyCode.Escape and visible then
            visible = false
            sg.Enabled = false
        end
    end)

    local invEv = Remotes.get("InventoryUpdate") :: RemoteEvent
    invEv.OnClientEvent:Connect(function(payload: any)
        if payload.inventory then data.inventory = payload.inventory end
        if payload.equipped ~= nil then data.equipped = payload.equipped end
        refresh()
    end)
end

return InventoryUI
