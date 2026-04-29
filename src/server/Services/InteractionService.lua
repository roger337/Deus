--!strict
-- Handles in-world interactions: talk to NPC, hack terminal, lockpick door, pick up item.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local DialogService = require(script.Parent.DialogService)
local InventoryService = require(script.Parent.InventoryService)
local MissionService = require(script.Parent.MissionService)
local SkillService = require(script.Parent.SkillService)
local VoiceService = require(script.Parent.VoiceService)
local EndingService = require(script.Parent.EndingService)
local VoteService = require(script.Parent.VoteService)
local VendorService = require(script.Parent.VendorService)

local InteractionService = {}

local INTERACT_RANGE = 12

local function near(player: Player, part: BasePart): boolean
    local char = player.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
    if not hrp then return false end
    return (hrp.Position - part.Position).Magnitude <= INTERACT_RANGE
end

function InteractionService.handleInteraction(player: Player, target: Instance)
    if not target or not target:IsA("BasePart") and not target:IsA("Model") then return end
    local rootPart: BasePart? = if target:IsA("BasePart") then target else (target :: Model).PrimaryPart or (target :: Model):FindFirstChildWhichIsA("BasePart")
    if not rootPart then return end
    if not near(player, rootPart) then return end

    local kind = target:GetAttribute("InteractionType")
    if kind == "NPC" then
        local treeId = target:GetAttribute("DialogTree")
        if typeof(treeId) == "string" then
            DialogService.start(player, treeId)
        end
    elseif kind == "Pickup" then
        local itemId = target:GetAttribute("ItemId")
        local count = target:GetAttribute("ItemCount") or 1
        if typeof(itemId) == "string" then
            InventoryService.add(player, itemId, count)
            if itemId == "KeyHelixVial" then
                MissionService.advance(player, "RecoverHelixVials", 1)
            end
            target:Destroy()
        end
    elseif kind == "Door" then
        local locked = target:GetAttribute("Locked")
        if locked then
            -- client should open lockpick minigame; server confirms upon success
            local ev = Remotes.get("AttemptLockpick") :: RemoteEvent
            ev:FireClient(player, target, target:GetAttribute("LockDifficulty") or 1)
        else
            -- toggle open: rotate the door 90 degrees on Y
            local model = target:IsA("Model") and target or target:FindFirstAncestorOfClass("Model")
            if model and model.PrimaryPart then
                local open = model:GetAttribute("IsOpen")
                if not open then
                    model:PivotTo(model.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(90), 0))
                else
                    model:PivotTo(model.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(-90), 0))
                end
                model:SetAttribute("IsOpen", not open)
            end
        end
    elseif kind == "Hack" then
        local ev = Remotes.get("AttemptHack") :: RemoteEvent
        ev:FireClient(player, target, target:GetAttribute("HackDifficulty") or 1)
    elseif kind == "EndingDirect" then
        -- Used by the Faith path exit door: no minigame, no consumables;
        -- the act of choosing IS the gameplay. Open the configured ending
        -- vote and let the team decide.
        local voteId = target:GetAttribute("EndingVote")
        if typeof(voteId) == "string" then
            VoteService.open(voteId)
        end
    elseif kind == "Vendor" then
        local vendorId = target:GetAttribute("VendorId")
        if typeof(vendorId) == "string" then
            VendorService.openFor(player, vendorId)
        end
    end
end

function InteractionService.confirmLockpick(player: Player, target: Instance, success: boolean)
    if not success then return end
    if target:GetAttribute("InteractionType") ~= "Door" then return end
    if not InventoryService.has(player, "Lockpick", 1) then return end
    InventoryService.remove(player, "Lockpick", 1)
    target:SetAttribute("Locked", false)
    VoiceService.playFor(player, "Mission:lockpickSuccess")
    InteractionService.handleInteraction(player, target)
end

function InteractionService.confirmHack(player: Player, target: Instance, success: boolean)
    if not success then
        VoiceService.playFor(player, "Mission:hackFail")
        return
    end
    if target:GetAttribute("InteractionType") ~= "Hack" then return end
    if not InventoryService.has(player, "Multitool", 1) then return end
    InventoryService.remove(player, "Multitool", 1)
    target:SetAttribute("Hacked", true)
    VoiceService.playFor(player, "Mission:hackSuccess")

    -- Endgame terminals carry an EndingId attribute; route them through a
    -- team vote. The vote's outcome ("ending:Lattice" etc.) calls
    -- EndingService.tryTrigger for every player when majority approves.
    local endingId = target:GetAttribute("EndingId")
    if typeof(endingId) == "string" then
        local voteId = target:GetAttribute("EndingVote")
        if typeof(voteId) ~= "string" then
            voteId = "ending" .. endingId
        end
        VoteService.open(voteId)
        return
    end

    local objectiveId = target:GetAttribute("ObjectiveId")
    if typeof(objectiveId) == "string" then
        MissionService.advance(player, objectiveId, math.huge)
    end
end

function InteractionService.init()
    local interactEv = Remotes.get("InteractWith") :: RemoteEvent
    interactEv.OnServerEvent:Connect(function(player, target)
        if typeof(target) == "Instance" then
            InteractionService.handleInteraction(player, target)
        end
    end)

    local lockEv = Remotes.get("AttemptLockpick") :: RemoteEvent
    lockEv.OnServerEvent:Connect(function(player, target, success)
        if typeof(target) == "Instance" and typeof(success) == "boolean" then
            InteractionService.confirmLockpick(player, target, success)
        end
    end)

    local hackEv = Remotes.get("AttemptHack") :: RemoteEvent
    hackEv.OnServerEvent:Connect(function(player, target, success)
        if typeof(target) == "Instance" and typeof(success) == "boolean" then
            InteractionService.confirmHack(player, target, success)
        end
    end)
end

return InteractionService
