--!strict
-- Final mission: Area 51. Underground Majestic-12 facility, Helios server room.
-- Heavy security; the ending choice (Helios merge / Illuminati / Dark Age) lives here.

local MapUtil = require(script.Parent.MapUtil)
local EnemyAI = require(script.Parent.Parent.EnemyAI)

local Area51 = {}

Area51.id = "Area51"
Area51.displayName = "Area 51 - Sector 4"
Area51.spawnPoint = Vector3.new(0, 4, 100)

function Area51.build(folder: Folder)
    -- Sand outdoor zone
    MapUtil.floor(folder, Vector3.new(0, 1, 60), Vector3.new(160, 1, 100),
        Color3.fromRGB(160, 130, 80))
    MapUtil.spawn(folder, "JCSpawn_Area51", Area51.spawnPoint, Color3.fromRGB(200, 50, 50))

    -- Outer fence
    for x = -80, 80, 16 do
        MapUtil.box(folder, Vector3.new(x, 8, 110), Vector3.new(0.5, 16, 0.5),
            Color3.fromRGB(180, 180, 180), Enum.Material.Metal)
    end
    -- "TOP SECRET" hangar
    MapUtil.box(folder, Vector3.new(0, 20, 30), Vector3.new(120, 40, 60),
        Color3.fromRGB(80, 80, 90), Enum.Material.Metal)
    local sign = MapUtil.part(folder, {
        Size = Vector3.new(60, 6, 0.5),
        Position = Vector3.new(0, 30, 0.5),
        Color = Color3.fromRGB(20, 20, 20),
    })
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Front
    sg.Parent = sign
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Text = "AREA 51 - SECTOR 4 - AUTHORIZED PERSONNEL ONLY"
    lbl.Font = Enum.Font.RobotoMono
    lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    lbl.TextScaled = true
    lbl.Parent = sg

    -- Hangar door (locked, max difficulty)
    MapUtil.door(folder, Vector3.new(0, 5, 0), true, 4)

    -- Underground facility
    MapUtil.floor(folder, Vector3.new(0, -10, -50), Vector3.new(80, 1, 80),
        Color3.fromRGB(40, 50, 60))
    MapUtil.wall(folder, Vector3.new(-40, -4, -50), Vector3.new(1, 12, 80))
    MapUtil.wall(folder, Vector3.new(40, -4, -50), Vector3.new(1, 12, 80))
    MapUtil.wall(folder, Vector3.new(0, -4, -90), Vector3.new(80, 12, 1))
    MapUtil.wall(folder, Vector3.new(0, -4, -10), Vector3.new(80, 12, 1))
    MapUtil.floor(folder, Vector3.new(0, 2, -50), Vector3.new(80, 1, 80))

    -- Stairs down (simple ramp)
    local ramp = MapUtil.part(folder, {
        Size = Vector3.new(16, 1, 30),
        CFrame = CFrame.new(0, -4, 5) * CFrame.Angles(math.rad(-25), 0, 0),
        Color = Color3.fromRGB(60, 60, 70),
        Material = Enum.Material.Metal,
    })

    -- Helios server room
    local helios = MapUtil.part(folder, {
        Name = "HeliosCore",
        Size = Vector3.new(8, 12, 8),
        Position = Vector3.new(0, -4, -80),
        Color = Color3.fromRGB(150, 200, 255),
        Material = Enum.Material.Neon,
        Transparency = 0.3,
    })
    helios:SetAttribute("InteractionType", "Hack")
    helios:SetAttribute("HackDifficulty", 4)
    helios:SetAttribute("ObjectiveId", "HackTerminal")
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(150, 200, 255)
    light.Range = 50
    light.Brightness = 4
    light.Parent = helios
    MapUtil.label(folder, "HELIOS AI Core", Vector3.new(0, 4, -80),
        Color3.fromRGB(150, 200, 255))

    -- Endgame choice consoles
    local function endChoice(name: string, endingId: string, pos: Vector3, color: Color3, label: string)
        local p = MapUtil.part(folder, {
            Name = name,
            Size = Vector3.new(3, 4, 1),
            Position = pos,
            Color = color,
            Material = Enum.Material.Neon,
        })
        p:SetAttribute("InteractionType", "Hack")
        p:SetAttribute("HackDifficulty", 3)
        p:SetAttribute("EndingId", endingId)
        MapUtil.label(folder, label, pos + Vector3.new(0, 5, 0), color)
    end
    endChoice("EndingHelios", "Helios", Vector3.new(-30, -8, -80), Color3.fromRGB(150, 200, 255), "Merge with Helios")
    endChoice("EndingIlluminati", "Illuminati", Vector3.new(-10, -8, -88), Color3.fromRGB(255, 215, 0), "Restore Illuminati")
    endChoice("EndingDarkAge", "DarkAge", Vector3.new(10, -8, -88), Color3.fromRGB(120, 30, 30), "Trigger Dark Age")
    endChoice("EndingMJ12", "MJ12Enforce", Vector3.new(30, -8, -80), Color3.fromRGB(60, 30, 30), "Become MJ12 Enforcer")

    -- MJ12 commandos
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-30, 4, 50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(30, 4, 50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(0, 4, 80), "SniperRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-20, -8, -50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(20, -8, -50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(0, -8, -70), "GepGun"))

    -- Sector 4 patrol bots: two security bots topside, two spiders
    -- guarding the underground Helios chamber.
    EnemyAI.run(EnemyAI.spawnSecurityBot(Vector3.new(-15, 4, 20)))
    EnemyAI.run(EnemyAI.spawnSecurityBot(Vector3.new(15, 4, 20)))
    EnemyAI.run(EnemyAI.spawnSpiderBot(Vector3.new(-10, -8, -60)))
    EnemyAI.run(EnemyAI.spawnSpiderBot(Vector3.new(10, -8, -60)))

    -- Endgame loot
    MapUtil.pickup(folder, "Biocell", 4, Vector3.new(-20, 2, 50), Color3.fromRGB(80, 200, 255))
    MapUtil.pickup(folder, "Medkit", 4, Vector3.new(20, 2, 50), Color3.fromRGB(255, 80, 80))
    MapUtil.pickup(folder, "GepGun", 1, Vector3.new(0, -8, -30), Color3.fromRGB(160, 80, 30))
    MapUtil.pickup(folder, "AmmoRocket", 4, Vector3.new(5, -8, -30), Color3.fromRGB(160, 80, 30))
    MapUtil.pickup(folder, "AugUpgradeCanister", 2, Vector3.new(-10, -8, -40), Color3.fromRGB(255, 100, 200))
    MapUtil.pickup(folder, "LAM", 1, Vector3.new(10, -8, -40), Color3.fromRGB(255, 100, 80))
    MapUtil.pickup(folder, "AmmoLAM", 4, Vector3.new(15, -8, -40), Color3.fromRGB(255, 100, 80))
    MapUtil.pickup(folder, "PlasmaRifle", 1, Vector3.new(-25, -8, -30), Color3.fromRGB(80, 200, 255))
    MapUtil.pickup(folder, "AmmoPlasma", 60, Vector3.new(-25, -8, -40), Color3.fromRGB(80, 200, 255))
    MapUtil.pickup(folder, "WeaponModDamage", 2, Vector3.new(0, -8, -20), Color3.fromRGB(220, 60, 60))
    MapUtil.pickup(folder, "WeaponModAccuracy", 1, Vector3.new(20, -8, -20), Color3.fromRGB(80, 200, 80))
    MapUtil.pickup(folder, "WeaponModRange", 1, Vector3.new(-20, -8, -20), Color3.fromRGB(80, 160, 220))

    -- MJ12 Quartermaster (sells exotic gear; only to MJ12 members).
    MapUtil.vendor(folder, "MJ12 Quartermaster", Vector3.new(0, -8, -10), "MJ12_QM",
        Color3.fromRGB(20, 20, 30))

    -- Transition back to UNATCO HQ
    MapUtil.transition(folder, "ToUNATCO", Vector3.new(0, 4, 115), Vector3.new(8, 8, 4), "UNATCO_HQ")
    MapUtil.label(folder, "Exfil -> UNATCO HQ", Vector3.new(0, 9, 115))
end

return Area51
