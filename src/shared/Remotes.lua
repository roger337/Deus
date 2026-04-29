--!strict
-- Centralized remote event/function bootstrapper.
-- Server creates them on first require; clients wait for them.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FOLDER_NAME = "DeusRemotes"

local Remotes = {}

local function ensureFolder(): Folder
    local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
    if folder then
        return folder :: Folder
    end
    if RunService:IsServer() then
        folder = Instance.new("Folder")
        folder.Name = FOLDER_NAME
        folder.Parent = ReplicatedStorage
        return folder :: Folder
    end
    return ReplicatedStorage:WaitForChild(FOLDER_NAME, 10) :: Folder
end

local EVENT_NAMES = {
    "FireWeapon",
    "ReloadWeapon",
    "EquipItem",
    "UseItem",
    "DropItem",
    "PickupItem",
    "InstallWeaponMod",
    "AllocateSkill",
    "InstallAugmentation",
    "ToggleAugmentation",
    "RequestDialog",
    "ChooseDialogOption",
    "EndDialog",
    "AttemptLockpick",
    "AttemptHack",
    "InteractWith",
    "ObjectiveUpdate",
    "InventoryUpdate",
    "StatsUpdate",
    "DamageFeedback",
    "Notify",
    "PlayVoice",
    "WorldStateUpdate",
    "ShowEnding",
    "OpenVote",
    "CastVote",
    "VoteUpdate",
    "CloseVote",
    "OpenVendor",
    "BuyItem",
    "CloseVendor",
    "SelectSaveSlot",
    "ShowSlotSelect",
}

local FUNCTION_NAMES = {
    "GetPlayerData",
    "GetWorldInteractables",
}

function Remotes.get(name: string): RemoteEvent | RemoteFunction
    local folder = ensureFolder()
    local existing = folder:FindFirstChild(name)
    if existing then
        return existing :: any
    end
    if RunService:IsServer() then
        local isFunction = false
        for _, n in ipairs(FUNCTION_NAMES) do
            if n == name then
                isFunction = true
                break
            end
        end
        local inst = Instance.new(isFunction and "RemoteFunction" or "RemoteEvent")
        inst.Name = name
        inst.Parent = folder
        return inst :: any
    end
    return folder:WaitForChild(name, 10) :: any
end

function Remotes.initServer()
    assert(RunService:IsServer(), "Remotes.initServer must run on server")
    for _, n in ipairs(EVENT_NAMES) do
        Remotes.get(n)
    end
    for _, n in ipairs(FUNCTION_NAMES) do
        Remotes.get(n)
    end
end

return Remotes
