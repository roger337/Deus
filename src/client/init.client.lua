--!strict
-- Client entry point. Wires controllers and UIs.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

local WeaponController = require(script.Controllers.WeaponController)
local InteractionController = require(script.Controllers.InteractionController)
local VoiceController = require(script.Controllers.VoiceController)
local HUD = require(script.UI.HUD)
local InventoryUI = require(script.UI.InventoryUI)
local SkillsUI = require(script.UI.SkillsUI)
local AugUI = require(script.UI.AugUI)
local DialogUI = require(script.UI.DialogUI)
local EndingScreen = require(script.UI.EndingScreen)
local VoteUI = require(script.UI.VoteUI)
local VendorUI = require(script.UI.VendorUI)
local SlotSelectUI = require(script.UI.SlotSelectUI)
local RequestAccessUI = require(script.UI.RequestAccessUI)
local AdminConsoleUI = require(script.UI.AdminConsoleUI)
local Lockpick = require(script.UI.Minigames.Lockpick)
local Hack = require(script.UI.Minigames.Hack)

-- Hide default Roblox UI elements that don't fit the aesthetic
pcall(function()
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
    StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

WeaponController.start()
InteractionController.start()
VoiceController.start()
HUD.start()
InventoryUI.start()
SkillsUI.start()
AugUI.start()
DialogUI.start()
EndingScreen.start()
VoteUI.start()
VendorUI.start()
SlotSelectUI.start()
RequestAccessUI.start()
AdminConsoleUI.start()
Lockpick.start()
Hack.start()

-- Keep WeaponController in sync with the equipped item.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared.Remotes)

local invEv = Remotes.get("InventoryUpdate") :: RemoteEvent
invEv.OnClientEvent:Connect(function(payload: any)
    if payload.equipped ~= nil then
        WeaponController.setEquipped(payload.equipped)
    end
end)

-- First-person on character spawn (toggle with F).
local firstPerson = false
local function applyCamera()
    local char = player.Character
    if not char then return end
    if firstPerson then
        player.CameraMode = Enum.CameraMode.LockFirstPerson
    else
        player.CameraMode = Enum.CameraMode.Classic
    end
end

player.CharacterAdded:Connect(function()
    task.wait(0.2)
    applyCamera()
end)
applyCamera()

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F then
        firstPerson = not firstPerson
        applyCamera()
    end
end)

-- Quick-equip hotkeys: 1..5 cycle weapon slots.
local SLOT_HOTKEYS = {
    [Enum.KeyCode.One] = "Pistol",
    [Enum.KeyCode.Two] = "Rifle",
    [Enum.KeyCode.Three] = "Heavy",
    [Enum.KeyCode.Four] = "Melee",
    [Enum.KeyCode.Five] = "Demolition",
}

local Weapons = require(Shared.Config.Weapons)

local lastInventory = {}
invEv.OnClientEvent:Connect(function(payload: any)
    if payload.inventory then lastInventory = payload.inventory end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local slot = SLOT_HOTKEYS[input.KeyCode]
    if not slot then return end
    -- find first weapon in inventory matching this slot
    for _, stack in ipairs(lastInventory) do
        local def = Weapons[stack.id]
        if def and def.slot == slot then
            local ev = Remotes.get("EquipItem") :: RemoteEvent
            ev:FireServer(stack.id)
            return
        end
    end
end)

print("[AegisVeil] Client ready.")
