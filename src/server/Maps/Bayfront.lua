--!strict
-- Mission 1: Bayfront District. The operative's first contract — recover
-- the stolen Helix vial cases from the Awakened cell holding the condemned
-- amusement pier.

local MapUtil = require(script.Parent.MapUtil)
local EnemyAI = require(script.Parent.Parent.EnemyAI)

local Bayfront = {}

Bayfront.id = "Bayfront"
Bayfront.displayName = "Bayfront District"
Bayfront.spawnPoint = Vector3.new(0, 4, 230)

function Bayfront.build(folder: Folder)
    -- Polluted bay
    MapUtil.part(folder, {
        Name = "Bay",
        Size = Vector3.new(2000, 4, 2000),
        Position = Vector3.new(0, -2, 0),
        Color = Color3.fromRGB(20, 35, 60),
        Material = Enum.Material.Water,
        Transparency = 0.2,
    })

    -- Boardwalk approach
    MapUtil.box(folder, Vector3.new(0, 1, 200), Vector3.new(40, 2, 80),
        Color3.fromRGB(80, 50, 30), Enum.Material.WoodPlanks)
    MapUtil.spawn(folder, "OperativeSpawn_Bayfront", Bayfront.spawnPoint)

    -- Stone path leading to the pier
    for z = 150, -10, -20 do
        MapUtil.box(folder, Vector3.new(0, 1, z), Vector3.new(20, 1, 20),
            Color3.fromRGB(120, 120, 120), Enum.Material.Cobblestone)
    end

    -- Pier base + condemned crane silhouette (Awakened use this as a meeting spot)
    MapUtil.box(folder, Vector3.new(0, 18, -80), Vector3.new(80, 40, 80),
        Color3.fromRGB(150, 140, 110), Enum.Material.Concrete)

    -- Broken crane: stub tower + diagonal arm + suspended cable
    MapUtil.box(folder, Vector3.new(0, 50, -80), Vector3.new(8, 30, 8),
        Color3.fromRGB(200, 50, 30), Enum.Material.CorrugatedMetal)
    MapUtil.part(folder, {
        Size = Vector3.new(40, 4, 4),
        CFrame = CFrame.new(15, 65, -80) * CFrame.Angles(0, 0, math.rad(-15)),
        Color = Color3.fromRGB(200, 50, 30),
        Material = Enum.Material.CorrugatedMetal,
    })
    local hookCable = MapUtil.part(folder, {
        Size = Vector3.new(0.4, 12, 0.4),
        Position = Vector3.new(28, 56, -80),
        Color = Color3.fromRGB(60, 60, 60),
        Material = Enum.Material.Metal,
    })
    local hookLight = Instance.new("PointLight")
    hookLight.Color = Color3.fromRGB(255, 180, 80)
    hookLight.Range = 30
    hookLight.Brightness = 1.5
    hookLight.Parent = hookCable

    -- Operations bunker on top of the pier
    MapUtil.floor(folder, Vector3.new(0, 39, -80), Vector3.new(40, 1, 40))
    MapUtil.wall(folder, Vector3.new(-20, 45, -80), Vector3.new(1, 12, 40))
    MapUtil.wall(folder, Vector3.new(20, 45, -80), Vector3.new(1, 12, 40))
    MapUtil.wall(folder, Vector3.new(0, 45, -100), Vector3.new(40, 12, 1))
    MapUtil.wall(folder, Vector3.new(-13, 45, -60), Vector3.new(14, 12, 1))
    MapUtil.wall(folder, Vector3.new(13, 45, -60), Vector3.new(14, 12, 1))
    MapUtil.floor(folder, Vector3.new(0, 51, -80), Vector3.new(40, 1, 40))

    MapUtil.door(folder, Vector3.new(0, 45, -60), true, 2)
    MapUtil.terminal(folder, Vector3.new(-15, 42, -98), 2, "HackTerminal")

    -- Helix vial cases (recover all 5)
    for i = 1, 5 do
        local v = MapUtil.part(folder, {
            Name = "HelixVial",
            Size = Vector3.new(1, 2, 1),
            Position = Vector3.new(-15 + i * 4, 41, -75),
            Color = Color3.fromRGB(120, 255, 180),
            Material = Enum.Material.Neon,
            Transparency = 0.2,
        })
        v:SetAttribute("InteractionType", "Pickup")
        v:SetAttribute("ItemId", "KeyHelixVial")
        v:SetAttribute("ItemCount", 1)
    end

    -- Field pickups
    MapUtil.pickup(folder, "Medkit", 1, Vector3.new(-6, 2, 100), Color3.fromRGB(255, 80, 80))
    MapUtil.pickup(folder, "Medkit", 1, Vector3.new(6, 2, 0), Color3.fromRGB(255, 80, 80))
    MapUtil.pickup(folder, "Ammo10mm", 30, Vector3.new(-12, 2, 60), Color3.fromRGB(220, 200, 80))
    MapUtil.pickup(folder, "Ammo762", 30, Vector3.new(12, 2, 60), Color3.fromRGB(220, 200, 80))
    MapUtil.pickup(folder, "Biocell", 1, Vector3.new(0, 2, -20), Color3.fromRGB(80, 200, 255))
    MapUtil.pickup(folder, "AssaultRifle", 1, Vector3.new(0, 2, 30), Color3.fromRGB(120, 120, 120))
    MapUtil.pickup(folder, "AugCanister", 1, Vector3.new(-5, 2, -40), Color3.fromRGB(255, 0, 200))
    MapUtil.pickup(folder, "Lockpick", 3, Vector3.new(8, 2, -30), Color3.fromRGB(160, 160, 160))
    MapUtil.pickup(folder, "Multitool", 3, Vector3.new(-8, 2, -30), Color3.fromRGB(80, 200, 80))
    MapUtil.pickup(folder, "WeaponModAccuracy", 1, Vector3.new(15, 2, 80), Color3.fromRGB(80, 200, 80))
    MapUtil.pickup(folder, "WeaponModSilencer", 1, Vector3.new(-15, 2, 80), Color3.fromRGB(40, 40, 50))

    -- Friendly NPCs at the boardwalk: AEGIS contacts and a confrontation
    -- with the rival enforcer.
    MapUtil.npc(folder, "Marcus Hale", Vector3.new(-8, 3, 220), "MarcusHale", Color3.fromRGB(40, 50, 90))
    MapUtil.npc(folder, "Dr. Halberg", Vector3.new(8, 3, 220), "InesHalberg", Color3.fromRGB(180, 180, 180))
    local vega = MapUtil.npc(folder, "Vega", Vector3.new(0, 3, 240), "Vega", Color3.fromRGB(60, 60, 60))
    vega:SetAttribute("CharacterId", "Vega")

    -- Transition: extraction back to AEGIS Tower
    MapUtil.transition(folder, "ToAegisTower", Vector3.new(0, 4, 250), Vector3.new(8, 8, 4), "AegisTower")
    MapUtil.label(folder, "Extraction -> AEGIS Tower", Vector3.new(0, 9, 250))

    -- Awakened sentries (hostile while the player is AEGIS-aligned)
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-20, 4, 50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(20, 4, 50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-30, 4, -10), "Pistol10mm"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(30, 4, -10), "Pistol10mm"))
    local sniper = EnemyAI.spawn(Vector3.new(35, 40, -80), "SniperRifle")
    sniper.Name = "Awakened_Marksman"
    EnemyAI.run(sniper)
    local cmdr = EnemyAI.spawn(Vector3.new(0, 41, -85), "AssaultRifle")
    cmdr.Name = "Awakened_Organizer"
    cmdr:SetAttribute("Stamina", 200)
    local hum = cmdr:FindFirstChildOfClass("Humanoid")
    if hum then hum.MaxHealth = 200; hum.Health = 200 end
    EnemyAI.run(cmdr)
end

return Bayfront
