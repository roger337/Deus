--!strict
-- Mission 3: Hong Kong — Tonnochi Road / Versalife labs.
-- Neon-lit street with Tracer Tong's lab entrance and Versalife tower entrance.

local MapUtil = require(script.Parent.MapUtil)
local EnemyAI = require(script.Parent.Parent.EnemyAI)

local HongKong = {}

HongKong.id = "HongKong"
HongKong.displayName = "Hong Kong - Tonnochi Road"
HongKong.spawnPoint = Vector3.new(0, 4, 100)

function HongKong.build(folder: Folder)
    -- Wet street
    MapUtil.floor(folder, Vector3.new(0, 1, 0), Vector3.new(120, 1, 240),
        Color3.fromRGB(30, 30, 38))
    MapUtil.spawn(folder, "JCSpawn_HK", HongKong.spawnPoint, Color3.fromRGB(200, 0, 200))

    -- Towers either side, lit with neon
    local function tower(x: number, z: number, color: Color3, signText: string)
        MapUtil.box(folder, Vector3.new(x, 40, z), Vector3.new(40, 80, 40),
            Color3.fromRGB(40, 40, 50), Enum.Material.Concrete)
        local sign = MapUtil.part(folder, {
            Size = Vector3.new(36, 8, 0.5),
            Position = Vector3.new(x - (x > 0 and 20 or -20), 35, z),
            CFrame = CFrame.new(x - (x > 0 and 20 or -20), 35, z) * CFrame.Angles(0, math.rad(x > 0 and -90 or 90), 0),
            Color = color,
            Material = Enum.Material.Neon,
        })
        local sg = Instance.new("SurfaceGui")
        sg.Face = Enum.NormalId.Front
        sg.Parent = sign
        local lbl = Instance.new("TextLabel")
        lbl.BackgroundTransparency = 1
        lbl.Size = UDim2.new(1, 0, 1, 0)
        lbl.Text = signText
        lbl.Font = Enum.Font.GothamBold
        lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
        lbl.TextStrokeTransparency = 0
        lbl.TextScaled = true
        lbl.Parent = sg
        local light = Instance.new("PointLight")
        light.Color = color
        light.Range = 60
        light.Brightness = 3
        light.Parent = sign
    end

    tower(-50, 50, Color3.fromRGB(255, 50, 100), "VERSALIFE")
    tower(50, 50, Color3.fromRGB(50, 200, 255), "LUCKY MONEY")
    tower(-50, -50, Color3.fromRGB(200, 100, 255), "QUEEN'S TOWER")
    tower(50, -50, Color3.fromRGB(255, 200, 50), "TONG'S CLINIC")

    -- Hanging lanterns
    for z = -80, 80, 16 do
        local lantern = MapUtil.part(folder, {
            Size = Vector3.new(2, 3, 2),
            Position = Vector3.new(0, 18, z),
            Color = Color3.fromRGB(255, 80, 80),
            Material = Enum.Material.Neon,
        })
        local pl = Instance.new("PointLight")
        pl.Color = Color3.fromRGB(255, 100, 100)
        pl.Range = 20
        pl.Brightness = 1
        pl.Parent = lantern
    end

    -- Versalife entrance (locked, hard difficulty)
    MapUtil.door(folder, Vector3.new(-30, 5, 50), true, 3)
    MapUtil.terminal(folder, Vector3.new(-30, 4, 30), 3, "HackTerminal")

    -- Tracer Tong's clinic (open)
    MapUtil.door(folder, Vector3.new(30, 5, -50), false)
    MapUtil.npc(folder, "Tracer Tong", Vector3.new(35, 3, -55), "JaimeReyes",
        Color3.fromRGB(80, 60, 40))

    -- MJ12 commandos
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-20, 4, 0), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(20, 4, 0), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(-30, 4, 70), "SniperRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(0, 4, -70), "AssaultRifle"))
    EnemyAI.run(EnemyAI.spawn(Vector3.new(15, 4, -90), "Pistol10mm"))

    -- Versalife security bots patrol the corporate side of the street.
    EnemyAI.run(EnemyAI.spawnSecurityBot(Vector3.new(-30, 4, 30)))
    EnemyAI.run(EnemyAI.spawnSpiderBot(Vector3.new(-25, 4, 50)))

    -- Pickups
    MapUtil.pickup(folder, "Medkit", 1, Vector3.new(-15, 2, 60), Color3.fromRGB(255, 80, 80))
    MapUtil.pickup(folder, "Biocell", 2, Vector3.new(20, 2, -40), Color3.fromRGB(80, 200, 255))
    MapUtil.pickup(folder, "AugCanister", 1, Vector3.new(0, 2, 0), Color3.fromRGB(255, 0, 200))
    MapUtil.pickup(folder, "AugUpgradeCanister", 1, Vector3.new(0, 2, 20), Color3.fromRGB(255, 100, 200))
    MapUtil.pickup(folder, "Multitool", 3, Vector3.new(-30, 2, 25), Color3.fromRGB(80, 200, 80))
    MapUtil.pickup(folder, "Ammo762", 60, Vector3.new(0, 2, -20), Color3.fromRGB(220, 200, 80))

    MapUtil.label(folder, "Hong Kong - Tonnochi Road", Vector3.new(0, 90, 0),
        Color3.fromRGB(255, 100, 200))

    -- Transition back to UNATCO HQ
    MapUtil.transition(folder, "ToUNATCO", Vector3.new(0, 4, 115), Vector3.new(8, 8, 4), "UNATCO_HQ")
    MapUtil.label(folder, "Helipad -> UNATCO HQ", Vector3.new(0, 9, 115))
end

return HongKong
