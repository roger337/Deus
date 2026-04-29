--!strict
-- Demo mission. Self-contained training area accessible from the lobby
-- without access approval. Players keep their loadout but no campaign
-- progress is saved here. Showcases the core gameplay verbs:
--   * Move + shoot at static training dummies
--   * Pick a lock
--   * Hack a terminal
--   * Talk to an NPC briefer
--   * Walk through the exit transition back to the lobby

local MapUtil = require(script.Parent.MapUtil)

local Demo = {}

Demo.id = "Demo"
Demo.displayName = "Demo Range"
Demo.spawnPoint = Vector3.new(0, 4, 60)

-- Sterile fluorescent-lit training-room feel.
Demo.ambient = {
    lighting = {
        Ambient        = Color3.fromRGB(80, 90, 100),
        OutdoorAmbient = Color3.fromRGB(150, 160, 170),
        Brightness     = 2.5,
        ClockTime      = 14,
        FogColor       = Color3.fromRGB(180, 190, 200),
        FogStart       = 100,
        FogEnd         = 600,
    },
    music = "",
}

local function dummy(parent: Instance, pos: Vector3, name: string)
    local model = Instance.new("Model")
    model.Name = name
    model:SetAttribute("Faction", "Hostile")  -- damage works, but no AI
    model:SetAttribute("Stamina", 50)

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Anchored = true
    hrp.Size = Vector3.new(2, 4, 1)
    hrp.Position = pos
    hrp.Color = Color3.fromRGB(120, 60, 60)
    hrp.Material = Enum.Material.Plastic
    hrp.Parent = model

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Anchored = true
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(1.4, 1.4, 1.4)
    head.Position = pos + Vector3.new(0, 2.5, 0)
    head.Color = Color3.fromRGB(180, 100, 100)
    head.Parent = model

    local hum = Instance.new("Humanoid")
    hum.MaxHealth = 50
    hum.Health = 50
    hum.WalkSpeed = 0
    hum.Parent = model

    -- Auto-respawn dummy after death so range stays usable.
    hum.Died:Connect(function()
        task.delay(5, function()
            if model.Parent then
                hum.Health = hum.MaxHealth
                model:SetAttribute("Stamina", 50)
            end
        end)
    end)

    local bb = Instance.new("BillboardGui")
    bb.Adornee = head
    bb.Size = UDim2.new(0, 100, 0, 18)
    bb.StudsOffset = Vector3.new(0, 1.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.TextColor3 = Color3.fromRGB(255, 200, 100)
    lbl.Font = Enum.Font.Code
    lbl.TextScaled = true
    lbl.Text = "DUMMY"
    lbl.Parent = bb

    model.PrimaryPart = hrp
    model.Parent = parent
end

function Demo.build(folder: Folder)
    -- Floor
    MapUtil.floor(folder, Vector3.new(0, 1, 0), Vector3.new(80, 1, 160),
        Color3.fromRGB(50, 60, 70))
    MapUtil.spawn(folder, "DemoSpawn", Demo.spawnPoint, Color3.fromRGB(120, 220, 120))

    -- Walls
    MapUtil.wall(folder, Vector3.new(-40, 8, 0), Vector3.new(1, 16, 160))
    MapUtil.wall(folder, Vector3.new(40, 8, 0), Vector3.new(1, 16, 160))
    MapUtil.wall(folder, Vector3.new(0, 8, -80), Vector3.new(80, 16, 1))
    MapUtil.wall(folder, Vector3.new(0, 8, 80), Vector3.new(80, 16, 1))
    MapUtil.floor(folder, Vector3.new(0, 16, 0), Vector3.new(80, 1, 160))

    MapUtil.label(folder, "DEMO RANGE", Vector3.new(0, 14, 60),
        Color3.fromRGB(120, 220, 120))

    -- Lane dividers
    for x = -20, 20, 20 do
        MapUtil.box(folder, Vector3.new(x, 4, 20),
            Vector3.new(0.4, 6, 60),
            Color3.fromRGB(60, 70, 80), Enum.Material.Metal)
    end

    -- Three dummies down the firing range
    for i = 1, 3 do
        dummy(folder, Vector3.new(-20 + (i - 1) * 20, 4, -30), "Dummy_" .. i)
    end

    -- Tutorial briefer (uses the lobby's introductory dialog tree if you
    -- add one; for now reuse the AEGIS technician's tree).
    MapUtil.npc(folder, "Drill Sergeant", Vector3.new(-10, 3, 50),
        "InesHalberg", Color3.fromRGB(80, 80, 100))
    MapUtil.label(folder, "Briefer", Vector3.new(-10, 7, 50))

    -- Practice lock
    MapUtil.door(folder, Vector3.new(15, 5, -50), true, 1)
    MapUtil.label(folder, "Practice Lock (lvl 1)",
        Vector3.new(15, 11, -50), Color3.fromRGB(200, 200, 200))

    -- Practice hack terminal (no objective hookup; just lets you try
    -- the minigame)
    MapUtil.terminal(folder, Vector3.new(-15, 4, -50), 1, nil)
    MapUtil.label(folder, "Practice Terminal (lvl 1)",
        Vector3.new(-15, 9, -50), Color3.fromRGB(120, 220, 120))

    -- Pickups: a basic loadout for trying stuff out
    MapUtil.pickup(folder, "Pistol10mm", 1, Vector3.new(-10, 2, 55), Color3.fromRGB(120, 120, 120))
    MapUtil.pickup(folder, "Ammo10mm", 60, Vector3.new(-5, 2, 55), Color3.fromRGB(220, 200, 80))
    MapUtil.pickup(folder, "AssaultRifle", 1, Vector3.new(0, 2, 55), Color3.fromRGB(120, 120, 120))
    MapUtil.pickup(folder, "Ammo762", 60, Vector3.new(5, 2, 55), Color3.fromRGB(220, 200, 80))
    MapUtil.pickup(folder, "Lockpick", 5, Vector3.new(10, 2, 55), Color3.fromRGB(160, 160, 160))
    MapUtil.pickup(folder, "Multitool", 5, Vector3.new(15, 2, 55), Color3.fromRGB(80, 200, 80))
    MapUtil.pickup(folder, "Medkit", 3, Vector3.new(20, 2, 55), Color3.fromRGB(255, 80, 80))

    -- Exit back to lobby (no access required)
    MapUtil.transition(folder, "ToLobby", Vector3.new(0, 4, 75),
        Vector3.new(8, 8, 4), "Lobby")
    MapUtil.label(folder, "Exit Demo",
        Vector3.new(0, 9, 75), Color3.fromRGB(180, 220, 255))
end

return Demo
