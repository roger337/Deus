--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Items = require(Shared.Config.Items)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Skills = require(Shared.Config.Skills)

local InventoryService = {}

local function findStack(data: PlayerData.PlayerData, itemId: string): (PlayerData.ItemStack?, number)
    for i, stack in ipairs(data.inventory) do
        if stack.id == itemId then
            return stack, i
        end
    end
    return nil, -1
end

function InventoryService.add(player: Player, itemId: string, count: number?): boolean
    local def = Items[itemId]
    if not def then return false end
    local n = count or 1
    local data = PlayerData.get(player)
    local stack = findStack(data, itemId)
    if stack and def.stackable then
        stack.count = math.min(def.stackMax, stack.count + n)
    else
        table.insert(data.inventory, { id = itemId, count = n })
    end
    InventoryService.replicate(player)
    return true
end

function InventoryService.remove(player: Player, itemId: string, count: number?): boolean
    local n = count or 1
    local data = PlayerData.get(player)
    local stack, idx = findStack(data, itemId)
    if not stack then return false end
    stack.count = stack.count - n
    if stack.count <= 0 then
        table.remove(data.inventory, idx)
        if data.equipped == itemId then
            data.equipped = nil
        end
    end
    InventoryService.replicate(player)
    return true
end

function InventoryService.has(player: Player, itemId: string, count: number?): boolean
    local data = PlayerData.get(player)
    local stack = findStack(data, itemId)
    return stack ~= nil and stack.count >= (count or 1)
end

function InventoryService.count(player: Player, itemId: string): number
    local data = PlayerData.get(player)
    local stack = findStack(data, itemId)
    return stack and stack.count or 0
end

function InventoryService.use(player: Player, itemId: string)
    local def = Items[itemId]
    if not def or not def.useEffect then return end
    local data = PlayerData.get(player)
    if not InventoryService.has(player, itemId, 1) then return end

    if def.useEffect == "Heal" then
        local mult = Skills.Skills.Medicine.multipliers[data.skills.Medicine.rank]
        local amount = (def.valueAmount or 0) * mult
        data.health = math.min(data.maxHealth, data.health + amount)
    elseif def.useEffect == "RestoreEnergy" then
        data.energy = math.min(data.maxEnergy, data.energy + (def.valueAmount or 0))
    end
    InventoryService.remove(player, itemId, 1)
    InventoryService.replicateStats(player)
end

function InventoryService.equip(player: Player, itemId: string)
    if itemId ~= "" and not InventoryService.has(player, itemId, 1) then return end
    local data = PlayerData.get(player)
    data.equipped = (itemId ~= "" and itemId) or nil
    InventoryService.replicate(player)
end

function InventoryService.replicate(player: Player)
    local data = PlayerData.get(player)
    local ev = Remotes.get("InventoryUpdate") :: RemoteEvent
    ev:FireClient(player, {
        inventory = data.inventory,
        equipped = data.equipped,
    })
end

function InventoryService.replicateStats(player: Player)
    local data = PlayerData.get(player)
    local ev = Remotes.get("StatsUpdate") :: RemoteEvent
    ev:FireClient(player, {
        health = data.health,
        maxHealth = data.maxHealth,
        energy = data.energy,
        maxEnergy = data.maxEnergy,
        skillPoints = data.skillPoints,
        kills = data.kills,
        knockouts = data.knockouts,
    })
end

function InventoryService.init()
    local useEv = Remotes.get("UseItem") :: RemoteEvent
    useEv.OnServerEvent:Connect(function(player, itemId)
        if typeof(itemId) == "string" then
            InventoryService.use(player, itemId)
        end
    end)

    local equipEv = Remotes.get("EquipItem") :: RemoteEvent
    equipEv.OnServerEvent:Connect(function(player, itemId)
        if typeof(itemId) == "string" then
            InventoryService.equip(player, itemId)
        end
    end)

    local dropEv = Remotes.get("DropItem") :: RemoteEvent
    dropEv.OnServerEvent:Connect(function(player, itemId)
        if typeof(itemId) == "string" then
            InventoryService.remove(player, itemId, 1)
        end
    end)
end

return InventoryService
