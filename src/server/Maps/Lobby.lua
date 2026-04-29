--!strict
-- Lobby map. Every player joins here first. They cannot reach AEGIS Tower
-- (the actual game hub) without access. The lobby has:
--   * Three info kiosks (Story / Mechanics / Factions) with read-only text
--   * A vendor preview alcove (the AEGIS Quartermaster, browse-only)
--   * A Request Access terminal (opens the request UI on click)
--   * A "Play Demo" transition -> Demo map
--   * An "Enter Game" transition -> AegisTower (gated by AccessService)
--   * An Owner Console (only interactable by AccessConfig.AdminUserIds)

local MapUtil = require(script.Parent.MapUtil)

local Lobby = {}

Lobby.id = "Lobby"
Lobby.displayName = "Lobby"
Lobby.spawnPoint = Vector3.new(0, 4, 0)

-- Late-afternoon civic atrium: warm but not blinding. Brightness/clock/fog
-- tuned so the kiosks and terminals across the lobby are clearly visible.
-- Music is a placeholder — drop in a `rbxassetid://NUMBER` for an audio
-- asset you own to enable it. Empty string = silence.
Lobby.ambient = {
    lighting = {
        Ambient        = Color3.fromRGB(60, 55, 50),
        OutdoorAmbient = Color3.fromRGB(90, 80, 70),
        Brightness     = 1.5,
        ClockTime      = 16,
        FogColor       = Color3.fromRGB(40, 35, 30),
        FogStart       = 200,
        FogEnd         = 800,
    },
    music = "",  -- e.g. "rbxassetid://123456789"
}

local function infoKiosk(folder: Instance, title: string, body: string, pos: Vector3)
    local stand = MapUtil.box(folder, pos, Vector3.new(8, 0.5, 4),
        Color3.fromRGB(40, 40, 50), Enum.Material.Metal)
    local screen = MapUtil.part(folder, {
        Size = Vector3.new(7, 5, 0.4),
        Position = pos + Vector3.new(0, 3, 0),
        Color = Color3.fromRGB(15, 20, 30),
        Material = Enum.Material.SmoothPlastic,
    })
    -- The kiosks line the north wall (z=-55). A Part's default "Front"
    -- normal points at -Z, which faces the wall behind the kiosk. We want
    -- the screen visible to the player walking through the lobby (looking
    -- in the -Z direction), so the GUI lives on the Back face (+Z normal).
    local sg = Instance.new("SurfaceGui")
    sg.Face = Enum.NormalId.Back
    sg.Parent = screen
    sg.CanvasSize = Vector2.new(700, 500)

    local titleLbl = Instance.new("TextLabel")
    titleLbl.Position = UDim2.fromOffset(20, 20)
    titleLbl.Size = UDim2.fromOffset(660, 60)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Font = Enum.Font.Code
    titleLbl.TextSize = 36
    titleLbl.TextColor3 = Color3.fromRGB(255, 180, 50)
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title
    titleLbl.Parent = sg

    local bodyLbl = Instance.new("TextLabel")
    bodyLbl.Position = UDim2.fromOffset(20, 100)
    bodyLbl.Size = UDim2.fromOffset(660, 380)
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.Font = Enum.Font.Code
    bodyLbl.TextSize = 18
    bodyLbl.TextColor3 = Color3.fromRGB(220, 230, 250)
    bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
    bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
    bodyLbl.TextWrapped = true
    bodyLbl.Text = body
    bodyLbl.Parent = sg
end

function Lobby.build(folder: Folder)
    -- Floor
    MapUtil.floor(folder, Vector3.new(0, 1, 0), Vector3.new(120, 1, 120),
        Color3.fromRGB(30, 35, 45))
    -- Spawn marker (visible)
    MapUtil.spawn(folder, "LobbySpawn", Lobby.spawnPoint, Color3.fromRGB(255, 180, 50))

    -- Outer walls
    MapUtil.wall(folder, Vector3.new(-60, 8, 0), Vector3.new(1, 16, 120))
    MapUtil.wall(folder, Vector3.new(60, 8, 0), Vector3.new(1, 16, 120))
    MapUtil.wall(folder, Vector3.new(0, 8, -60), Vector3.new(120, 16, 1))
    MapUtil.wall(folder, Vector3.new(0, 8, 60), Vector3.new(120, 16, 1))
    MapUtil.floor(folder, Vector3.new(0, 16, 0), Vector3.new(120, 1, 120))

    -- Title banner above spawn
    MapUtil.label(folder, "AEGIS: VEIL  —  LOBBY", Vector3.new(0, 14, 0),
        Color3.fromRGB(255, 180, 50))

    -- Three info kiosks along the north wall
    infoKiosk(folder, "STORY",
        "You are an AEGIS contract operative. Helix appears to manage Earth.\n" ..
        "It is not what it claims to be. The biomods you carry let you see\n" ..
        "through the perception filter that shapes what humans believe and want.\n\n" ..
        "Five missions. Five endings. Three save slots. Co-op up to four.",
        Vector3.new(-30, 1, -55))

    infoKiosk(folder, "MECHANICS",
        "* Skills (9, 4 ranks): Pistol, Rifle, Heavy, Melee, Computer,\n" ..
        "  Lockpicking, Medicine, Environmental, Swimming.\n" ..
        "* Biomods (10+, 4 levels): Cloak, Targeting, Speed, Combat\n" ..
        "  Strength, Regeneration, Veil Breaker, etc.\n" ..
        "* Weapons + 9 attachable mods.\n" ..
        "* Lockpick + Hack minigames; vote-majority co-op decisions;\n" ..
        "  tied votes resolved by duel.",
        Vector3.new(0, 1, -55))

    infoKiosk(folder, "FACTIONS",
        "* AEGIS — your starting employer. Compromised.\n" ..
        "* Helix — the bureaucracy that 'manages' Earth. Not what you think.\n" ..
        "* The Awakened — humans who've pierced the veil.\n" ..
        "* The Quorum — old human collaborators with Helix.\n\n" ..
        "Your alignment shifts based on your choices. Vendors gate by faction.",
        Vector3.new(30, 1, -55))

    -- Request Access terminal
    local reqTerm = MapUtil.part(folder, {
        Name = "RequestAccessTerminal",
        Size = Vector3.new(4, 5, 1),
        Position = Vector3.new(-20, 3, 50),
        Color = Color3.fromRGB(80, 200, 80),
        Material = Enum.Material.Neon,
    })
    reqTerm:SetAttribute("InteractionType", "RequestAccess")
    MapUtil.label(folder, "Request Team Access  [E]",
        Vector3.new(-20, 6, 50), Color3.fromRGB(200, 255, 200))

    -- Owner Console (visible to all but only usable by admins)
    local ownerTerm = MapUtil.part(folder, {
        Name = "OwnerConsole",
        Size = Vector3.new(4, 5, 1),
        Position = Vector3.new(20, 3, 50),
        Color = Color3.fromRGB(255, 60, 60),
        Material = Enum.Material.Neon,
    })
    ownerTerm:SetAttribute("InteractionType", "AdminConsole")
    MapUtil.label(folder, "Owner Console  [E]",
        Vector3.new(20, 6, 50), Color3.fromRGB(255, 200, 200))

    -- Vendor preview (read-only browsing of AEGIS Quartermaster stock)
    MapUtil.vendor(folder, "Sample Quartermaster", Vector3.new(-40, 3, 0),
        "AEGIS_QM", Color3.fromRGB(40, 50, 90))
    MapUtil.label(folder, "Vendor Preview", Vector3.new(-40, 8, 0))

    -- Demo entrance (left transition pad)
    MapUtil.transition(folder, "ToDemo", Vector3.new(-30, 4, 30),
        Vector3.new(8, 8, 4), "Demo")
    MapUtil.label(folder, "Play Demo Mission", Vector3.new(-30, 9, 30),
        Color3.fromRGB(120, 220, 120))

    -- Main game entrance (right transition pad — gated by AccessService)
    local gameTransition = MapUtil.transition(folder, "ToGame", Vector3.new(30, 4, 30),
        Vector3.new(8, 8, 4), "AegisTower")
    gameTransition:SetAttribute("RequiresAccess", true)
    MapUtil.label(folder, "Enter Game (access required)",
        Vector3.new(30, 9, 30), Color3.fromRGB(255, 180, 50))
end

return Lobby
