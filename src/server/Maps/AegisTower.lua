--!strict
-- Hub level: AEGIS Tower atrium. Briefing area, biomod technician, supply
-- vendor, AutoMedic for biomod installation, travel transitions to all
-- mission maps. Director Cole's office is on the west side of the floor.

local MapUtil = require(script.Parent.MapUtil)

local AegisTower = {}

AegisTower.id = "AegisTower"
AegisTower.displayName = "AEGIS Tower"
AegisTower.spawnPoint = Vector3.new(0, 4, 0)

function AegisTower.build(folder: Folder)
    -- Atrium floor
    MapUtil.floor(folder, Vector3.new(0, 1, 0), Vector3.new(80, 1, 80),
        Color3.fromRGB(50, 50, 60))
    MapUtil.spawn(folder, "OperativeSpawn_AEGIS", AegisTower.spawnPoint, Color3.fromRGB(0, 100, 200))

    -- Outer walls
    MapUtil.wall(folder, Vector3.new(-40, 8, 0), Vector3.new(1, 14, 80))
    MapUtil.wall(folder, Vector3.new(40, 8, 0), Vector3.new(1, 14, 80))
    MapUtil.wall(folder, Vector3.new(0, 8, -40), Vector3.new(80, 14, 1))
    MapUtil.wall(folder, Vector3.new(-22, 8, 40), Vector3.new(36, 14, 1))
    MapUtil.wall(folder, Vector3.new(22, 8, 40), Vector3.new(36, 14, 1))
    MapUtil.floor(folder, Vector3.new(0, 16, 0), Vector3.new(80, 1, 80))

    -- Corporate banner
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
    lbl.Text = "AEGIS"
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextScaled = true
    lbl.Parent = sg

    -- Workstations / partitions
    for x = -25, 25, 25 do
        MapUtil.box(folder, Vector3.new(x, 3, -20), Vector3.new(8, 4, 4),
            Color3.fromRGB(90, 70, 50), Enum.Material.Wood)
    end

    -- Med Bay (NE corner): biomod install station
    MapUtil.wall(folder, Vector3.new(20, 4, -20), Vector3.new(30, 6, 1))
    MapUtil.wall(folder, Vector3.new(35, 4, -10), Vector3.new(1, 6, 21))
    local autoMedic = MapUtil.part(folder, {
        Name = "AutoMedic",
        Size = Vector3.new(4, 6, 4),
        Position = Vector3.new(30, 4, -15),
        Color = Color3.fromRGB(220, 220, 220),
        Material = Enum.Material.Metal,
    })
    autoMedic:SetAttribute("InteractionType", "MedBot")
    MapUtil.label(folder, "Med Bay (Install Biomod)", Vector3.new(30, 9, -15))

    -- Biomod technician
    MapUtil.npc(folder, "Dr. Halberg", Vector3.new(20, 3, -15), "InesHalberg",
        Color3.fromRGB(200, 200, 220))

    -- Briefing area
    MapUtil.npc(folder, "Marcus Hale", Vector3.new(-20, 3, -15), "MarcusHale",
        Color3.fromRGB(40, 50, 90))

    -- Director Cole (Helix liaison; opens the fourth ending path)
    MapUtil.npc(folder, "Director Cole", Vector3.new(-30, 3, 5), "DirectorCole",
        Color3.fromRGB(20, 20, 25))

    MapUtil.label(folder, "AEGIS Tower", Vector3.new(0, 14, 0),
        Color3.fromRGB(180, 220, 255))

    -- Pickups
    MapUtil.pickup(folder, "Medkit", 2, Vector3.new(-15, 2, 10), Color3.fromRGB(255, 80, 80))
    MapUtil.pickup(folder, "Biocell", 2, Vector3.new(15, 2, 10), Color3.fromRGB(80, 200, 255))
    MapUtil.pickup(folder, "Ammo10mm", 60, Vector3.new(-25, 2, 5), Color3.fromRGB(220, 200, 80))

    -- Mission terminals (transitions to the campaign maps)
    MapUtil.transition(folder, "ToBayfront", Vector3.new(-25, 4, 35), Vector3.new(6, 8, 4), "Bayfront")
    MapUtil.label(folder, "Bayfront District", Vector3.new(-25, 9, 35))

    MapUtil.transition(folder, "ToHardline", Vector3.new(-8, 4, 35), Vector3.new(6, 8, 4), "Hardline")
    MapUtil.label(folder, "Hardline District", Vector3.new(-8, 9, 35))

    MapUtil.transition(folder, "ToAnchor", Vector3.new(8, 4, 35), Vector3.new(6, 8, 4), "PacificAnchor")
    MapUtil.label(folder, "Pacific Anchor", Vector3.new(8, 9, 35))

    MapUtil.transition(folder, "ToVault7", Vector3.new(25, 4, 35), Vector3.new(6, 8, 4), "Vault7")
    MapUtil.label(folder, "Vault-7 (Sierras)", Vector3.new(25, 9, 35))

    -- Friendly inert AEGIS bot in the lobby (Faction = "AEGIS" so kills
    -- don't count against the player's score).
    local EnemyAI = require(script.Parent.Parent.EnemyAI)
    local lobbyBot = EnemyAI.spawnSecurityBot(Vector3.new(0, 4, 20))
    lobbyBot:SetAttribute("Faction", "AEGIS")

    -- AEGIS Quartermaster.
    MapUtil.vendor(folder, "Quartermaster", Vector3.new(30, 3, 10), "AEGIS_QM",
        Color3.fromRGB(40, 50, 90))
end

return AegisTower
