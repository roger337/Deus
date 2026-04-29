--!strict
-- Mission 2: Hell's Kitchen — NYC street level. 'Ton Hotel, warehouse, alley.
-- Mixed civilian + hostile presence; hackable computer with NSF intel.

local MapUtil = require(script.Parent.MapUtil)
local EnemyAI = require(script.Parent.Parent.EnemyAI)

local HellsKitchen = {}

HellsKitchen.id = "HellsKitchen"
HellsKitchen.displayName = "Hell's Kitchen"
HellsKitchen.spawnPoint = Vector3.new(0, 4, 80)

function HellsKitchen.build(folder: Folder)
    -- Street pavement
    MapUtil.floor(folder, Vector3.new(0, 1, 0), Vector3.new(120, 1, 200),
        Color3.fromRGB(45, 45, 50))
    MapUtil.spawn(folder, "JCSpawn_Hells", HellsKitchen.spawnPoint, Color3.fromRGB(0, 100, 200))

    -- Yellow road lines
    for z = -90, 90, 20 do
        MapUtil.box(folder, Vector3.new(0, 1.5, z), Vector3.new(0.6, 0.1, 8),
            Color3.fromRGB(255, 200, 50), Enum.Material.Neon)
    end

    -- Tenement buildings (left side)
    for i = 0, 4 do
        local z = -80 + i * 40
        MapUtil.box(folder, Vector3.new(-50, 20, z), Vector3.new(40, 40, 35),
            Color3.fromRGB(90, 60, 50), Enum.Material.Brick)
        for floor = 1, 5 do
            for w = 0, 3 do
                MapUtil.part(folder, {
                    Size = Vector3.new(0.5, 4, 4),
                    Position = Vector3.new(-30, floor * 7, z - 12 + w * 8),
                    Color = Color3.fromRGB(255, 230, 120),
                    Material = Enum.Material.Neon,
                    Transparency = 0.3,
                })
            end
        end
    end

    -- 'Ton Hotel (right side)
    MapUtil.box(folder, Vector3.new(50, 25, 0), Vector3.new(40, 50, 60),
        Color3.fromRGB(70, 60, 80), Enum.Material.Brick)
    -- 'Ton sign
    local sign = MapUtil.part(folder, {
        Size = Vector3.new(20, 6, 0.5),
        Position = Vector3.new(35, 12, 0),
        Color = Color3.fromRGB(200, 30, 30),
        Material = Enum.Material.Neon,
    })
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Left
    sg.Parent = sign
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.Text = "'TON HOTEL"
    lbl.Font = Enum.Font.GothamBold
    lbl.TextColor3 = Color3.fromRGB(255, 220, 220)
    lbl.TextScaled = true
    lbl.Parent = sg

    -- Hotel lobby door (locked)
    MapUtil.door(folder, Vector3.new(34, 5, 0), true, 1)

    -- Warehouse (south)
    MapUtil.box(folder, Vector3.new(0, 12, -130), Vector3.new(80, 24, 40),
        Color3.fromRGB(70, 70, 70), Enum.Material.CorrugatedMetal)
    MapUtil.door(folder, Vector3.new(0, 5, -110), true, 2)
    MapUtil.terminal(folder, Vector3.new(-10, 4, -140), 2, "HackTerminal")

    -- Crates
    for i = 1, 8 do
        MapUtil.box(folder, Vector3.new(math.random(-30, 30), 3, math.random(-150, -120)),
            Vector3.new(4, 4, 4),
            Color3.fromRGB(120, 80, 40), Enum.Material.Wood)
    end

    -- Streetlights
    for z = -60, 60, 30 do
        MapUtil.box(folder, Vector3.new(20, 8, z), Vector3.new(0.5, 16, 0.5),
            Color3.fromRGB(50, 50, 50), Enum.Material.Metal)
        local bulb = MapUtil.part(folder, {
            Size = Vector3.new(2, 2, 2),
            Position = Vector3.new(20, 17, z),
            Color = Color3.fromRGB(255, 240, 200),
            Material = Enum.Material.Neon,
            Transparency = 0.3,
        })
        local light = Instance.new("PointLight")
        light.Range = 30
        light.Brightness = 1.5
        light.Color = Color3.fromRGB(255, 230, 180)
        light.Parent = bulb
    end

    -- Civilians / informant
    MapUtil.npc(folder, "Sandra Renton", Vector3.new(30, 3, 50), "JaimeReyes",
        Color3.fromRGB(140, 80, 100))

    -- NSF gangsters
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-20, 4, -30), "Pistol10mm"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(20, 4, -50), "Pistol10mm"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(0, 4, -130), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-15, 4, -130), "AssaultRifle"))

    -- One spider bot lurking in the warehouse — NSF patched it together
    -- from stolen Versalife parts.
    EnemyAI.run(EnemyAI.spawnSpiderBot(Vector3.new(15, 4, -135)))

    -- Pickups
    MapUtil.pickup(folder, "Medkit", 1, Vector3.new(20, 2, 70), Color3.fromRGB(255, 80, 80))
    MapUtil.pickup(folder, "MiniCrossbow", 1, Vector3.new(-20, 2, 30), Color3.fromRGB(180, 180, 200))
    MapUtil.pickup(folder, "AmmoTranq", 10, Vector3.new(-20, 2, 40), Color3.fromRGB(180, 180, 200))
    MapUtil.pickup(folder, "Lockpick", 2, Vector3.new(45, 2, -100), Color3.fromRGB(160, 160, 160))
    MapUtil.pickup(folder, "DataCube", 1, Vector3.new(-20, 4, -140), Color3.fromRGB(0, 200, 255))
    MapUtil.pickup(folder, "StealthPistol", 1, Vector3.new(40, 2, 40), Color3.fromRGB(40, 40, 50))
    MapUtil.pickup(folder, "ThrowingKnife", 1, Vector3.new(-40, 2, 40), Color3.fromRGB(180, 200, 220))
    MapUtil.pickup(folder, "AmmoKnife", 6, Vector3.new(-40, 2, 50), Color3.fromRGB(180, 200, 220))
    MapUtil.pickup(folder, "WeaponModClip", 1, Vector3.new(0, 2, 60), Color3.fromRGB(160, 160, 160))
    MapUtil.pickup(folder, "WeaponModLaser", 1, Vector3.new(45, 2, 0), Color3.fromRGB(255, 50, 50))
    MapUtil.pickup(folder, "WeaponModRecoil", 1, Vector3.new(-45, 2, 0), Color3.fromRGB(140, 100, 80))

    MapUtil.label(folder, "Hell's Kitchen, NYC", Vector3.new(0, 30, 0),
        Color3.fromRGB(180, 220, 255))

    -- Transition back to UNATCO
    MapUtil.transition(folder, "ToUNATCO", Vector3.new(0, 4, 95), Vector3.new(8, 8, 4), "UNATCO_HQ")
    MapUtil.label(folder, "Subway -> UNATCO HQ", Vector3.new(0, 9, 95))
end

return HellsKitchen
