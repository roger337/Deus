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
local SaveSlotService = require(script.Services.SaveSlotService)
local InventoryService = require(script.Services.InventoryService)
local SkillService = require(script.Services.SkillService)
local AugService = require(script.Services.AugService)
local CombatService = require(script.Services.CombatService)
local DialogService = require(script.Services.DialogService)
local InteractionService = require(script.Services.InteractionService)
local MissionService = require(script.Services.MissionService)
local VoteService = require(script.Services.VoteService)
local VendorService = require(script.Services.VendorService)
local EnemyAI = require(script.EnemyAI)
local LevelManager = require(script.LevelManager)

InventoryService.init()
SkillService.init()
AugService.init()
CombatService.init()
DialogService.init()
InteractionService.init()
VoteService.init()
VendorService.init()
SaveSlotService.init()

-- =========================================================================
-- Dialog effect handlers. Declarative effects in Dialog.lua (`hostile:Vega`)
-- are dispatched to these handlers. Keep handlers small + idempotent.
-- =========================================================================

DialogService.registerEffect("hostile:Vega", function(player: Player)
    -- Find the friendly Vega NPC, capture position, replace with a hostile
    -- enemy at the same spot. CharacterId persists so kill tracking still
    -- flags WorldState.killedVega correctly.
    for _, child in ipairs(Workspace:GetDescendants()) do
        if child:IsA("Model") and child:GetAttribute("CharacterId") == "Vega"
           and child:GetAttribute("Faction") ~= "Hostile" then
            local hrp = child:FindFirstChild("HumanoidRootPart") :: BasePart?
            if not hrp then return end
            local pos = hrp.Position
            child:Destroy()
            local hostile = EnemyAI.spawn({
                position = pos,
                kind = "Human",
                weapon = "SniperRifle",
                name = "Vega",
                health = 200,
            })
            hostile:SetAttribute("CharacterId", "Vega")
            EnemyAI.run(hostile)
            local notify = Remotes.get("Notify") :: RemoteEvent
            notify:FireClient(player, "Vega is now hostile.")
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
    -- Show slot picker first; until they pick we still spawn them in the
    -- current map (they're playable but haven't restored a save). Once they
    -- pick, applySlot replaces both PlayerData and WorldState for the slot.
    SaveSlotService.showPicker(player)

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
    SaveSlotService.saveSlot(player)
    PlayerData.clear(player)
    WorldState.clear(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        SaveSlotService.saveSlot(player)
    end
end)

LevelManager.init()
SaveSlotService.bindAutoSave(120)

print("[AegisVeil] Server ready. Map:", LevelManager.currentMap())
