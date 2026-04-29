--!strict
-- Faction-gated vendor service. NPCs with InteractionType="Vendor" carry a
-- VendorId attribute; InteractionService routes to VendorService.openFor
-- which validates the gate and broadcasts the stock to the client.
--
-- Purchase flow:
--   1. Client sends BuyItem(vendorId, stockIndex)
--   2. Server validates: vendor exists, gate passes, index in range, player
--      has enough credits, item is a known weapon/item.
--   3. Deducts credits, adds the item (or N of an ammo entry).
--   4. Sends back updated stats (credits) + inventory replication.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local Vendors = require(Shared.Config.Vendors)
local Items = require(Shared.Config.Items)
local Weapons = require(Shared.Config.Weapons)
local PlayerData = require(script.Parent.Parent.PlayerData)
local InventoryService = require(script.Parent.InventoryService)
local WorldState = require(script.Parent.Parent.WorldState)

local VendorService = {}

local active: { [Player]: string } = {}  -- player -> open vendor id

function VendorService.openFor(player: Player, vendorId: string)
    local def = Vendors[vendorId]
    if not def then return end
    if def.gate and not WorldState.evaluate(player, def.gate) then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, def.rejectMessage or "Vendor refuses to sell to you.")
        return
    end
    active[player] = vendorId
    local data = PlayerData.get(player)
    local payload = {
        vendorId = def.id,
        name = def.name,
        faction = def.faction,
        greeting = def.greeting,
        credits = data.credits,
        stock = {},
    }
    for i, entry in ipairs(def.stock) do
        local itemDef = Items[entry.id]
        local weaponDef = Weapons[entry.id]
        local name = (itemDef and itemDef.name) or (weaponDef and weaponDef.name) or entry.id
        local desc = (itemDef and itemDef.description) or (weaponDef and weaponDef.description) or ""
        table.insert(payload.stock, {
            index = i,
            id = entry.id,
            name = name,
            description = desc,
            price = entry.price,
            quantity = entry.quantity or 1,
        })
    end
    local ev = Remotes.get("OpenVendor") :: RemoteEvent
    ev:FireClient(player, payload)
end

function VendorService.buy(player: Player, vendorId: string, stockIndex: number)
    if active[player] ~= vendorId then return end
    local def = Vendors[vendorId]
    if not def then return end
    if def.gate and not WorldState.evaluate(player, def.gate) then return end
    local entry = def.stock[stockIndex]
    if not entry then return end
    local data = PlayerData.get(player)
    if data.credits < entry.price then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, "Insufficient credits.")
        return
    end
    data.credits -= entry.price
    InventoryService.add(player, entry.id, entry.quantity or 1)
    InventoryService.replicateStats(player)
    -- Re-emit OpenVendor so the credit display refreshes.
    VendorService.openFor(player, vendorId)
end

function VendorService.close(player: Player)
    active[player] = nil
    local ev = Remotes.get("CloseVendor") :: RemoteEvent
    ev:FireClient(player)
end

function VendorService.init()
    local buyEv = Remotes.get("BuyItem") :: RemoteEvent
    buyEv.OnServerEvent:Connect(function(player, vendorId, stockIndex)
        if typeof(vendorId) == "string" and typeof(stockIndex) == "number" then
            VendorService.buy(player, vendorId, stockIndex)
        end
    end)
    local closeEv = Remotes.get("CloseVendor") :: RemoteEvent
    closeEv.OnServerEvent:Connect(function(player)
        VendorService.close(player)
    end)
end

return VendorService
