--!strict
-- Vendor shop UI. Listens for OpenVendor / CloseVendor remotes.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Remotes = require(Shared.Remotes)

local VendorUI = {}

local player = Players.LocalPlayer
local sg: ScreenGui? = nil
local activeVendorId: string? = nil

local function destroyUI()
    if sg then sg:Destroy() end
    sg = nil
    activeVendorId = nil
end

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

local function buildUI(payload: any)
    destroyUI()
    activeVendorId = payload.vendorId
    local pg = player:WaitForChild("PlayerGui")
    sg = Instance.new("ScreenGui")
    sg.Name = "VendorUI"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 30
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
    title.Size = UDim2.fromOffset(528, 24)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 18
    title.TextColor3 = Theme.Accent
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = string.format("VENDOR: %s [%s]", payload.name or "?", payload.faction or "?")
    title.Parent = panel

    local credits = Instance.new("TextLabel")
    credits.AnchorPoint = Vector2.new(1, 0)
    credits.Position = UDim2.new(1, -16, 0, 12)
    credits.Size = UDim2.fromOffset(160, 24)
    credits.BackgroundTransparency = 1
    credits.Font = Theme.Font
    credits.TextSize = 16
    credits.TextColor3 = Theme.Good
    credits.TextXAlignment = Enum.TextXAlignment.Right
    credits.Text = string.format("Credits: %d", payload.credits or 0)
    credits.Parent = panel

    local greeting = Instance.new("TextLabel")
    greeting.Position = UDim2.fromOffset(16, 40)
    greeting.Size = UDim2.fromOffset(608, 30)
    greeting.BackgroundTransparency = 1
    greeting.Font = Theme.Font
    greeting.TextSize = 13
    greeting.TextColor3 = Theme.TextDim
    greeting.TextXAlignment = Enum.TextXAlignment.Left
    greeting.TextWrapped = true
    greeting.Text = "\"" .. (payload.greeting or "") .. "\""
    greeting.Parent = panel

    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.fromOffset(16, 80)
    list.Size = UDim2.fromOffset(608, 380)
    list.BackgroundColor3 = Theme.Bg
    list.BorderSizePixel = 0
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.ScrollBarThickness = 4
    list.Parent = panel
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = list

    for _, entry in ipairs(payload.stock or {}) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 50)
        row.BackgroundColor3 = Theme.Bg
        row.BorderSizePixel = 0
        row.Parent = list
        local rs = Instance.new("UIStroke")
        rs.Color = Theme.Border
        rs.Thickness = 1
        rs.Parent = row

        local name = Instance.new("TextLabel")
        name.Position = UDim2.fromOffset(12, 4)
        name.Size = UDim2.fromOffset(380, 20)
        name.BackgroundTransparency = 1
        name.Font = Theme.Font
        name.TextSize = 14
        name.TextColor3 = Theme.Text
        name.TextXAlignment = Enum.TextXAlignment.Left
        local qty = (entry.quantity or 1) > 1 and string.format(" x%d", entry.quantity) or ""
        name.Text = entry.name .. qty
        name.Parent = row

        local desc = Instance.new("TextLabel")
        desc.Position = UDim2.fromOffset(12, 24)
        desc.Size = UDim2.fromOffset(420, 22)
        desc.BackgroundTransparency = 1
        desc.Font = Theme.Font
        desc.TextSize = 12
        desc.TextColor3 = Theme.TextDim
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.TextTruncate = Enum.TextTruncate.AtEnd
        desc.Text = entry.description or ""
        desc.Parent = row

        local price = Instance.new("TextLabel")
        price.AnchorPoint = Vector2.new(1, 0.5)
        price.Position = UDim2.new(1, -100, 0.5, 0)
        price.Size = UDim2.fromOffset(80, 24)
        price.BackgroundTransparency = 1
        price.Font = Theme.Font
        price.TextSize = 14
        price.TextColor3 = Theme.Accent
        price.TextXAlignment = Enum.TextXAlignment.Right
        price.Text = string.format("%d cr.", entry.price)
        price.Parent = row

        local buyBtn = Instance.new("TextButton")
        buyBtn.AnchorPoint = Vector2.new(1, 0.5)
        buyBtn.Position = UDim2.new(1, -10, 0.5, 0)
        buyBtn.Size = UDim2.fromOffset(80, 30)
        buyBtn.Text = "BUY"
        styleButton(buyBtn)
        buyBtn.Parent = row
        buyBtn.MouseButton1Click:Connect(function()
            local ev = Remotes.get("BuyItem") :: RemoteEvent
            ev:FireServer(payload.vendorId, entry.index)
        end)
    end

    local closeBtn = Instance.new("TextButton")
    closeBtn.AnchorPoint = Vector2.new(0.5, 1)
    closeBtn.Position = UDim2.new(0.5, 0, 1, -16)
    closeBtn.Size = UDim2.fromOffset(180, 30)
    closeBtn.Text = "Close (Esc)"
    styleButton(closeBtn)
    closeBtn.Parent = panel
    closeBtn.MouseButton1Click:Connect(function()
        local ev = Remotes.get("CloseVendor") :: RemoteEvent
        ev:FireServer()
    end)
end

function VendorUI.start()
    local openEv = Remotes.get("OpenVendor") :: RemoteEvent
    openEv.OnClientEvent:Connect(buildUI)
    local closeEv = Remotes.get("CloseVendor") :: RemoteEvent
    closeEv.OnClientEvent:Connect(destroyUI)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.Escape and activeVendorId then
            local ev = Remotes.get("CloseVendor") :: RemoteEvent
            ev:FireServer()
        end
    end)
end

return VendorUI
