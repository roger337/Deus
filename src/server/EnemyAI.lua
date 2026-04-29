--!strict
-- Server-driven AI for NSF grunts. State machine: Patrol -> Suspicious -> Alert -> Combat.
-- Vision is a forward cone; hearing is a radius (modified by player's Run Silent aug).

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local PathfindingService = game:GetService("PathfindingService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local CombatService = require(script.Parent.Services.CombatService)
local AugService = require(script.Parent.Services.AugService)
local Weapons = require(Shared.Config.Weapons)

local EnemyAI = {}

local VIEW_DEGREES = 100
local VIEW_DIST = 80
local HEAR_DIST = 30
local ATTACK_COOLDOWN = 1.2
local PATROL_SPEED = 8
local CHASE_SPEED = 16

local function inViewCone(from: CFrame, target: Vector3, distance: number): boolean
    local toTarget = target - from.Position
    local dist = toTarget.Magnitude
    if dist > distance then return false end
    local fwd = from.LookVector
    local angle = math.deg(math.acos(math.clamp(fwd:Dot(toTarget.Unit), -1, 1)))
    return angle <= VIEW_DEGREES / 2
end

local function lineOfSight(from: Vector3, to: Vector3, ignore: Instance): boolean
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { ignore }
    local r = Workspace:Raycast(from, (to - from), params)
    return r == nil
end

local function findTargetPlayer(enemy: Model): (Player?, Vector3?)
    local hrp = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return nil, nil end

    local closest: Player? = nil
    local closestDist = VIEW_DIST + 1
    for _, player in ipairs(Players:GetPlayers()) do
        local char = player.Character
        if not char then continue end
        local pHrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not pHrp then continue end
        if not inViewCone(hrp.CFrame, pHrp.Position, VIEW_DIST) then continue end
        if not lineOfSight(hrp.Position, pHrp.Position, enemy) then continue end

        -- Cloak aug: invisibility quality multiplier.
        local cloak = AugService.magnitude(player, "Cloak")
        if cloak and cloak <= 0 then continue end -- perfect cloak: invisible
        if cloak and math.random() < (1 - cloak) then continue end

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

local function shootAt(enemy: Model, targetPos: Vector3, weaponId: string)
    local hrp = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end
    local def = Weapons[weaponId] or Weapons.AssaultRifle
    -- Visualize tracer
    local origin = hrp.Position + Vector3.new(0, 1, 0)
    local dir = (targetPos - origin).Unit + Vector3.new(
        (math.random() - 0.5) * def.spread * 4,
        (math.random() - 0.5) * def.spread * 4,
        (math.random() - 0.5) * def.spread * 4
    )
    local tracer = Instance.new("Part")
    tracer.Anchored = true
    tracer.CanCollide = false
    tracer.Size = Vector3.new(0.2, 0.2, math.min(def.range, 100))
    tracer.CFrame = CFrame.lookAt(origin, origin + dir.Unit * 10) * CFrame.new(0, 0, -tracer.Size.Z / 2)
    tracer.Color = Color3.fromRGB(255, 220, 100)
    tracer.Material = Enum.Material.Neon
    tracer.Transparency = 0.4
    tracer.Parent = Workspace
    task.delay(0.05, function() tracer:Destroy() end)

    -- Damage with raycast
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { enemy }
    local hit = Workspace:Raycast(origin, dir.Unit * def.range, params)
    if hit and hit.Instance then
        local model = hit.Instance:FindFirstAncestorOfClass("Model")
        if model then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local player = Players:GetPlayerFromCharacter(model)
            if player and hum then
                CombatService.applyDamageToPlayer(player, def.damage, "ballistic")
            end
        end
    end
end

local function patrolStep(enemy: Model)
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local hrp = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end
    -- Wander to a random nearby spot.
    local target = hrp.Position + Vector3.new(
        (math.random() - 0.5) * 60,
        0,
        (math.random() - 0.5) * 60
    )
    hum.WalkSpeed = PATROL_SPEED
    hum:MoveTo(target)
end

local function chaseAndFire(enemy: Model, lastSeen: Vector3, weaponId: string)
    local hum = enemy:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.WalkSpeed = CHASE_SPEED
    hum:MoveTo(lastSeen)
    local hrp = enemy:FindFirstChild("HumanoidRootPart") :: BasePart?
    if hrp then
        -- face the target so vision cone tracks
        local look = (lastSeen - hrp.Position) * Vector3.new(1, 0, 1)
        if look.Magnitude > 0.1 then
            hrp.CFrame = CFrame.lookAt(hrp.Position, hrp.Position + look)
        end
    end
    shootAt(enemy, lastSeen, weaponId)
end

function EnemyAI.spawn(position: Vector3, weaponId: string?): Model
    local model = Instance.new("Model")
    model.Name = "NSF_Grunt"
    model:SetAttribute("Faction", "NSF")
    model:SetAttribute("Stamina", 100)
    model:SetAttribute("Weapon", weaponId or "AssaultRifle")

    local hrp = Instance.new("Part")
    hrp.Name = "HumanoidRootPart"
    hrp.Size = Vector3.new(2, 2, 1)
    hrp.Position = position
    hrp.Color = Color3.fromRGB(80, 30, 30)
    hrp.Parent = model

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Color = Color3.fromRGB(60, 60, 90)
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

    local hum = Instance.new("Humanoid")
    hum.MaxHealth = 100
    hum.Health = 100
    hum.WalkSpeed = PATROL_SPEED
    hum.Parent = model

    model.PrimaryPart = hrp
    model.Parent = Workspace

    -- Health label
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
    lbl.Text = "NSF"
    lbl.Parent = bb

    return model
end

function EnemyAI.run(enemy: Model)
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
            local player, pos = findTargetPlayer(enemy)
            local weaponId = enemy:GetAttribute("Weapon") or "AssaultRifle"
            if player and pos then
                state = "Combat"
                lastSeen = pos
                if os.clock() - lastFire > ATTACK_COOLDOWN then
                    lastFire = os.clock()
                    chaseAndFire(enemy, pos, weaponId :: string)
                end
            elseif lastSeen and state == "Combat" then
                state = "Suspicious"
                hum:MoveTo(lastSeen)
                task.wait(2)
                lastSeen = nil
                state = "Patrol"
            elseif os.clock() > nextPatrol then
                nextPatrol = os.clock() + math.random(3, 6)
                patrolStep(enemy)
            end
        end
    end)

    hum.Died:Connect(function()
        task.delay(10, function() enemy:Destroy() end)
    end)
end

return EnemyAI
