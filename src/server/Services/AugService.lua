--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Augs = require(Shared.Config.Augmentations)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)
local InventoryService = require(script.Parent.InventoryService)

local AugService = {}

local DRAIN_INTERVAL = 0.5  -- seconds

function AugService.install(player: Player, augId: string): boolean
    local def = Augs.Augs[augId]
    if not def then return false end
    local data = PlayerData.get(player)
    local state = data.augs[augId]
    if state.installed then return false end
    if not InventoryService.has(player, "AugCanister", 1) then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, "No augmentation canisters available.")
        return false
    end
    -- Enforce slot exclusivity: only one aug per slot.
    for otherId, otherState in pairs(data.augs) do
        if otherState.installed and Augs.Augs[otherId].slot == def.slot then
            local notify = Remotes.get("Notify") :: RemoteEvent
            notify:FireClient(player, "Slot already in use.")
            return false
        end
    end
    InventoryService.remove(player, "AugCanister", 1)
    state.installed = true
    state.level = 1
    state.active = false
    AugService.replicate(player)
    return true
end

function AugService.upgrade(player: Player, augId: string): boolean
    local data = PlayerData.get(player)
    local state = data.augs[augId]
    if not state or not state.installed then return false end
    if state.level >= 4 then return false end
    if not InventoryService.has(player, "AugUpgradeCanister", 1) then return false end
    InventoryService.remove(player, "AugUpgradeCanister", 1)
    state.level += 1
    AugService.replicate(player)
    return true
end

function AugService.toggle(player: Player, augId: string)
    local def = Augs.Augs[augId]
    if not def or not def.active then return end
    local data = PlayerData.get(player)
    local state = data.augs[augId]
    if not state or not state.installed then return end
    state.active = not state.active
    AugService.replicate(player)
end

function AugService.magnitude(player: Player, augId: string): number?
    local data = PlayerData.get(player)
    local state = data.augs[augId]
    if not state or not state.installed or not state.active then
        return nil
    end
    local def = Augs.Augs[augId]
    return def.magnitudes[state.level]
end

function AugService.passiveMagnitude(player: Player, augId: string): number?
    local data = PlayerData.get(player)
    local state = data.augs[augId]
    if not state or not state.installed then return nil end
    local def = Augs.Augs[augId]
    return def.magnitudes[state.level]
end

function AugService.replicate(player: Player)
    local data = PlayerData.get(player)
    local ev = Remotes.get("StatsUpdate") :: RemoteEvent
    ev:FireClient(player, {
        augs = data.augs,
        energy = data.energy,
    })
end

function AugService.init()
    local installEv = Remotes.get("InstallAugmentation") :: RemoteEvent
    installEv.OnServerEvent:Connect(function(player, augId)
        if typeof(augId) == "string" then
            AugService.install(player, augId)
        end
    end)

    local toggleEv = Remotes.get("ToggleAugmentation") :: RemoteEvent
    toggleEv.OnServerEvent:Connect(function(player, augId)
        if typeof(augId) == "string" then
            AugService.toggle(player, augId)
        end
    end)

    -- Energy drain loop for active augs and regeneration grant.
    task.spawn(function()
        while true do
            task.wait(DRAIN_INTERVAL)
            for _, data in pairs(PlayerData.all()) do
                local player = game:GetService("Players"):GetPlayerByUserId(data.userId)
                if not player then continue end
                local drained = false
                for augId, state in pairs(data.augs) do
                    if state.installed and state.active then
                        local def = Augs.Augs[augId]
                        local cost = def.energyPerSec * DRAIN_INTERVAL
                        if data.energy >= cost then
                            data.energy -= cost
                            drained = true
                            if augId == "Regeneration" then
                                local mag = def.magnitudes[state.level]
                                data.health = math.min(data.maxHealth, data.health + mag * DRAIN_INTERVAL)
                            end
                        else
                            state.active = false
                        end
                    end
                end
                if drained then
                    InventoryService.replicateStats(player)
                end
            end
        end
    end)
end

return AugService
