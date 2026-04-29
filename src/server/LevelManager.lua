--!strict
-- Owns the currently-loaded map. Builds it, despawns it, and handles transitions
-- when players walk through transition triggers.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local Maps = require(script.Parent.Maps)

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

    -- Teleport everyone to the spawn point.
    for _, player in ipairs(Players:GetPlayers()) do
        LevelManager.placePlayer(player)
    end

    print("[LevelManager] Loaded map:", def.displayName)
end

function LevelManager.placePlayer(player: Player)
    if not current then return end
    local def = Maps[current]
    local char = player.Character or player.CharacterAdded:Wait()
    local hrp = char:WaitForChild("HumanoidRootPart") :: BasePart
    hrp.CFrame = CFrame.new(def.spawnPoint + Vector3.new(0, 4, 0))
end

function LevelManager.transitionPlayer(player: Player, targetMap: string)
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
