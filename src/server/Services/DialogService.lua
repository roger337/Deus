--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Dialog = require(Shared.Config.Dialog)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)
local InventoryService = require(script.Parent.InventoryService)
local MissionService = require(script.Parent.MissionService)
local VoiceService = require(script.Parent.VoiceService)
local VoteService = require(script.Parent.VoteService)
local WorldState = require(script.Parent.Parent.WorldState)

local DialogService = {}

local active: { [Player]: { tree: string, node: string } } = {}

-- Hook called by other systems (e.g. Vega confrontation) to mutate the world.
-- Allows "hostile:Vega" effect to flip an NPC to combat. The map module
-- registers handlers via DialogService.registerEffect.
local effectHandlers: { [string]: (Player) -> () } = {}

function DialogService.registerEffect(name: string, handler: (Player) -> ())
    effectHandlers[name] = handler
end

local function applyEffect(player: Player, expr: string)
    if expr == "" then return end
    for clause in string.gmatch(expr, "[^;]+") do
        clause = clause:match("^%s*(.-)%s*$")
        local kind, body = clause:match("^([%w_!]+):(.+)$")
        if not kind then continue end
        if kind == "flag" then
            WorldState.setFlag(player, body, true)
        elseif kind == "!flag" then
            WorldState.setFlag(player, body, false)
        elseif kind == "faction" then
            WorldState.setFaction(player, body :: any)
        elseif kind == "rep" then
            local f, sign, num = body:match("^([%w_]+)([+%-])(%d+)$")
            if f and sign and num then
                local n = tonumber(num) or 0
                WorldState.adjustReputation(player, f, sign == "-" and -n or n)
            end
        elseif kind == "vote" then
            -- Open a team vote; outcome's effects will apply to all players
            -- when the vote resolves.
            VoteService.open(body)
        elseif kind == "hostile" then
            local h = effectHandlers["hostile:" .. body]
            if h then h(player) end
        else
            local h = effectHandlers[clause]
            if h then h(player) end
        end
    end
end

local function resolveStart(player: Player, tree: Dialog.DialogTree): string
    if tree.selectStart then
        for _, variant in ipairs(tree.selectStart) do
            if WorldState.evaluate(player, variant.when) then
                return variant.node
            end
        end
    end
    return tree.start
end

local function send(player: Player)
    local sess = active[player]
    if not sess then return end
    local tree = Dialog[sess.tree]
    if not tree then return end
    local node = tree.nodes[sess.node]
    if not node then return end
    local visibleOptions = {}
    for i, opt in ipairs(node.options) do
        if WorldState.evaluate(player, opt.requires) then
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

    VoiceService.playFor(player, "Dialog:" .. sess.tree .. ":" .. sess.node)
end

function DialogService.start(player: Player, treeId: string)
    local tree = Dialog[treeId]
    if not tree then return end
    active[player] = { tree = treeId, node = resolveStart(player, tree) }
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
    if not WorldState.evaluate(player, opt.requires) then return end

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
    if opt.effect then
        applyEffect(player, opt.effect)
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
