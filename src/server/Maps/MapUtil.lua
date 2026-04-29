--!strict
-- Shared helpers used by map modules to build geometry, NPCs, doors, etc.

local Workspace = game:GetService("Workspace")

local MapUtil = {}

function MapUtil.part(parent: Instance, props: { [string]: any }): Part
    local p = Instance.new("Part")
    p.Anchored = true
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    for k, v in pairs(props) do
        (p :: any)[k] = v
    end
    p.Parent = parent
    return p
end

function MapUtil.box(parent: Instance, pos: Vector3, size: Vector3, color: Color3, material: Enum.Material?): Part
    return MapUtil.part(parent, {
        Position = pos, Size = size, Color = color,
        Material = material or Enum.Material.SmoothPlastic,
    })
end

function MapUtil.wall(parent: Instance, pos: Vector3, size: Vector3): Part
    return MapUtil.box(parent, pos, size, Color3.fromRGB(80, 80, 90), Enum.Material.Concrete)
end

function MapUtil.floor(parent: Instance, pos: Vector3, size: Vector3, color: Color3?): Part
    return MapUtil.box(parent, pos, size, color or Color3.fromRGB(60, 60, 65), Enum.Material.Metal)
end

function MapUtil.spawn(parent: Instance, name: string, pos: Vector3, color: Color3?): SpawnLocation
    local s = Instance.new("SpawnLocation")
    s.Name = name
    s.Anchored = true
    s.CanCollide = false
    s.Size = Vector3.new(6, 1, 6)
    s.Position = pos
    s.Color = color or Color3.fromRGB(0, 100, 200)
    s.Material = Enum.Material.Neon
    s.Neutral = true
    s.Parent = parent
    return s
end

function MapUtil.npc(parent: Instance, name: string, pos: Vector3, treeId: string, bodyColor: Color3?): Model
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("InteractionType", "NPC")
    model:SetAttribute("DialogTree", treeId)

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Anchored = true
    hrp.Size = Vector3.new(2, 4, 1)
    hrp.Position = pos
    hrp.Color = bodyColor or Color3.fromRGB(40, 50, 90)
    hrp.Material = Enum.Material.SmoothPlastic
    hrp:SetAttribute("InteractionType", "NPC")
    hrp:SetAttribute("DialogTree", treeId)
    hrp.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Anchored = true
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(1.4, 1.4, 1.4)
    head.Position = pos + Vector3.new(0, 2.5, 0)
    head.Color = Color3.fromRGB(200, 170, 150)
    head.Parent = model

    local bb = Instance.new("BillboardGui")
    bb.Adornee = head
    bb.Size = UDim2.new(0, 140, 0, 24)
    bb.StudsOffset = Vector3.new(0, 1.6, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.TextColor3 = Color3.fromRGB(180, 220, 255)
    lbl.Font = Enum.Font.Code
    lbl.TextScaled = true
    lbl.Text = name
    lbl.Parent = bb

    model.PrimaryPart = hrp
    model.Parent = parent
    return model
end

function MapUtil.pickup(parent: Instance, itemId: string, count: number, pos: Vector3, color: Color3): Part
    local p = MapUtil.part(parent, {
        Name = itemId .. "_Pickup",
        Size = Vector3.new(1.5, 1.5, 1.5),
        Position = pos,
        Color = color,
        Material = Enum.Material.Neon,
    })
    p:SetAttribute("InteractionType", "Pickup")
    p:SetAttribute("ItemId", itemId)
    p:SetAttribute("ItemCount", count)
    return p
end

function MapUtil.door(parent: Instance, pos: Vector3, locked: boolean, difficulty: number?): Model
    local door = Instance.new("Model")
    door.Name = "Door"
    local dp = Instance.new("Part")
    dp.Anchored = true
    dp.Size = Vector3.new(6, 10, 1)
    dp.CFrame = CFrame.new(pos)
    dp.Color = Color3.fromRGB(90, 50, 30)
    dp.Material = Enum.Material.Wood
    dp.Parent = door
    door.PrimaryPart = dp
    door:SetAttribute("InteractionType", "Door")
    door:SetAttribute("Locked", locked)
    door:SetAttribute("LockDifficulty", difficulty or 1)
    dp:SetAttribute("InteractionType", "Door")
    dp:SetAttribute("Locked", locked)
    dp:SetAttribute("LockDifficulty", difficulty or 1)
    door.Parent = parent
    return door
end

-- Vendor NPC: same shape as a regular NPC but tagged as a vendor with a
-- VendorId attribute. Bright tag color so players can spot the merchant.
function MapUtil.vendor(parent: Instance, name: string, pos: Vector3, vendorId: string, bodyColor: Color3?): Model
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("InteractionType", "Vendor")
    model:SetAttribute("VendorId", vendorId)

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Anchored = true
    hrp.Size = Vector3.new(2, 4, 1)
    hrp.Position = pos
    hrp.Color = bodyColor or Color3.fromRGB(80, 60, 40)
    hrp.Material = Enum.Material.SmoothPlastic
    hrp:SetAttribute("InteractionType", "Vendor")
    hrp:SetAttribute("VendorId", vendorId)
    hrp.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Anchored = true
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(1.4, 1.4, 1.4)
    head.Position = pos + Vector3.new(0, 2.5, 0)
    head.Color = Color3.fromRGB(220, 180, 140)
    head.Parent = model

    local bb = Instance.new("BillboardGui")
    bb.Adornee = head
    bb.Size = UDim2.new(0, 160, 0, 22)
    bb.StudsOffset = Vector3.new(0, 1.6, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.TextColor3 = Color3.fromRGB(255, 220, 120)
    lbl.Font = Enum.Font.Code
    lbl.TextScaled = true
    lbl.Text = name .. "  [VENDOR]"
    lbl.Parent = bb

    model.PrimaryPart = hrp
    model.Parent = parent
    return model
end

function MapUtil.terminal(parent: Instance, pos: Vector3, difficulty: number, objectiveId: string?): Part
    local t = MapUtil.part(parent, {
        Name = "HackTerminal",
        Size = Vector3.new(3, 4, 1),
        Position = pos,
        Color = Color3.fromRGB(30, 80, 30),
        Material = Enum.Material.Neon,
    })
    t:SetAttribute("InteractionType", "Hack")
    t:SetAttribute("HackDifficulty", difficulty)
    if objectiveId then
        t:SetAttribute("ObjectiveId", objectiveId)
    end
    return t
end

function MapUtil.transition(parent: Instance, name: string, pos: Vector3, size: Vector3, targetMap: string): Part
    local p = MapUtil.part(parent, {
        Name = name,
        Size = size,
        Position = pos,
        Color = Color3.fromRGB(0, 200, 255),
        Material = Enum.Material.ForceField,
        Transparency = 0.5,
        CanCollide = false,
    })
    p:SetAttribute("InteractionType", "Transition")
    p:SetAttribute("TargetMap", targetMap)
    return p
end

-- Civilian: a non-hostile humanoid the player CAN kill but shouldn't.
-- Faction = "Civilian" so CombatService can track civilian casualties.
function MapUtil.civilian(parent: Instance, name: string, pos: Vector3, treeId: string?): Model
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("Faction", "Civilian")
    if treeId then
        model:SetAttribute("InteractionType", "NPC")
        model:SetAttribute("DialogTree", treeId)
    end

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 4, 1)
    hrp.Position = pos
    hrp.Color = Color3.fromRGB(140, 110, 90)
    hrp.Material = Enum.Material.SmoothPlastic
    hrp.Parent = model
    if treeId then
        hrp:SetAttribute("InteractionType", "NPC")
        hrp:SetAttribute("DialogTree", treeId)
    end

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(1.4, 1.4, 1.4)
    head.Position = pos + Vector3.new(0, 2.5, 0)
    head.Color = Color3.fromRGB(220, 180, 160)
    head.Parent = model

    local hum = Instance.new("Humanoid")
    hum.MaxHealth = 60
    hum.Health = 60
    hum.WalkSpeed = 0
    hum.Parent = model

    local bb = Instance.new("BillboardGui")
    bb.Adornee = head
    bb.Size = UDim2.new(0, 120, 0, 22)
    bb.StudsOffset = Vector3.new(0, 1.6, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.TextColor3 = Color3.fromRGB(220, 220, 160)
    lbl.Font = Enum.Font.Code
    lbl.TextScaled = true
    lbl.Text = name .. "  [civilian]"
    lbl.Parent = bb

    model.PrimaryPart = hrp
    model.Parent = parent
    return model
end

function MapUtil.label(parent: Instance, name: string, pos: Vector3, color: Color3?)
    local p = MapUtil.part(parent, {
        Name = "Label_" .. name,
        Size = Vector3.new(0.1, 0.1, 0.1),
        Position = pos,
        Transparency = 1,
        CanCollide = false,
    })
    local bb = Instance.new("BillboardGui")
    bb.Adornee = p
    bb.Size = UDim2.new(0, 300, 0, 60)
    bb.AlwaysOnTop = true
    bb.Parent = p
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.TextColor3 = color or Color3.fromRGB(220, 220, 255)
    lbl.Font = Enum.Font.Code
    lbl.TextScaled = true
    lbl.TextStrokeTransparency = 0
    lbl.Text = name
    lbl.Parent = bb
end

return MapUtil
