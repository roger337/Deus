--!strict
-- Mission 1: Liberty Island. JC's first deployment — recover Ambrosia from the NSF.

local MapUtil = require(script.Parent.MapUtil)
local EnemyAI = require(script.Parent.Parent.EnemyAI)

local LibertyIsland = {}

LibertyIsland.id = "LibertyIsland"
LibertyIsland.displayName = "Liberty Island"
LibertyIsland.spawnPoint = Vector3.new(0, 4, 230)

function LibertyIsland.build(folder: Folder)
    -- Ocean
    MapUtil.part(folder, {
        Name = "Ocean",
        Size = Vector3.new(2000, 4, 2000),
        Position = Vector3.new(0, -2, 0),
        Color = Color3.fromRGB(20, 35, 60),
        Material = Enum.Material.Water,
        Transparency = 0.2,
    })

    -- Pier
    MapUtil.box(folder, Vector3.new(0, 1, 200), Vector3.new(40, 2, 80),
        Color3.fromRGB(80, 50, 30), Enum.Material.WoodPlanks)
    MapUtil.spawn(folder, "JCSpawn_Liberty", LibertyIsland.spawnPoint)

    -- Stone path
    for z = 150, -10, -20 do
        MapUtil.box(folder, Vector3.new(0, 1, z), Vector3.new(20, 1, 20),
            Color3.fromRGB(120, 120, 120), Enum.Material.Cobblestone)
    end

    -- Statue base + broken statue
    MapUtil.box(folder, Vector3.new(0, 18, -80), Vector3.new(80, 40, 80),
        Color3.fromRGB(180, 170, 140), Enum.Material.Concrete)
    MapUtil.box(folder, Vector3.new(0, 50, -80), Vector3.new(20, 30, 12),
        Color3.fromRGB(120, 200, 170), Enum.Material.Marble)
    local arm = MapUtil.part(folder, {
        Size = Vector3.new(6, 30, 6),
        CFrame = CFrame.new(15, 60, -80) * CFrame.Angles(0, 0, math.rad(20)),
        Color = Color3.fromRGB(120, 200, 170),
        Material = Enum.Material.Marble,
    })
    local torch = MapUtil.box(folder, Vector3.new(25, 75, -80), Vector3.new(8, 8, 8),
        Color3.fromRGB(120, 200, 170), Enum.Material.Marble)
    local flame = Instance.new("PointLight")
    flame.Color = Color3.fromRGB(255, 180, 80)
    flame.Range = 30
    flame.Brightness = 2
    flame.Parent = torch

    -- Bunker on top of pedestal
    MapUtil.floor(folder, Vector3.new(0, 39, -80), Vector3.new(40, 1, 40))
    MapUtil.wall(folder, Vector3.new(-20, 45, -80), Vector3.new(1, 12, 40))
    MapUtil.wall(folder, Vector3.new(20, 45, -80), Vector3.new(1, 12, 40))
    MapUtil.wall(folder, Vector3.new(0, 45, -100), Vector3.new(40, 12, 1))
    MapUtil.wall(folder, Vector3.new(-13, 45, -60), Vector3.new(14, 12, 1))
    MapUtil.wall(folder, Vector3.new(13, 45, -60), Vector3.new(14, 12, 1))
    MapUtil.floor(folder, Vector3.new(0, 51, -80), Vector3.new(40, 1, 40))

    MapUtil.door(folder, Vector3.new(0, 45, -60), true, 2)
    MapUtil.terminal(folder, Vector3.new(-15, 42, -98), 2, "HackTerminal")

    -- Ambrosia vials
    for i = 1, 5 do
        local v = MapUtil.part(folder, {
            Name = "AmbrosiaVial",
            Size = Vector3.new(1, 2, 1),
            Position = Vector3.new(-15 + i * 4, 41, -75),
            Color = Color3.fromRGB(120, 255, 180),
            Material = Enum.Material.Neon,
            Transparency = 0.2,
        })
        v:SetAttribute("InteractionType", "Pickup")
        v:SetAttribute("ItemId", "KeyAmbrosia")
        v:SetAttribute("ItemCount", 1)
    end

    -- Pickups
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

    -- Friendly NPCs at the dock
    MapUtil.npc(folder, "Paul Denton", Vector3.new(-8, 3, 220), "PaulDenton", Color3.fromRGB(40, 50, 90))
    MapUtil.npc(folder, "Dr. Reyes", Vector3.new(8, 3, 220), "JaimeReyes", Color3.fromRGB(180, 180, 180))
    MapUtil.npc(folder, "Anna Navarre", Vector3.new(0, 3, 240), "AnnaNavarre", Color3.fromRGB(60, 60, 60))

    -- Transition: extraction boat back to UNATCO HQ
    MapUtil.transition(folder, "ToUNATCO", Vector3.new(0, 4, 250), Vector3.new(8, 8, 4), "UNATCO_HQ")
    MapUtil.label(folder, "Extraction -> UNATCO HQ", Vector3.new(0, 9, 250))

    -- Enemies
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-20, 4, 50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(20, 4, 50), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-30, 4, -10), "Pistol10mm"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(30, 4, -10), "Pistol10mm"))
    local sniper = EnemyAI.spawn(Vector3.new(0, 40, -55), "SniperRifle")
    sniper.Name = "NSF_Sniper"
    EnemyAI.run(sniper)
    local cmdr = EnemyAI.spawn(Vector3.new(0, 41, -85), "AssaultRifle")
    cmdr.Name = "NSF_Commander"
    cmdr:SetAttribute("Stamina", 200)
    local hum = cmdr:FindFirstChildOfClass("Humanoid")
    if hum then hum.MaxHealth = 200; hum.Health = 200 end
    EnemyAI.run(cmdr)
end

return LibertyIsland
