--!strict
-- Owner-only console: lists pending access requests and lets the owner
-- grant or deny each. Server enforces admin status on the remote handlers
-- (clients calling these without being on AccessConfig.AdminUserIds are
-- silently dropped).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Theme = require(script.Parent.Theme)
local Remotes = require(Shared.Remotes)

local AdminConsoleUI = {}

local player = Players.LocalPlayer
local sg: ScreenGui? = nil

local function destroy()
    if sg then sg:Destroy() end
    sg = nil
end

local function rebuildList(listFrame: ScrollingFrame)
    for _, child in ipairs(listFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local listFn = Remotes.get("AdminListPending") :: RemoteFunction
    local ok, pending = pcall(function() return listFn:InvokeServer() end)
    if not ok or typeof(pending) ~= "table" then pending = {} end

    if #pending == 0 then
        local empty = Instance.new("Frame")
        empty.Size = UDim2.new(1, -8, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Parent = listFrame
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.fromScale(1, 1)
        lbl.BackgroundTransparency = 1
        lbl.Font = Theme.Font
        lbl.TextSize = 14
        lbl.TextColor3 = Theme.TextDim
        lbl.Text = "  No pending requests."
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = empty
        return
    end

    for _, entry in ipairs(pending) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -8, 0, 56)
        row.BackgroundColor3 = Theme.Bg
        row.BorderSizePixel = 0
        row.Parent = listFrame
        local rs = Instance.new("UIStroke")
        rs.Color = Theme.Border
        rs.Thickness = 1
        rs.Parent = row

        local info = Instance.new("TextLabel")
        info.Position = UDim2.fromOffset(12, 6)
        info.Size = UDim2.fromOffset(420, 44)
        info.BackgroundTransparency = 1
        info.Font = Theme.Font
        info.TextSize = 14
        info.TextColor3 = Theme.Text
        info.TextXAlignment = Enum.TextXAlignment.Left
        info.TextYAlignment = Enum.TextYAlignment.Top
        info.TextWrapped = true
        info.Text = string.format("%s  (userId %d)\nTeam: %s",
            entry.name, entry.userId, entry.team)
        info.Parent = row

        local function btn(text: string, color: Color3, x: number)
            local b = Instance.new("TextButton")
            b.AnchorPoint = Vector2.new(1, 0.5)
            b.Position = UDim2.new(1, x, 0.5, 0)
            b.Size = UDim2.fromOffset(80, 32)
            b.BackgroundColor3 = color
            b.BorderSizePixel = 0
            b.Font = Theme.Font
            b.TextSize = 13
            b.TextColor3 = Color3.fromRGB(255, 255, 255)
            b.Text = text
            b.Parent = row
            return b
        end

        local approve = btn("GRANT", Color3.fromRGB(40, 100, 40), -8)
        local deny    = btn("DENY",  Color3.fromRGB(120, 40, 40), -96)

        approve.MouseButton1Click:Connect(function()
            local ev = Remotes.get("AdminGrantAccess") :: RemoteEvent
            ev:FireServer(entry.userId)
            row:Destroy()
        end)
        deny.MouseButton1Click:Connect(function()
            local ev = Remotes.get("AdminRevokeAccess") :: RemoteEvent
            ev:FireServer(entry.userId)
            row:Destroy()
        end)
    end
end

local function show()
    destroy()
    local pg = player:WaitForChild("PlayerGui")
    sg = Instance.new("ScreenGui")
    sg.Name = "AdminConsoleUI"
    sg.ResetOnSpawn = false
    sg.DisplayOrder = 70
    sg.Parent = pg

    local panel = Instance.new("Frame")
    panel.AnchorPoint = Vector2.new(0.5, 0.5)
    panel.Position = UDim2.fromScale(0.5, 0.5)
    panel.Size = UDim2.fromOffset(640, 480)
    panel.BackgroundColor3 = Theme.Panel
    panel.BorderSizePixel = 0
    panel.Parent = sg
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 60, 60)
    stroke.Thickness = 1
    stroke.Parent = panel

    local title = Instance.new("TextLabel")
    title.Position = UDim2.fromOffset(16, 12)
    title.Size = UDim2.fromOffset(508, 28)
    title.BackgroundTransparency = 1
    title.Font = Theme.Font
    title.TextSize = 20
    title.TextColor3 = Color3.fromRGB(255, 80, 80)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Text = "OWNER CONSOLE  —  PENDING ACCESS REQUESTS"
    title.Parent = panel

    local hint = Instance.new("TextLabel")
    hint.Position = UDim2.fromOffset(16, 44)
    hint.Size = UDim2.fromOffset(608, 18)
    hint.BackgroundTransparency = 1
    hint.Font = Theme.Font
    hint.TextSize = 12
    hint.TextColor3 = Theme.TextDim
    hint.TextXAlignment = Enum.TextXAlignment.Left
    hint.Text = "Set AccessConfig.AdminUserIds to your Roblox userId before publishing."
    hint.Parent = panel

    local list = Instance.new("ScrollingFrame")
    list.Position = UDim2.fromOffset(16, 70)
    list.Size = UDim2.fromOffset(608, 360)
    list.BackgroundColor3 = Theme.Bg
    list.BorderSizePixel = 0
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.CanvasSize = UDim2.new()
    list.ScrollBarThickness = 4
    list.Parent = panel
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = list

    rebuildList(list)

    local refresh = Instance.new("TextButton")
    refresh.AnchorPoint = Vector2.new(0, 1)
    refresh.Position = UDim2.fromOffset(16, 464)
    refresh.Size = UDim2.fromOffset(160, 36)
    refresh.BackgroundColor3 = Theme.Bg
    refresh.BorderSizePixel = 0
    refresh.Font = Theme.Font
    refresh.TextSize = 14
    refresh.TextColor3 = Theme.Text
    refresh.Text = "REFRESH"
    local rs2 = Instance.new("UIStroke")
    rs2.Color = Theme.Border
    rs2.Thickness = 1
    rs2.Parent = refresh
    refresh.Parent = panel
    refresh.MouseButton1Click:Connect(function() rebuildList(list) end)

    local close = Instance.new("TextButton")
    close.AnchorPoint = Vector2.new(1, 1)
    close.Position = UDim2.new(1, -16, 1, -16)
    close.Size = UDim2.fromOffset(160, 36)
    close.BackgroundColor3 = Theme.Bg
    close.BorderSizePixel = 0
    close.Font = Theme.Font
    close.TextSize = 14
    close.TextColor3 = Theme.Text
    close.Text = "CLOSE"
    local cs = Instance.new("UIStroke")
    cs.Color = Theme.Border
    cs.Thickness = 1
    cs.Parent = close
    close.Parent = panel
    close.MouseButton1Click:Connect(destroy)

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not sg then return end
        if input.KeyCode == Enum.KeyCode.Escape then destroy() end
    end)
end

function AdminConsoleUI.start()
    local ev = Remotes.get("ShowAdminConsole") :: RemoteEvent
    ev.OnClientEvent:Connect(show)
end

return AdminConsoleUI
