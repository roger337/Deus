--!strict
-- Save/load wrapper around DataStore with retries and graceful failure in Studio.

local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local PlayerData = require(script.Parent.Parent.PlayerData)
local WorldState = require(script.Parent.Parent.WorldState)

local SAVE_KEY = "DeusExSave_v1"
local store: DataStore? = nil

-- DataStore is unavailable in Studio without API services; soft-fail there.
do
    local ok, ds = pcall(function()
        return DataStoreService:GetDataStore(SAVE_KEY)
    end)
    if ok then store = ds end
end

local module = {}

local function retry<T>(fn: () -> T, attempts: number): (boolean, T?)
    local lastErr
    for i = 1, attempts do
        local ok, result = pcall(fn)
        if ok then
            return true, result
        end
        lastErr = result
        task.wait(2 ^ (i - 1))
    end
    warn("[DataStore] failed after retries:", lastErr)
    return false, nil
end

function module.load(player: Player)
    if not store then return end
    local ok, payload = retry(function()
        return (store :: DataStore):GetAsync(tostring(player.UserId))
    end, 3)
    if ok and typeof(payload) == "table" then
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
end

function module.save(player: Player)
    if not store then return end
    local data = PlayerData.get(player)
    local payload = {
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
        nonLethalRun = data.nonLethalRun,
        worldState = WorldState.serialize(player),
    }
    retry(function()
        (store :: DataStore):SetAsync(tostring(player.UserId), payload)
        return true
    end, 3)
end

function module.bindAutoSave(intervalSec: number)
    if RunService:IsStudio() then return end
    task.spawn(function()
        while true do
            task.wait(intervalSec)
            for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
                module.save(player)
            end
        end
    end)
end

return module
