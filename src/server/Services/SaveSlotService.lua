--!strict
-- Per-user save slots (1..3). Each slot holds independent PlayerData +
-- WorldState in a separate DataStore key. The player picks a slot on join
-- via SlotSelectUI; until they pick, they're held off the playable map.
--
-- DataStore key: "<userId>_<slot>"
-- Manifest key:  "<userId>_manifest" (small per-user record listing slot
-- summaries: "Slot 1: AEGIS faction, kills=3, civilians=0").

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)
local WorldState = require(script.Parent.Parent.WorldState)

local SaveSlotService = {}

local STORE_NAME = "AegisVeilSave_v1"
local MANIFEST_NAME = "AegisVeilSlots_v1"

local store: DataStore? = nil
local manifestStore: DataStore? = nil

do
    local ok1, ds = pcall(function() return DataStoreService:GetDataStore(STORE_NAME) end)
    if ok1 then store = ds end
    local ok2, ms = pcall(function() return DataStoreService:GetDataStore(MANIFEST_NAME) end)
    if ok2 then manifestStore = ms end
end

local pendingSlot: { [Player]: number } = {}  -- player -> chosen slot

local function retry<T>(fn: () -> T, attempts: number): (boolean, any)
    local last
    for i = 1, attempts do
        local ok, result = pcall(fn)
        if ok then return true, result end
        last = result
        task.wait(2 ^ (i - 1))
    end
    return false, last
end

function SaveSlotService.fetchManifest(player: Player): { [number]: any }
    if not manifestStore then return {} end
    local _, payload = retry(function()
        return (manifestStore :: DataStore):GetAsync(tostring(player.UserId))
    end, 2)
    if typeof(payload) == "table" then return payload end
    return {}
end

function SaveSlotService.writeManifest(player: Player, slot: number)
    if not manifestStore then return end
    local data = PlayerData.get(player)
    local state = WorldState.get(player)
    local summary = {
        slot = slot,
        faction = state.faction,
        kills = data.kills,
        civiliansKilled = state.counters.civiliansKilled or 0,
        skillPoints = data.skillPoints,
        playedAt = os.time(),
    }
    retry(function()
        local mgr = manifestStore :: DataStore
        local current = mgr:GetAsync(tostring(player.UserId)) or {}
        if typeof(current) ~= "table" then current = {} end
        current[tostring(slot)] = summary
        mgr:SetAsync(tostring(player.UserId), current)
        return true
    end, 2)
end

function SaveSlotService.loadSlot(player: Player, slot: number)
    if not store then return end
    local _, payload = retry(function()
        return (store :: DataStore):GetAsync(tostring(player.UserId) .. "_" .. tostring(slot))
    end, 2)
    if typeof(payload) == "table" then
        local data = PlayerData.get(player)
        for k, v in pairs(payload) do
            if k ~= "worldState" then
                (data :: any)[k] = v
            end
        end
        if typeof(payload.worldState) == "table" then
            WorldState.deserialize(player, payload.worldState)
        end
    end
    PlayerData.get(player).saveSlot = slot
end

function SaveSlotService.saveSlot(player: Player)
    if not store then return end
    local data = PlayerData.get(player)
    local slot = data.saveSlot or 1
    local payload = {
        saveSlot = slot,
        health = data.health,
        maxHealth = data.maxHealth,
        energy = data.energy,
        maxEnergy = data.maxEnergy,
        skillPoints = data.skillPoints,
        credits = data.credits,
        skills = data.skills,
        augs = data.augs,
        inventory = data.inventory,
        equipped = data.equipped,
        objectives = data.objectives,
        kills = data.kills,
        knockouts = data.knockouts,
        nonLethalRun = data.nonLethalRun,
        worldState = WorldState.serialize(player),
    }
    retry(function()
        (store :: DataStore):SetAsync(tostring(player.UserId) .. "_" .. tostring(slot), payload)
        return true
    end, 2)
    SaveSlotService.writeManifest(player, slot)
end

function SaveSlotService.bindAutoSave(intervalSec: number)
    if RunService:IsStudio() then return end
    task.spawn(function()
        while true do
            task.wait(intervalSec)
            for _, p in ipairs(Players:GetPlayers()) do
                if not pendingSlot[p] then
                    SaveSlotService.saveSlot(p)
                end
            end
        end
    end)
end

-- Show the slot picker to a freshly-joined player. They cannot move (we
-- spawn them in a holding spot via LevelManager.placePlayer until they
-- choose). The client UI sends back SelectSaveSlot with a slot number.
function SaveSlotService.showPicker(player: Player)
    pendingSlot[player] = nil
    local manifest = SaveSlotService.fetchManifest(player)
    local ev = Remotes.get("ShowSlotSelect") :: RemoteEvent
    ev:FireClient(player, { slots = manifest })
end

function SaveSlotService.pickerStillOpen(player: Player): boolean
    return pendingSlot[player] == nil and not PlayerData.get(player)._slotChosen
end

function SaveSlotService.applySlot(player: Player, slot: number, newGame: boolean)
    if slot < 1 or slot > 3 then return end
    pendingSlot[player] = slot
    -- Reset PlayerData + WorldState before loading so we don't keep stale
    -- defaults from another slot.
    PlayerData.clear(player)
    WorldState.clear(player)
    PlayerData.get(player).saveSlot = slot
    WorldState.get(player)
    if not newGame then
        SaveSlotService.loadSlot(player, slot)
    end
    PlayerData.get(player)._slotChosen = true
    PlayerData.get(player).saveSlot = slot
end

function SaveSlotService.init()
    local ev = Remotes.get("SelectSaveSlot") :: RemoteEvent
    ev.OnServerEvent:Connect(function(player, slot, newGame)
        if typeof(slot) ~= "number" then return end
        local fresh = newGame == true
        SaveSlotService.applySlot(player, slot, fresh)
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, string.format("Loaded slot %d%s.", slot, fresh and " (new game)" or ""))
    end)
end

return SaveSlotService
