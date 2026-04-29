--!strict
-- Server entry point. Boot order matters: remotes -> services -> map.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
Remotes.initServer()

local PlayerData = require(script.PlayerData)
local DataStoreService = require(script.Services.DataStoreService)
local InventoryService = require(script.Services.InventoryService)
local SkillService = require(script.Services.SkillService)
local AugService = require(script.Services.AugService)
local CombatService = require(script.Services.CombatService)
local DialogService = require(script.Services.DialogService)
local InteractionService = require(script.Services.InteractionService)
local MissionService = require(script.Services.MissionService)
local LevelManager = require(script.LevelManager)

InventoryService.init()
SkillService.init()
AugService.init()
CombatService.init()
DialogService.init()
InteractionService.init()

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
    }
end

local function onPlayerAdded(player: Player)
    PlayerData.get(player)
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
    end)
end

local function onPlayerRemoving(player: Player)
    DataStoreService.save(player)
    PlayerData.clear(player)
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
