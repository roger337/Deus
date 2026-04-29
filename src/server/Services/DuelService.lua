--!strict
-- Tie-breaker duels for co-op votes.
--
-- When VoteService.resolve detects two or more options with the same max
-- vote count, it hands off to DuelService.start. We push the tied voters
-- into a small floating arena, flip friendly fire on FOR THEM ONLY, and
-- watch humanoid health. When all players on one side are "down" (HP <= 5,
-- which we clamp at 1 to avoid actual death + auto-respawn), the surviving
-- side's option wins the original vote.
--
-- Players who voted for non-tied options spectate from their original
-- positions; they take no damage and cannot deal damage to duelers.
--
-- Solo and small lobbies handle gracefully: with one player, no tie is
-- possible (the tally has at most one max). With two players voting
-- against each other, the duel is 1v1.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)

local DuelService = {}

-- Arena far above any playable map.
local ARENA_ORIGIN = Vector3.new(0, 2000, 0)
local SIDE_OFFSET = 24

type Duel = {
    voteId: string,
    tiedOptions: { string },
    sides: { [string]: { Player } },          -- option id -> participants
    spectators: { Player },
    preDuelPositions: { [Player]: CFrame },
    downPlayers: { [Player]: boolean },
    finished: boolean,
    onResolve: (winnerOptionId: string) -> (),
}

local active: Duel? = nil
local arenaFolder: Folder? = nil

local function buildArena()
    if arenaFolder and arenaFolder.Parent then return end
    local f = Instance.new("Folder")
    f.Name = "DuelArena"
    f.Parent = Workspace

    local function part(props: { [string]: any })
        local p = Instance.new("Part")
        p.Anchored = true
        p.TopSurface = Enum.SurfaceType.Smooth
        p.BottomSurface = Enum.SurfaceType.Smooth
        for k, v in pairs(props) do (p :: any)[k] = v end
        p.Parent = f
        return p
    end

    -- Floor
    part({
        Name = "Floor",
        Size = Vector3.new(80, 1, 80),
        Position = ARENA_ORIGIN,
        Color = Color3.fromRGB(40, 40, 50),
        Material = Enum.Material.Slate,
    })
    -- Center stripe
    part({
        Size = Vector3.new(0.5, 1.1, 80),
        Position = ARENA_ORIGIN + Vector3.new(0, 0.05, 0),
        Color = Color3.fromRGB(220, 60, 60),
        Material = Enum.Material.Neon,
    })
    -- Walls (closed dome to keep duelers in)
    for _, side in ipairs({ Vector3.new(40, 8, 0), Vector3.new(-40, 8, 0), Vector3.new(0, 8, 40), Vector3.new(0, 8, -40) }) do
        local size = Vector3.new(side.X == 0 and 80 or 1, 16, side.Z == 0 and 80 or 1)
        part({
            Size = size,
            Position = ARENA_ORIGIN + side,
            Color = Color3.fromRGB(30, 30, 38),
            Material = Enum.Material.Concrete,
            Transparency = 0.4,
        })
    end
    -- Roof (low ceiling stops fly-aways)
    part({
        Size = Vector3.new(80, 1, 80),
        Position = ARENA_ORIGIN + Vector3.new(0, 30, 0),
        Color = Color3.fromRGB(30, 30, 38),
        Material = Enum.Material.Concrete,
        Transparency = 0.7,
    })
    arenaFolder = f
end

local function spawnPosForOption(optionIndex: number): Vector3
    -- Up to 4 sides spread around the arena. Two-way ties use index 1+2.
    local angles = { 0, math.pi, math.pi / 2, -math.pi / 2 }
    local angle = angles[optionIndex] or 0
    return ARENA_ORIGIN + Vector3.new(math.cos(angle) * SIDE_OFFSET, 1, math.sin(angle) * SIDE_OFFSET)
end

local function teleport(player: Player, pos: Vector3)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end
    hrp.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0))
end

local function teleportBack(player: Player, cframe: CFrame)
    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return end
    hrp.CFrame = cframe
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.Health = hum.MaxHealth
    end
end

local function notifyAll(text: string)
    local ev = Remotes.get("Notify") :: RemoteEvent
    for _, p in ipairs(Players:GetPlayers()) do
        ev:FireClient(p, text)
    end
end

function DuelService.isInDuel(player: Player): boolean
    if not active or active.finished then return false end
    for _, side in pairs(active.sides) do
        for _, p in ipairs(side) do
            if p == player then return true end
        end
    end
    return false
end

-- Allow damage between two players if and only if they are on opposing
-- sides of the same active duel. CombatService consults this for FF.
function DuelService.canDamageBetween(attacker: Player, victim: Player): boolean
    if not active or active.finished then return false end
    local attackerSide: string? = nil
    local victimSide: string? = nil
    for optId, side in pairs(active.sides) do
        for _, p in ipairs(side) do
            if p == attacker then attackerSide = optId end
            if p == victim then victimSide = optId end
        end
    end
    return attackerSide ~= nil and victimSide ~= nil and attackerSide ~= victimSide
end

local function findTiedOptions(tally: { [string]: number }, options): { string }
    local maxCount = 0
    for _, opt in ipairs(options) do
        local c = tally[opt.id] or 0
        if c > maxCount then maxCount = c end
    end
    if maxCount == 0 then return {} end
    local tied = {}
    for _, opt in ipairs(options) do
        if (tally[opt.id] or 0) == maxCount then
            table.insert(tied, opt.id)
        end
    end
    return tied
end

local function watchHealth()
    if not active then return end
    while active and not active.finished do
        task.wait(0.25)
        if not active then return end
        local sideStanding: { [string]: boolean } = {}
        for optId, side in pairs(active.sides) do
            sideStanding[optId] = false
            for _, p in ipairs(side) do
                if active.downPlayers[p] then continue end
                local char = p.Character
                if not char then continue end
                local hum = char:FindFirstChildOfClass("Humanoid") :: Humanoid?
                if not hum then continue end
                if hum.Health <= 5 then
                    -- knock down: clamp at 1, freeze.
                    hum.Health = 1
                    hum.WalkSpeed = 0
                    hum.JumpPower = 0
                    active.downPlayers[p] = true
                    notifyAll(string.format("%s is down.", p.Name))
                else
                    sideStanding[optId] = true
                end
            end
        end
        local sidesUp = 0
        local lastUp: string? = nil
        for optId, up in pairs(sideStanding) do
            if up then sidesUp += 1; lastUp = optId end
        end
        if sidesUp <= 1 then
            -- One side standing (or all down — fallback to first tied).
            local winner = lastUp or active.tiedOptions[1]
            DuelService.finish(winner)
            return
        end
    end
end

function DuelService.finish(winnerOptionId: string)
    if not active or active.finished then return end
    active.finished = true

    local notify = Remotes.get("Notify") :: RemoteEvent
    for _, p in ipairs(Players:GetPlayers()) do
        notify:FireClient(p, string.format("Duel resolved: %s wins.", winnerOptionId))
    end

    -- Restore everyone.
    for _, side in pairs(active.sides) do
        for _, p in ipairs(side) do
            local cf = active.preDuelPositions[p]
            if cf then teleportBack(p, cf) end
        end
    end

    local cb = active.onResolve
    active = nil
    if cb then cb(winnerOptionId) end
end

function DuelService.start(voteId: string, votes: { [number]: string }, options, onResolve: (string) -> ())
    -- Compute tally + tied options.
    local tally: { [string]: number } = {}
    for _, opt in ipairs(options) do
        tally[opt.id] = 0
    end
    for _, optId in pairs(votes) do
        tally[optId] = (tally[optId] or 0) + 1
    end
    local tied = findTiedOptions(tally, options)
    if #tied <= 1 then
        -- No tie — caller already handled, but defensive.
        onResolve(tied[1] or options[1].id)
        return
    end

    -- Build sides.
    local sides: { [string]: { Player } } = {}
    for _, optId in ipairs(tied) do sides[optId] = {} end
    for userId, optId in pairs(votes) do
        if sides[optId] then
            local p = Players:GetPlayerByUserId(userId)
            if p then table.insert(sides[optId], p) end
        end
    end
    -- Drop empty sides (someone whose vote was tied may have left).
    local nonEmpty: { string } = {}
    for _, optId in ipairs(tied) do
        if #sides[optId] > 0 then table.insert(nonEmpty, optId) end
    end
    if #nonEmpty <= 1 then
        onResolve(nonEmpty[1] or tied[1])
        return
    end

    buildArena()

    active = {
        voteId = voteId,
        tiedOptions = nonEmpty,
        sides = sides,
        spectators = {},
        preDuelPositions = {},
        downPlayers = {},
        finished = false,
        onResolve = onResolve,
    }

    -- Save positions and teleport into arena.
    notifyAll("VOTE TIED — duelers report to the arena.")
    for i, optId in ipairs(nonEmpty) do
        local pos = spawnPosForOption(i)
        for _, p in ipairs(sides[optId]) do
            local char = p.Character
            if char then
                local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
                if hrp then
                    active.preDuelPositions[p] = hrp.CFrame
                end
            end
            teleport(p, pos)
        end
    end

    task.spawn(watchHealth)
end

return DuelService
