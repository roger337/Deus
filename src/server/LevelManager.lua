--!strict
-- Owns the currently-loaded map. Builds it, despawns it, and handles transitions
-- when players walk through transition triggers.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Maps = require(script.Parent.Maps)
local WorldState = require(script.Parent.WorldState)
local MissionService = require(script.Parent.Services.MissionService)
local Remotes = require(Shared.Remotes)

local LevelManager = {}

local current: string? = nil
local mapFolder: Folder? = nil

local function clearWorld()
    if mapFolder then
        mapFolder:Destroy()
        mapFolder = nil
    end
    -- Despawn lingering enemies (they live directly in Workspace).
    for _, child in ipairs(Workspace:GetChildren()) do
        if child:IsA("Model") and child:GetAttribute("Faction") == "NSF" then
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

    -- Teleport everyone to the spawn point and trigger arrival objectives.
    for _, player in ipairs(Players:GetPlayers()) do
        LevelManager.placePlayer(player)
        LevelManager.applyArrivalObjectives(player, mapId)
    end

    print("[LevelManager] Loaded map:", def.displayName)
end

-- Some maps auto-start an objective on arrival, with the variant chosen
-- based on prior behavior. This is where "objectives change based on prior
-- choices" hooks in.
function LevelManager.applyArrivalObjectives(player: Player, mapId: string)
    if mapId == "HongKong" then
        local state = WorldState.get(player)
        local pacifist = (state.counters.civiliansKilled or 0) == 0
            and (state.counters.kills or 0) <= 5
        local objectiveId = pacifist and "HongKong_Stealth" or "HongKong_Assault"
        if not state.flags["startedHongKong"] then
            MissionService.start(player, objectiveId)
            WorldState.setFlag(player, "startedHongKong", true)
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

-- Per-transition gate predicate, keyed by "<sourceMap>->" + targetMap.
-- Returning false denies the transition and shows a notify.
local function gateFor(targetMap: string): (string?, string?)
    -- Once defected, JC cannot return through the front door of UNATCO HQ.
    if targetMap == "UNATCO_HQ" then
        return "!flag:defected", "UNATCO has flagged you as a defector. Find another way."
    end
    return nil, nil
end

function LevelManager.transitionPlayer(player: Player, targetMap: string)
    local predicate, denyReason = gateFor(targetMap)
    if predicate and not WorldState.evaluate(player, predicate) then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, denyReason or "Transition denied.")
        return
    end
    -- For simplicity, transitions are global: when one player triggers it,
    -- the level reloads for everyone. (Single-player intent for this game.)
    LevelManager.load(targetMap)
end

local function watchTransitions()
    -- Polling: cheap, simple, and avoids per-Touched flooding.
    task.spawn(function()
        while true do
            task.wait(0.5)
            if not mapFolder then continue end
            for _, child in ipairs(mapFolder:GetChildren()) do
                if not child:IsA("BasePart") then continue end
                local kind = child:GetAttribute("InteractionType")
                if kind ~= "Transition" then continue end
                local target = child:GetAttribute("TargetMap")
                if typeof(target) ~= "string" then continue end
                local region = child :: BasePart
                for _, player in ipairs(Players:GetPlayers()) do
                    local char = player.Character
                    if not char then continue end
                    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
                    if not hrp then continue end
                    if (hrp.Position - region.Position).Magnitude < math.max(region.Size.X, region.Size.Z) then
                        LevelManager.transitionPlayer(player, target)
                        return -- map will reload, restart loop
                    end
                end
            end
        end
    end)
end

function LevelManager.init()
    LevelManager.load("LibertyIsland")
    watchTransitions()
end

return LevelManager
