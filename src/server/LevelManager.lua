--!strict
-- Owns the currently-loaded map. Builds it, despawns it, handles transitions.
-- All players share one map at a time; a transition triggered by any player
-- reloads the map for everyone in the session. Gating predicates apply to
-- the *triggering* player, so an approved player can bring their squad
-- through together.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maps = require(script.Parent.Maps)
local WorldState = require(script.Parent.WorldState)
local MissionService = require(script.Parent.Services.MissionService)
local Remotes = require(Shared.Remotes)

-- Lazy-required to avoid circular dependency (AccessService doesn't need
-- LevelManager, but importing here at load time would force AccessService
-- to also be hot at first require, which is fine — keeping the lazy form
-- for symmetry with other lazy imports).
local _AccessService = nil
local function accessService()
    if not _AccessService then
        _AccessService = require(script.Parent.Services.AccessService)
    end
    return _AccessService
end

local _DemoStatsService = nil
local function demoStatsService()
    if not _DemoStatsService then
        _DemoStatsService = require(script.Parent.Services.DemoStatsService)
    end
    return _DemoStatsService
end

local LevelManager = {}

local current: string? = nil
local mapFolder: Folder? = nil
local ambientSound: Sound? = nil

-- Default lighting baseline — used by maps that don't declare their own
-- `ambient` table. Targets a late-afternoon, slightly overcast feel:
-- visible but moody, suitable for the cyberpunk tone.
local DEFAULT_LIGHTING = {
    Ambient = Color3.fromRGB(80, 80, 90),
    OutdoorAmbient = Color3.fromRGB(130, 130, 140),
    Brightness = 2.5,
    ClockTime = 17,
    FogColor = Color3.fromRGB(80, 85, 95),
    FogEnd = 1200,
    FogStart = 300,
}

local function applyLighting(props: { [string]: any }?)
    local merged: { [string]: any } = {}
    for k, v in pairs(DEFAULT_LIGHTING) do merged[k] = v end
    if props then
        for k, v in pairs(props) do merged[k] = v end
    end
    for k, v in pairs(merged) do
        (Lighting :: any)[k] = v
    end
end

local function applyMusic(soundId: string?)
    if ambientSound then
        ambientSound:Stop()
        ambientSound:Destroy()
        ambientSound = nil
    end
    if not soundId or soundId == "" then return end
    local s = Instance.new("Sound")
    s.Name = "AmbientMusic"
    s.SoundId = soundId
    s.Looped = true
    s.Volume = 0.4
    s.Parent = SoundService
    s:Play()
    ambientSound = s
end

local function clearWorld()
    if mapFolder then
        mapFolder:Destroy()
        mapFolder = nil
    end
    -- Despawn lingering enemies (they live directly in Workspace).
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("Faction") == "Hostile" then
            child:Destroy()
        end
    end
end

function LevelManager.currentMap(): string?
    return current
end

function LevelManager.load(mapId: string)
    local def = Maps[mapId]
    if not def then
        warn("[LevelManager] Unknown map:", mapId)
        return
    end
    clearWorld()
    local folder = Instance.new("Folder")
    folder.Name = "Map_" .. def.id
    folder.Parent = Workspace
    mapFolder = folder
    current = mapId
    def.build(folder)

    -- Per-map ambient: lighting + looping music. Maps may declare:
    --   def.ambient = {
    --     lighting = { Ambient = ..., FogColor = ..., ... },
    --     music = "rbxassetid://NUMBER",
    --   }
    -- Both are optional. Defaults are restored when not specified.
    local ambient = (def :: any).ambient
    applyLighting(ambient and ambient.lighting)
    applyMusic(ambient and ambient.music)

    for _, player in ipairs(Players:GetPlayers()) do
        LevelManager.placePlayer(player)
        LevelManager.applyArrivalObjectives(player, mapId)
    end

    print("[LevelManager] Loaded map:", def.displayName)
end

function LevelManager.applyArrivalObjectives(player: Player, mapId: string)
    if mapId == "PacificAnchor" then
        local state = WorldState.get(player)
        local pacifist = (state.counters.civiliansKilled or 0) == 0
            and (state.counters.kills or 0) <= 5
        local objectiveId = pacifist and "AnchorStealth" or "AnchorAssault"
        if not state.flags["startedAnchor"] then
            MissionService.start(player, objectiveId)
            WorldState.setFlag(player, "startedAnchor", true)
        end
    end
end

function LevelManager.placePlayer(player: Player)
    if not current then return end
    local def = Maps[current]
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
    hrp.CFrame = CFrame.new(def.spawnPoint + Vector3.new(0, 4, 0))
end

-- Per-transition gate. Returns (predicateExpr?, denyReason?, customCheck?).
-- The customCheck is a function(player) -> bool, used for non-WorldState
-- gates (like access).
type Gate = {
    predicate: string?,
    reason: string?,
    custom: ((Player) -> boolean)?,
}

local function gateFor(targetMap: string): Gate
    if targetMap == "AegisTower" then
        return {
            predicate = "!flag:defected",
            reason = "AEGIS has flagged you as a defector. Find another way.",
            custom = function(player)
                return accessService().hasAccess(player)
            end,
        }
    end
    return {}
end

function LevelManager.transitionPlayer(player: Player, targetMap: string, requiresAccess: boolean?)
    local gate = gateFor(targetMap)
    if gate.predicate and not WorldState.evaluate(player, gate.predicate) then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, gate.reason or "Transition denied.")
        return
    end
    if (requiresAccess or gate.custom) and gate.custom and not gate.custom(player) then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, "Access required. Use the Request Access terminal in the lobby.")
        return
    end

    -- Demo -> anywhere: flush demo stats summary to the leaving player
    -- BEFORE the map reloads so the UI fires while they're still focused.
    if current == "Demo" and targetMap ~= "Demo" then
        for _, p in ipairs(Players:GetPlayers()) do
            demoStatsService().flushFor(p)
        end
    end

    LevelManager.load(targetMap)

    -- Anywhere -> Demo: reset counters for everyone now in the map.
    if targetMap == "Demo" then
        for _, p in ipairs(Players:GetPlayers()) do
            demoStatsService().enter(p)
        end
    end
end

local function watchTransitions()
    task.spawn(function()
        while true do
            task.wait(0.5)
            if not mapFolder then continue end
            local fired = false
            for _, child in ipairs(mapFolder:GetChildren()) do
                if fired then break end
                if not child:IsA("BasePart") then continue end
                local kind = child:GetAttribute("InteractionType")
                if kind ~= "Transition" then continue end
                local target = child:GetAttribute("TargetMap")
                if typeof(target) ~= "string" then continue end
                local requiresAccess = child:GetAttribute("RequiresAccess") == true
                local region = child :: BasePart
                for _, player in ipairs(Players:GetPlayers()) do
                    local char = player.Character
                    if not char then continue end
                    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
                    if not hrp then continue end
                    if (hrp.Position - region.Position).Magnitude < math.max(region.Size.X, region.Size.Z) then
                        LevelManager.transitionPlayer(player, target, requiresAccess)
                        fired = true
                        break  -- map reloaded; iterators are stale; restart watch loop
                    end
                end
            end
        end
    end)
end

function LevelManager.init()
    LevelManager.load("Lobby")
    watchTransitions()
end

return LevelManager
