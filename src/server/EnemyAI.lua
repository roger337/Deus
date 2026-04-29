--!strict
-- Server-driven AI. Three kinds:
--   Human       - human grunt, ranged weapon, radio chatter (Hostile:* keys)
--   SecurityBot - wheeled, slow turn, laser, EMP-vulnerable (Bot:* keys)
--   SpiderBot   - small, fast, melee zap (Spider:* + Bot:disabled keys)
--
-- Spawn entrypoints:
--   EnemyAI.spawn(positionVec3, weaponId)             -- legacy: human grunt
--   EnemyAI.spawn({ position=..., kind=..., ... })    -- options table
-- Then call EnemyAI.run(model).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local CombatService = require(script.Parent.Services.CombatService)
local AugService = require(script.Parent.Services.AugService)
local VoiceService = require(script.Parent.Services.VoiceService)
local Weapons = require(Shared.Config.Weapons)

local EnemyAI = {}

local ATTACK_COOLDOWN_HUMAN = 1.2
local ATTACK_COOLDOWN_BOT = 0.8
local SPIDER_ATTACK_COOLDOWN = 1.0

-- Per-kind tuning + voice key mapping. Keep declarative so adding a new kind
-- means a new entry here, not new branches in the loop.
type KindCfg = {
    -- vision
    viewDeg: number,
    viewDist: number,
    -- movement
    patrolSpeed: number,
    chaseSpeed: number,
    -- voice key dispatch ("" = no bark for this event)
    barks: { [string]: any },  -- spotted: string, lost: string, wounded: string?, death: string, idle: {string}, idleProb: number
    -- combat
    attackCooldown: number,
    -- visuals
    bodyColor: Color3,
    healthLabel: string,
}

local KIND_CFG: { [string]: KindCfg } = {
    Human = {
        viewDeg = 100, viewDist = 80,
        patrolSpeed = 8, chaseSpeed = 16,
        attackCooldown = ATTACK_COOLDOWN_HUMAN,
        bodyColor = Color3.fromRGB(60, 60, 90),
        healthLabel = "HOSTILE",
        barks = {
            spotted = "Hostile:spotted",
            lost = "Hostile:lostTarget",
            wounded = "Hostile:wounded",
            death = "Hostile:death",
            idle = { "Hostile:idle1", "Hostile:idle2", "Hostile:idle3", "Hostile:idle4" },
            idleProb = 0.15,
        },
    },
    SecurityBot = {
        viewDeg = 140, viewDist = 100,
        patrolSpeed = 6, chaseSpeed = 9,
        attackCooldown = ATTACK_COOLDOWN_BOT,
        bodyColor = Color3.fromRGB(150, 30, 30),
        healthLabel = "BOT",
        barks = {
            spotted = "Bot:alert",
            lost = "Bot:lost",
            wounded = nil,
            death = "Bot:disabled",
            idle = { "Bot:scan" },
            idleProb = 0.30,
        },
    },
    SpiderBot = {
        viewDeg = 180, viewDist = 60,
        patrolSpeed = 12, chaseSpeed = 22,
        attackCooldown = SPIDER_ATTACK_COOLDOWN,
        bodyColor = Color3.fromRGB(40, 40, 50),
        healthLabel = "SPIDER",
        barks = {
            spotted = "Spider:strike",
            lost = nil,
            wounded = nil,
            death = "Bot:disabled",
            idle = { "Spider:warble" },
            idleProb = 0.30,
        },
    },
}

local function cfgFor(model: Model): KindCfg
    local kind = model:GetAttribute("Kind") or "Human"
    return KIND_CFG[kind] or KIND_CFG.Human
end

-- Vision -----------------------------------------------------------------

local function inViewCone(from: CFrame, target: Vector3, distance: number, fovDeg: number): boolean
    local toTarget = target - from.Position
    local dist = toTarget.Magnitude
    if dist > distance then return false end
    local fwd = from.LookVector
    local angle = math.deg(math.acos(math.clamp(fwd:Dot(toTarget.Unit), -1, 1)))
    return angle <= fovDeg / 2
end

local function lineOfSight(from: Vector3, to: Vector3, ignore: Instance): boolean
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { ignore }
    local r = Workspace:Raycast(from, (to - from), params)
    return r == nil
end

local function findTargetPlayer(enemy: Model, cfg: KindCfg): (Player?, Vector3?)
    local hrp = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return nil, nil end

    local closest: Player? = nil
    local closestDist = cfg.viewDist + 1
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if not char then continue end
        local pHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not pHrp then continue end
        if not inViewCone(hrp.CFrame, pHrp.Position, cfg.viewDist, cfg.viewDeg) then continue end
        if not lineOfSight(hrp.Position, pHrp.Position, enemy) then continue end

        -- Cloak only fools humans. Bots use thermal/IR — full visibility.
        local kind = enemy:GetAttribute("Kind") or "Human"
        if kind == "Human" then
            local cloak = AugService.magnitude(player, "Cloak")
            if cloak and math.random() < (1 - cloak) then continue end
        end

        local d = (pHrp.Position - hrp.Position).Magnitude
        if d < closestDist then
            closestDist = d
            closest = player
        end
    end
    if closest and closest.Character then
        local pHrp = closest.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if pHrp then
            return closest, pHrp.Position
        end
    end
    return nil, nil
end

-- Combat -----------------------------------------------------------------

local function tracerPart(origin: Vector3, dir: Vector3, len: number, color: Color3): Part
    local tracer = Instance.new("Part")
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.Size = Vector3.new(0.2, 0.2, len)
    tracer.CFrame = CFrame.lookAt(origin, origin + dir.Unit * 10) * CFrame.new(0, 0, -tracer.Size.Z / 2)
    tracer.Color = color
    tracer.Material = Enum.Material.Neon
    tracer.Transparency = 0.4
    tracer.Parent = Workspace
    return tracer
end

local function shootHuman(enemy: Model, targetPos: Vector3, weaponId: string)
    local hrp = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end
    local def = Weapons[weaponId] or Weapons.AssaultRifle
    local origin = hrp.Position + Vector3.new(0, 1, 0)
    local dir = (targetPos - origin).Unit + Vector3.new(
        (math.random() - 0.5) * def.spread * 4,
        (math.random() - 0.5) * def.spread * 4,
        (math.random() - 0.5) * def.spread * 4
    )
    local tracer = tracerPart(origin, dir, math.min(def.range, 100), Color3.fromRGB(255, 220, 100))
    task.delay(0.05, function() tracer:Destroy() end)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { enemy }
    local hit = Workspace:Raycast(origin, dir.Unit * def.range, params)
    if hit and hit.Instance then
        local model = hit.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local player = Players:GetPlayerFromCharacter(model)
            if player then
                CombatService.applyDamageToPlayer(player, def.damage, "ballistic")
            end
        end
    end
end

local function shootLaser(enemy: Model, targetPos: Vector3)
    local hrp = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end
    local origin = hrp.Position + Vector3.new(0, 1.5, 0)
    local dir = (targetPos - origin).Unit
    local tracer = tracerPart(origin, dir, 120, Color3.fromRGB(255, 30, 30))
    tracer.Size = Vector3.new(0.3, 0.3, tracer.Size.Z)
    task.delay(0.08, function() tracer:Destroy() end)

    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { enemy }
    local hit = Workspace:Raycast(origin, dir * 120, params)
    if hit and hit.Instance then
        local model = hit.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local player = Players:GetPlayerFromCharacter(model)
            if player then
                CombatService.applyDamageToPlayer(player, 12, "ballistic")
            end
        end
    end
end

local function spiderZap(enemy: Model, targetPos: Vector3)
    local hrp = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end
    -- Only zap if very close (melee).
    if (hrp.Position - targetPos).Magnitude > 7 then return end

    local arc = Instance.new("Part")
    arc.Anchored = true
    arc.CanCollide = false
    arc.Size = Vector3.new(0.5, 0.5, (hrp.Position - targetPos).Magnitude)
    arc.CFrame = CFrame.lookAt(hrp.Position, targetPos) * CFrame.new(0, 0, -arc.Size.Z / 2)
    arc.Color = Color3.fromRGB(120, 220, 255)
    arc.Material = Enum.Material.Neon
    arc.Transparency = 0.3
    arc.Parent = Workspace
    task.delay(0.2, function() arc:Destroy() end)

    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if not char then continue end
        local pHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if pHrp and (pHrp.Position - hrp.Position).Magnitude <= 7 then
            CombatService.applyDamageToPlayer(player, 18, "emp")
        end
    end
end

-- Movement ---------------------------------------------------------------

local function patrolStep(enemy: Model, cfg: KindCfg)
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local hrp = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end
    local target = hrp.Position + Vector3.new(
        (math.random() - 0.5) * 60,
        0,
        (math.random() - 0.5) * 60
    )
    hum.WalkSpeed = cfg.patrolSpeed
    hum:MoveTo(target)
end

local function chaseAndAttack(enemy: Model, cfg: KindCfg, lastSeen: Vector3)
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = cfg.chaseSpeed
    hum:MoveTo(lastSeen)
    local hrp = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if hrp then
        local look = (lastSeen - hrp.Position) * Vector3.new(1, 0, 1)
        if look.Magnitude > 0.1 then
            hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + look)
        end
    end

    local kind = enemy:GetAttribute("Kind") or "Human"
    if kind == "SecurityBot" then
        shootLaser(enemy, lastSeen)
    elseif kind == "SpiderBot" then
        spiderZap(enemy, lastSeen)
    else
        local weaponId = enemy:GetAttribute("Weapon") or "AssaultRifle"
        shootHuman(enemy, lastSeen, weaponId :: string)
    end
end

-- Spawn helpers ---------------------------------------------------------

local function buildHuman(opts): Model
    local position: Vector3 = opts.position
    local model = Instance.new("Model")
    model.Name = opts.name or "Hostile_Grunt"
    model:SetAttribute("Faction", "Hostile")
    model:SetAttribute("Kind", "Human")
    model:SetAttribute("Stamina", 100)
    model:SetAttribute("Weapon", opts.weapon or "AssaultRifle")

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Position = position
    hrp.Color = Color3.fromRGB(80, 30, 30)
    hrp.Parent = model

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Color = KIND_CFG.Human.bodyColor
    torso.Position = position
    torso.Parent = model
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = hrp; weld.Part1 = torso; weld.Parent = hrp

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(1.2, 1.2, 1.2)
    head.Color = Color3.fromRGB(180, 150, 130)
    head.Position = position + Vector3.new(0, 1.6, 0)
    head.Parent = model
    local hweld = Instance.new("WeldConstraint")
    hweld.Part0 = torso; hweld.Part1 = head; hweld.Parent = torso

    local legs = Instance.new("Part")
    legs.Name = "Legs"
    legs.Size = Vector3.new(2, 2, 1)
    legs.Color = Color3.fromRGB(40, 40, 60)
    legs.Position = position + Vector3.new(0, -2, 0)
    legs.Parent = model
    local lweld = Instance.new("WeldConstraint")
    lweld.Part0 = torso; lweld.Part1 = legs; lweld.Parent = torso

    return model
end

local function buildSecurityBot(opts): Model
    local position: Vector3 = opts.position
    local model = Instance.new("Model")
    model.Name = opts.name or "SecurityBot"
    model:SetAttribute("Faction", "Hostile")
    model:SetAttribute("Kind", "SecurityBot")

    -- Wheeled base.
    local base = Instance.new("Part")
    base.Name = "HumanoidRootPart"
    base.Size = Vector3.new(4, 1.5, 4)
    base.Position = position
    base.Color = Color3.fromRGB(60, 60, 70)
    base.Material = Enum.Material.Metal
    base.Parent = model

    -- Body cylinder.
    local body = Instance.new("Part")
    body.Name = "Body"
    body.Shape = Enum.PartType.Cylinder
    body.Size = Vector3.new(3, 3, 3)
    body.CFrame = CFrame.new(position + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90))
    body.Color = KIND_CFG.SecurityBot.bodyColor
    body.Material = Enum.Material.Metal
    body.Parent = model
    local bw = Instance.new("WeldConstraint")
    bw.Part0 = base; bw.Part1 = body; bw.Parent = base

    -- "Head" sensor cluster.
    local head = Instance.new("Part")
    head.Name = "Head"
    head.Shape = Enum.PartType.Ball
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.Position = position + Vector3.new(0, 3.5, 0)
    head.Color = Color3.fromRGB(40, 40, 50)
    head.Material = Enum.Material.Metal
    head.Parent = model
    local hw = Instance.new("WeldConstraint")
    hw.Part0 = body; hw.Part1 = head; hw.Parent = body

    -- Sensor light.
    local sensor = Instance.new("Part")
    sensor.Size = Vector3.new(0.6, 0.6, 0.6)
    sensor.Position = position + Vector3.new(0, 3.5, 0.8)
    sensor.Color = Color3.fromRGB(255, 50, 50)
    sensor.Material = Enum.Material.Neon
    sensor.Parent = model
    local sw = Instance.new("WeldConstraint")
    sw.Part0 = head; sw.Part1 = sensor; sw.Parent = head
    local pl = Instance.new("PointLight")
    pl.Color = Color3.fromRGB(255, 50, 50)
    pl.Range = 12
    pl.Brightness = 1.5
    pl.Parent = sensor

    return model
end

local function buildSpiderBot(opts): Model
    local position: Vector3 = opts.position
    local model = Instance.new("Model")
    model.Name = opts.name or "SpiderBot"
    model:SetAttribute("Faction", "Hostile")
    model:SetAttribute("Kind", "SpiderBot")

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2.5, 0.8, 2.5)
    hrp.Position = position
    hrp.Color = KIND_CFG.SpiderBot.bodyColor
    hrp.Material = Enum.Material.Metal
    hrp.Parent = model

    -- Dome
    local dome = Instance.new("Part")
    dome.Name = "Head"
    dome.Shape = Enum.PartType.Ball
    dome.Size = Vector3.new(2, 2, 2)
    dome.Position = position + Vector3.new(0, 0.8, 0)
    dome.Color = Color3.fromRGB(20, 20, 30)
    dome.Material = Enum.Material.Metal
    dome.Parent = model
    local dw = Instance.new("WeldConstraint")
    dw.Part0 = hrp; dw.Part1 = dome; dw.Parent = hrp

    -- 4 legs as small parts
    for i = 1, 4 do
        local angle = (i - 1) * (math.pi / 2)
        local leg = Instance.new("Part")
        leg.Size = Vector3.new(0.4, 1.6, 0.4)
        leg.CFrame = CFrame.new(position + Vector3.new(math.cos(angle) * 1.6, -0.6, math.sin(angle) * 1.6))
            * CFrame.Angles(math.rad(20), -angle, math.rad(20))
        leg.Color = Color3.fromRGB(20, 20, 30)
        leg.Material = Enum.Material.Metal
        leg.Parent = model
        local w = Instance.new("WeldConstraint")
        w.Part0 = hrp; w.Part1 = leg; w.Parent = hrp
    end

    -- Eye
    local eye = Instance.new("Part")
    eye.Size = Vector3.new(0.4, 0.4, 0.4)
    eye.Position = position + Vector3.new(0, 0.8, 0.9)
    eye.Color = Color3.fromRGB(120, 220, 255)
    eye.Material = Enum.Material.Neon
    eye.Parent = model
    local ew = Instance.new("WeldConstraint")
    ew.Part0 = dome; ew.Part1 = eye; ew.Parent = dome
    local pl = Instance.new("PointLight")
    pl.Color = Color3.fromRGB(120, 220, 255)
    pl.Range = 8
    pl.Brightness = 1
    pl.Parent = eye

    return model
end

local function attachHumanoid(model: Model, cfg: KindCfg, healthMaxOverride: number?)
    local hum = Instance.new("Humanoid")
    hum.MaxHealth = healthMaxOverride or 100
    hum.Health = hum.MaxHealth
    hum.WalkSpeed = cfg.patrolSpeed
    hum.Parent = model

    local primary = model:FindFirstChild("HumanoidRootPart") :: BasePart?
    if primary then
        model.PrimaryPart = primary
    end
end

local function attachLabel(model: Model, cfg: KindCfg)
    local head = model:FindFirstChild("Head") :: BasePart?
    if not head then return end
    local bb = Instance.new("BillboardGui")
    bb.Adornee = head
    bb.Size = UDim2.new(0, 80, 0, 16)
    bb.StudsOffset = Vector3.new(0, 1.5, 0)
    bb.AlwaysOnTop = true
    bb.Parent = head
    local lbl = Instance.new("TextLabel")
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(1, 0, 1, 0)
    lbl.TextColor3 = Color3.fromRGB(255, 80, 80)
    lbl.Font = Enum.Font.Code
    lbl.TextScaled = true
    lbl.Text = cfg.healthLabel
    lbl.Parent = bb
end

-- Public spawn API. Accepts either a Vector3 (legacy) or an options table.
function EnemyAI.spawn(opts_or_pos: any, weaponId: string?): Model
    local opts: { position: Vector3, kind: string?, weapon: string?, name: string?, health: number? }
    if typeof(opts_or_pos) == "Vector3" then
        opts = { position = opts_or_pos, weapon = weaponId, kind = "Human" }
    else
        opts = opts_or_pos
        opts.kind = opts.kind or "Human"
    end

    local cfg = KIND_CFG[opts.kind] or KIND_CFG.Human
    local model: Model
    if opts.kind == "SecurityBot" then
        model = buildSecurityBot(opts)
    elseif opts.kind == "SpiderBot" then
        model = buildSpiderBot(opts)
    else
        model = buildHuman(opts)
    end

    local defaultHealth = if opts.kind == "SecurityBot" then 200
        elseif opts.kind == "SpiderBot" then 50
        else 100
    attachHumanoid(model, cfg, opts.health or defaultHealth)
    attachLabel(model, cfg)

    model.Parent = Workspace
    return model
end

-- Run loop. Same state machine for all kinds; bark keys + attack action are
-- dispatched via cfg.barks and the kind attribute.
function EnemyAI.run(enemy: Model)
    local cfg = cfgFor(enemy)
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local state = "Patrol"
    local lastSeen: Vector3? = nil
    local lastFire = 0
    local nextPatrol = 0

    task.spawn(function()
        while enemy.Parent and hum.Health > 0 do
            task.wait(0.25)
            if enemy:GetAttribute("KnockedOut") then continue end
            local player, pos = findTargetPlayer(enemy, cfg)
            if player and pos then
                if state ~= "Combat" and cfg.barks.spotted then
                    VoiceService.bark(enemy, cfg.barks.spotted)
                end
                state = "Combat"
                lastSeen = pos
                if os.clock() - lastFire > cfg.attackCooldown then
                    lastFire = os.clock()
                    chaseAndAttack(enemy, cfg, pos)
                end
            elseif lastSeen and state == "Combat" then
                state = "Suspicious"
                if cfg.barks.lost then
                    VoiceService.bark(enemy, cfg.barks.lost)
                end
                hum:MoveTo(lastSeen)
                task.wait(2)
                lastSeen = nil
                state = "Patrol"
            elseif os.clock() > nextPatrol then
                nextPatrol = os.clock() + math.random(3, 6)
                patrolStep(enemy, cfg)
                -- Idle bark at random.
                if cfg.barks.idle and #cfg.barks.idle > 0 and math.random() < (cfg.barks.idleProb or 0) then
                    local key = cfg.barks.idle[math.random(1, #cfg.barks.idle)]
                    VoiceService.bark(enemy, key)
                end
            end
        end
    end)

    hum.HealthChanged:Connect(function(hp)
        if cfg.barks.wounded and hp > 0 and hp < hum.MaxHealth * 0.5 then
            VoiceService.bark(enemy, cfg.barks.wounded)
        end
    end)

    hum.Died:Connect(function()
        if cfg.barks.death then
            VoiceService.bark(enemy, cfg.barks.death)
        end
        task.delay(10, function() enemy:Destroy() end)
    end)
end

-- Convenience constructors used by maps.
function EnemyAI.spawnSecurityBot(position: Vector3): Model
    return EnemyAI.spawn({ position = position, kind = "SecurityBot" })
end

function EnemyAI.spawnSpiderBot(position: Vector3): Model
    return EnemyAI.spawn({ position = position, kind = "SpiderBot" })
end

return EnemyAI
