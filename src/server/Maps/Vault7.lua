--!strict
-- Final mission: Vault-7. Underground Helix custodial site beneath the
-- Sierras. Houses the Lattice core — the AI that maintains Earth's
-- perception filter. The four endgame consoles live in the deepest chamber.

local MapUtil = require(script.Parent.MapUtil)
local EnemyAI = require(script.Parent.Parent.EnemyAI)

local Vault7 = {}

Vault7.id = "Vault7"
Vault7.displayName = "Vault-7 (Sierras)"
Vault7.spawnPoint = Vector3.new(0, 4, 100)

-- Deep emergency-red ambient. The endgame chamber should feel like the
-- floor of the world — but the player still needs to see the consoles
-- and the exit, so brightness is kept playable and fog isn't pea-soup.
Vault7.ambient = {
    lighting = {
        Ambient        = Color3.fromRGB(50, 25, 25),
        OutdoorAmbient = Color3.fromRGB(70, 35, 35),
        Brightness     = 0.8,
        ClockTime      = 22,
        FogColor       = Color3.fromRGB(40, 15, 15),
        FogStart       = 100,
        FogEnd         = 500,
    },
    music = "",
}

function Vault7.build(folder: Folder)
    -- Sand outdoor zone
    MapUtil.floor(folder, Vector3.new(0, 1, 60), Vector3.new(160, 1, 100),
        Color3.fromRGB(160, 130, 80))
    MapUtil.spawn(folder, "OperativeSpawn_Vault7", Vault7.spawnPoint, Color3.fromRGB(200, 50, 50))

    -- Outer fence
    for x = -80, 80, 16 do
        MapUtil.box(folder, Vector3.new(x, 8, 110), Vector3.new(0.5, 16, 0.5),
            Color3.fromRGB(180, 180, 180), Enum.Material.Metal)
    end
    -- "RESTRICTED" hangar
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
    lbl.Text = "VAULT-7  |  CUSTODIAL SITE  |  RESTRICTED"
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

    -- Stairs down (ramp)
    MapUtil.part(folder, {
        Size = Vector3.new(16, 1, 30),
        CFrame = CFrame.new(0, -4, 5) * CFrame.Angles(math.rad(-25), 0, 0),
        Color = Color3.fromRGB(60, 60, 70),
        Material = Enum.Material.Metal,
    })

    -- Lattice core chamber
    local lattice = MapUtil.part(folder, {
        Name = "LatticeCore",
        Size = Vector3.new(8, 12, 8),
        Position = Vector3.new(0, -4, -80),
        Color = Color3.fromRGB(150, 200, 255),
        Material = Enum.Material.Neon,
        Transparency = 0.3,
    })
    lattice:SetAttribute("InteractionType", "Hack")
    lattice:SetAttribute("HackDifficulty", 4)
    lattice:SetAttribute("ObjectiveId", "HackTerminal")
    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(150, 200, 255)
    light.Range = 50
    light.Brightness = 4
    light.Parent = lattice
    MapUtil.label(folder, "LATTICE CORE", Vector3.new(0, 4, -80),
        Color3.fromRGB(150, 200, 255))

    -- Endgame consoles (four; the Helix Ascension console gated by joinedHelix)
    local function endChoice(name: string, endingId: string, voteId: string,
                              pos: Vector3, color: Color3, label: string)
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
        p:SetAttribute("EndingVote", voteId)
        MapUtil.label(folder, label, pos + Vector3.new(0, 5, 0), color)
    end
    endChoice("EndingLattice", "Lattice", "endingLattice",
        Vector3.new(-30, -8, -80), Color3.fromRGB(150, 200, 255), "Lattice Symbiosis")
    endChoice("EndingQuorum", "Quorum", "endingQuorum",
        Vector3.new(-10, -8, -88), Color3.fromRGB(255, 215, 0), "Quorum Restoration")
    endChoice("EndingReset", "Reset", "endingReset",
        Vector3.new(10, -8, -88), Color3.fromRGB(120, 30, 30), "Network Reset")
    endChoice("EndingHelixAscension", "HelixAscension", "endingHelixAscension",
        Vector3.new(30, -8, -80), Color3.fromRGB(60, 30, 30), "Helix Ascension")

    -- The fifth path: a plain door at the back of the chamber. Touching it
    -- opens the Faith vote — refuse all four consoles, walk out, ascend
    -- without their tools. Visually unassuming (the others glow; this is
    -- just a frame).
    local exit = MapUtil.part(folder, {
        Name = "FaithExit",
        Size = Vector3.new(6, 8, 0.5),
        Position = Vector3.new(0, -6, -100),
        Color = Color3.fromRGB(240, 240, 200),
        Material = Enum.Material.SmoothPlastic,
    })
    exit:SetAttribute("InteractionType", "EndingDirect")
    exit:SetAttribute("EndingId", "AscensionByFaith")
    exit:SetAttribute("EndingVote", "endingFaith")
    MapUtil.label(folder, "Walk Out  (Ascension by Faith)",
        Vector3.new(0, -1, -100), Color3.fromRGB(240, 240, 200))

    -- Helix custodian troopers + bots
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-30, 4, 50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(30, 4, 50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(0, 4, 80), "SniperRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-20, -8, -50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(20, -8, -50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(0, -8, -70), "GepGun"))
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

    -- Helix Quartermaster (only sells to Helix members)
    MapUtil.vendor(folder, "Helix Quartermaster", Vector3.new(0, -8, -10), "Helix_QM",
        Color3.fromRGB(20, 20, 30))

    -- Transition back to AEGIS Tower
    MapUtil.transition(folder, "ToAegisTower", Vector3.new(0, 4, 115), Vector3.new(8, 8, 4), "AegisTower")
    MapUtil.label(folder, "Exfil -> AEGIS Tower", Vector3.new(0, 9, 115))
end

return Vault7
