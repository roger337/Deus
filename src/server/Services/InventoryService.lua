--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Items = require(Shared.Config.Items)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)
local Skills = require(Shared.Config.Skills)
local Weapons = require(Shared.Config.Weapons)
local WeaponMods = require(Shared.Config.WeaponMods)

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

-- Maps inventory mod-item ids ("WeaponModSilencer") to mod registry ids ("Silencer").
local function modItemToModId(itemId: string): string?
    if string.sub(itemId, 1, 9) ~= "WeaponMod" then return nil end
    return string.sub(itemId, 10)
end

function InventoryService.installMod(player: Player, weaponItemId: string, modItemId: string): boolean
    local weaponDef = Weapons[weaponItemId]
    if not weaponDef then return false end
    local modId = modItemToModId(modItemId)
    if not modId or not WeaponMods.Mods[modId] then return false end
    if not WeaponMods.compatible(modId, weaponDef.slot) then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, "Mod incompatible with this weapon.")
        return false
    end
    if not InventoryService.has(player, modItemId, 1) then return false end

    local data = PlayerData.get(player)
    local stack = findStack(data, weaponItemId)
    if not stack then return false end
    stack.mods = stack.mods or {}
    for _, existing in ipairs(stack.mods) do
        if existing == modId then
            local notify = Remotes.get("Notify") :: RemoteEvent
            notify:FireClient(player, "Mod already installed on this weapon.")
            return false
        end
    end
    table.insert(stack.mods, modId)
    InventoryService.remove(player, modItemId, 1)
    InventoryService.replicate(player)
    local notify = Remotes.get("Notify") :: RemoteEvent
    notify:FireClient(player, weaponDef.name .. ": " .. WeaponMods.Mods[modId].name .. " installed.")
    return true
end

function InventoryService.getStackMods(player: Player, weaponItemId: string): { string }
    local data = PlayerData.get(player)
    local stack = findStack(data, weaponItemId)
    if not stack or not stack.mods then return {} end
    return stack.mods
end

function InventoryService.equip(player: Player, itemId: string)
    if itemId ~= "" and not InventoryService.has(player, itemId, 1) then return end
    local data = PlayerData.get(player)
    data.equipped = (itemId ~= "" and itemId) or nil
    InventoryService.replicate(player)
    InventoryService.updateWeaponVisual(player)
end

-- Per-weapon visual: a Tool with a sized/colored Handle parented directly
-- to the character (which auto-equips it into the right hand). The Tool
-- is purely visual — actual firing logic stays in WeaponController on
-- the client. CanBeDropped = false so the player can't drop the visual
-- via Backspace.
function InventoryService.updateWeaponVisual(player: Player)
    local char = player.Character
    if not char then return end

    -- Tear down any existing visual first.
    local existing = char:FindFirstChild("WeaponVisual")
    if existing then existing:Destroy() end

    local data = PlayerData.get(player)
    if not data.equipped then return end
    local def = Weapons[data.equipped]
    if not def then return end

    local size, color, material = Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(60, 60, 70), Enum.Material.Metal
    if def.slot == "Pistol" then
        size = Vector3.new(0.5, 0.7, 1.5)
        color = Color3.fromRGB(40, 40, 50)
    elseif def.slot == "Rifle" then
        size = Vector3.new(0.5, 0.9, 3.5)
        color = Color3.fromRGB(50, 50, 55)
    elseif def.slot == "Heavy" then
        size = Vector3.new(0.9, 0.9, 4.5)
        color = Color3.fromRGB(80, 50, 40)
    elseif def.slot == "Melee" then
        if def.id == "RiotProd" then
            size = Vector3.new(0.3, 0.3, 1.6)
            color = Color3.fromRGB(80, 80, 90)
        else
            size = Vector3.new(0.2, 0.2, 1.4)
            color = Color3.fromRGB(200, 200, 200)
        end
    elseif def.slot == "Demolition" then
        size = Vector3.new(0.6, 0.6, 0.6)
        color = Color3.fromRGB(180, 50, 50)
    end

    local tool = Instance.new("Tool")
    tool.Name = "WeaponVisual"
    tool.RequiresHandle = true
    tool.CanBeDropped = false
    tool.ManualActivationOnly = true       -- don't fire Activated on click
    tool.ToolTip = def.name

    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = size
    handle.Color = color
    handle.Material = material
    handle.CanCollide = false
    handle.Massless = true
    handle.Parent = tool

    tool.Parent = char  -- parenting directly to Character auto-equips
end

function InventoryService.replicate(player: Player)
    local data = PlayerData.get(player)
    local ev = Remotes.get("InventoryUpdate") :: RemoteEvent
    ev:FireClient(player, {
        inventory = data.inventory,
        equipped = data.equipped,
    })
    InventoryService.updateWeaponVisual(player)
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

    local installEv = Remotes.get("InstallWeaponMod") :: RemoteEvent
    installEv.OnServerEvent:Connect(function(player, weaponId, modItemId)
        if typeof(weaponId) == "string" and typeof(modItemId) == "string" then
            InventoryService.installMod(player, weaponId, modItemId)
        end
    end)
end

return InventoryService
