--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Dialog = require(Shared.Config.Dialog)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)
local InventoryService = require(script.Parent.InventoryService)
local MissionService = require(script.Parent.MissionService)

local DialogService = {}

local active: { [Player]: { tree: string, node: string } } = {}

local function send(player: Player)
    local sess = active[player]
    if not sess then return end
    local tree = Dialog[sess.tree]
    if not tree then return end
    local node = tree.nodes[sess.node]
    if not node then return end
    local data = PlayerData.get(player)
    local visibleOptions = {}
    for i, opt in ipairs(node.options) do
        if not opt.requires or (data.objectives[opt.requires] and data.objectives[opt.requires].started) then
            table.insert(visibleOptions, { index = i, text = opt.text })
        end
    end
    local payload = {
        npc = tree.npc,
        speaker = node.speaker,
        text = node.text,
        options = visibleOptions,
    }
    local ev = Remotes.get("RequestDialog") :: RemoteEvent
    ev:FireClient(player, payload)
end

function DialogService.start(player: Player, treeId: string)
    local tree = Dialog[treeId]
    if not tree then return end
    active[player] = { tree = treeId, node = tree.start }
    send(player)
end

function DialogService.choose(player: Player, optionIndex: number)
    local sess = active[player]
    if not sess then return end
    local tree = Dialog[sess.tree]
    if not tree then return end
    local node = tree.nodes[sess.node]
    if not node then return end
    local opt = node.options[optionIndex]
    if not opt then return end

    if opt.grants then
        for _, itemId in ipairs(opt.grants) do
            InventoryService.add(player, itemId, 1)
        end
    end
    if opt.starts then
        MissionService.start(player, opt.starts)
    end
    if opt.completes then
        MissionService.advance(player, opt.completes, math.huge)
    end
    if opt.end_ then
        DialogService.endDialog(player)
        return
    end
    if opt.next then
        sess.node = opt.next
        send(player)
    end
end

function DialogService.endDialog(player: Player)
    active[player] = nil
    local ev = Remotes.get("EndDialog") :: RemoteEvent
    ev:FireClient(player)
end

function DialogService.init()
    local chooseEv = Remotes.get("ChooseDialogOption") :: RemoteEvent
    chooseEv.OnServerEvent:Connect(function(player, optionIndex)
        if typeof(optionIndex) == "number" then
            DialogService.choose(player, optionIndex)
        end
    end)
    local endEv = Remotes.get("EndDialog") :: RemoteEvent
    endEv.OnServerEvent:Connect(function(player)
        DialogService.endDialog(player)
    end)
end

return DialogService
