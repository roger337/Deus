--!strict
-- Hub level: UNATCO Headquarters (basement of the UN building, Battery Park).
-- Briefings, supply officer, MedBot for installing augs, and travel to other missions.

local MapUtil = require(script.Parent.MapUtil)

local UnatcoHQ = {}

UnatcoHQ.id = "UNATCO_HQ"
UnatcoHQ.displayName = "UNATCO Headquarters"
UnatcoHQ.spawnPoint = Vector3.new(0, 4, 0)

function UnatcoHQ.build(folder: Folder)
    -- Lobby floor
    MapUtil.floor(folder, Vector3.new(0, 1, 0), Vector3.new(80, 1, 80),
        Color3.fromRGB(50, 50, 60))
    MapUtil.spawn(folder, "JCSpawn_UNATCO", UnatcoHQ.spawnPoint, Color3.fromRGB(0, 100, 200))

    -- Outer walls
    MapUtil.wall(folder, Vector3.new(-40, 8, 0), Vector3.new(1, 14, 80))
    MapUtil.wall(folder, Vector3.new(40, 8, 0), Vector3.new(1, 14, 80))
    MapUtil.wall(folder, Vector3.new(0, 8, -40), Vector3.new(80, 14, 1))
    MapUtil.wall(folder, Vector3.new(-22, 8, 40), Vector3.new(36, 14, 1))
    MapUtil.wall(folder, Vector3.new(22, 8, 40), Vector3.new(36, 14, 1))
    MapUtil.floor(folder, Vector3.new(0, 16, 0), Vector3.new(80, 1, 80))

    -- UN logo banner
    local banner = MapUtil.part(folder, {
        Size = Vector3.new(20, 8, 0.5),
        Position = Vector3.new(0, 10, -39),
        Color = Color3.fromRGB(20, 60, 120),
        Material = Enum.Material.Fabric,
    })
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Front
    sg.Parent = banner
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Text = "UNATCO"
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextScaled = true
    lbl.Parent = sg

    -- Desks / partitions
    for x = -25, 25, 25 do
        MapUtil.box(folder, Vector3.new(x, 3, -20), Vector3.new(8, 4, 4),
            Color3.fromRGB(90, 70, 50), Enum.Material.Wood)
    end

    -- Med Bay (NE corner): aug install station
    MapUtil.wall(folder, Vector3.new(20, 4, -20), Vector3.new(30, 6, 1))
    MapUtil.wall(folder, Vector3.new(35, 4, -10), Vector3.new(1, 6, 21))
    local medBot = MapUtil.part(folder, {
        Name = "MedBot",
        Size = Vector3.new(4, 6, 4),
        Position = Vector3.new(30, 4, -15),
        Color = Color3.fromRGB(220, 220, 220),
        Material = Enum.Material.Metal,
    })
    medBot:SetAttribute("InteractionType", "MedBot")
    MapUtil.label(folder, "Med Bay (Install Aug)", Vector3.new(30, 9, -15))

    -- Supply officer
    MapUtil.npc(folder, "Dr. Reyes", Vector3.new(20, 3, -15), "JaimeReyes",
        Color3.fromRGB(200, 200, 220))

    -- Briefing area: Joseph Manderley/Paul Denton
    MapUtil.npc(folder, "Paul Denton", Vector3.new(-20, 3, -15), "PaulDenton",
        Color3.fromRGB(40, 50, 90))

    MapUtil.label(folder, "UNATCO Headquarters", Vector3.new(0, 14, 0),
        Color3.fromRGB(180, 220, 255))

    -- Pickups
    MapUtil.pickup(folder, "Medkit", 2, Vector3.new(-15, 2, 10), Color3.fromRGB(255, 80, 80))
    MapUtil.pickup(folder, "Biocell", 2, Vector3.new(15, 2, 10), Color3.fromRGB(80, 200, 255))
    MapUtil.pickup(folder, "Ammo10mm", 60, Vector3.new(-25, 2, 5), Color3.fromRGB(220, 200, 80))

    -- Mission terminals (transitions)
    MapUtil.transition(folder, "ToLiberty", Vector3.new(-25, 4, 35), Vector3.new(6, 8, 4), "LibertyIsland")
    MapUtil.label(folder, "Liberty Island", Vector3.new(-25, 9, 35))

    MapUtil.transition(folder, "ToHellsKitchen", Vector3.new(-8, 4, 35), Vector3.new(6, 8, 4), "HellsKitchen")
    MapUtil.label(folder, "Hell's Kitchen", Vector3.new(-8, 9, 35))

    MapUtil.transition(folder, "ToHongKong", Vector3.new(8, 4, 35), Vector3.new(6, 8, 4), "HongKong")
    MapUtil.label(folder, "Hong Kong", Vector3.new(8, 9, 35))

    MapUtil.transition(folder, "ToArea51", Vector3.new(25, 4, 35), Vector3.new(6, 8, 4), "Area51")
    MapUtil.label(folder, "Area 51", Vector3.new(25, 9, 35))

    -- UNATCO security: a friendly bot in the lobby. Faction is overridden
    -- to "UNATCO" so it never counts toward the player's kill count, and
    -- we don't call EnemyAI.run so it stays inert.
    local EnemyAI = require(script.Parent.Parent.EnemyAI)
    local lobbyBot = EnemyAI.spawnSecurityBot(Vector3.new(0, 4, 20))
    lobbyBot:SetAttribute("Faction", "UNATCO")
end

return UnatcoHQ
