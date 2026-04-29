--!strict
-- Server entry point. Boot order matters: remotes -> services -> map.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
Remotes.initServer()

local PlayerData = require(script.PlayerData)
local WorldState = require(script.WorldState)
local DataStoreService = require(script.Services.DataStoreService)
local InventoryService = require(script.Services.InventoryService)
local SkillService = require(script.Services.SkillService)
local AugService = require(script.Services.AugService)
local CombatService = require(script.Services.CombatService)
local DialogService = require(script.Services.DialogService)
local InteractionService = require(script.Services.InteractionService)
local MissionService = require(script.Services.MissionService)
local EnemyAI = require(script.EnemyAI)
local LevelManager = require(script.LevelManager)

InventoryService.init()
SkillService.init()
AugService.init()
CombatService.init()
DialogService.init()
InteractionService.init()

-- =========================================================================
-- Dialog effect handlers. Declarative effects in Dialog.lua (`hostile:Anna`)
-- are dispatched to these handlers. Keep handlers small + idempotent.
-- =========================================================================

DialogService.registerEffect("hostile:Anna", function(player: Player)
    -- Find the friendly Anna NPC, capture position, replace with a hostile
    -- NSF-class enemy at the same spot. CharacterId persists so kill tracking
    -- still flags WorldState.killedAnna correctly.
    for _, child in ipairs(Workspace:GetDescendants()) do
        if child:IsA("Model") and child:GetAttribute("CharacterId") == "Anna"
           and child:GetAttribute("Faction") ~= "NSF" then
            local hrp = child:FindFirstChild("HumanoidRootPart") :: BasePart?
            if not hrp then return end
            local pos = hrp.Position
            child:Destroy()
            local hostile = EnemyAI.spawn({
                position = pos,
                kind = "Human",
                weapon = "SniperRifle",
                name = "Anna Navarre",
                health = 200,
            })
            hostile:SetAttribute("CharacterId", "Anna")
            EnemyAI.run(hostile)
            local notify = Remotes.get("Notify") :: RemoteEvent
            notify:FireClient(player, "Anna Navarre is now hostile.")
            return
        end
    end
end)

-- GetPlayerData remote function: client requests its own state on spawn.
local getData = Remotes.get("GetPlayerData") :: RemoteFunction
getData.OnServerInvoke = function(player: Player)
    local data = PlayerData.get(player)
    return {
        health = data.health,
        maxHealth = data.maxHealth,
        energy = data.energy,
        maxEnergy = data.maxEnergy,
        skillPoints = data.skillPoints,
        skills = data.skills,
        augs = data.augs,
        inventory = data.inventory,
        equipped = data.equipped,
        objectives = data.objectives,
        kills = data.kills,
        knockouts = data.knockouts,
        worldState = WorldState.serialize(player),
    }
end

local function onPlayerAdded(player: Player)
    PlayerData.get(player)
    WorldState.get(player)
    DataStoreService.load(player)

    player.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid") :: Humanoid
        local data = PlayerData.get(player)
        hum.MaxHealth = data.maxHealth
        hum.Health = math.max(1, data.health)

        hum.Died:Connect(function()
            local d = PlayerData.get(player)
            d.health = d.maxHealth
            d.nonLethalRun = false
        end)

        hum:GetPropertyChangedSignal("Health"):Connect(function()
            local d = PlayerData.get(player)
            d.health = hum.Health
            InventoryService.replicateStats(player)
        end)

        task.wait(0.5)
        LevelManager.placePlayer(player)
        InventoryService.replicate(player)
        InventoryService.replicateStats(player)
        SkillService.replicate(player)
        AugService.replicate(player)
        MissionService.replicate(player)
        WorldState.replicate(player)
    end)
end

local function onPlayerRemoving(player: Player)
    DataStoreService.save(player)
    PlayerData.clear(player)
    WorldState.clear(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        DataStoreService.save(player)
    end
end)

LevelManager.init()
DataStoreService.bindAutoSave(120)

print("[DeusEx] Server ready. Map:", LevelManager.currentMap())
