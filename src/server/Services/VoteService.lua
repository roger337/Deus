--!strict
-- Vote-majority co-op decision system.
-- Only one vote can be active at a time. When a vote opens:
--   1. All online players receive an OpenVote remote with prompt + options
--   2. Each player can CastVote(voteId, optionId) once
--   3. When every online player has voted OR timeoutSec elapses, the winner
--      (most votes; tie goes to first listed) is selected and its effect is
--      applied to all players. CloseVote remote dismisses the UI.
--
-- Outcome effects: most are standard WorldState mutations (flag:, faction:,
-- rep:); the special prefix "ending:Foo" routes through EndingService and
-- shows the epilogue for every player.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)
local Votes = require(Shared.Config.Votes)
local WorldState = require(script.Parent.Parent.WorldState)

-- Lazy-required to avoid circular import.
local _DuelService = nil
local function duelService()
    if not _DuelService then
        _DuelService = require(script.Parent.DuelService)
    end
    return _DuelService
end

local VoteService = {}

-- Lazy-required to avoid circular import.
local _EndingService = nil
local function endingService()
    if not _EndingService then
        _EndingService = require(script.Parent.EndingService)
    end
    return _EndingService
end

type ActiveVote = {
    def: Votes.VoteDef,
    votes: { [number]: string },     -- userId -> optionId
    closing: boolean,
    expiresAt: number,
}

local active: ActiveVote? = nil

local function tally(): { [string]: number }
    if not active then return {} end
    local counts: { [string]: number } = {}
    for _, opt in ipairs(active.def.options) do
        counts[opt.id] = 0
    end
    for _, optId in pairs(active.votes) do
        counts[optId] = (counts[optId] or 0) + 1
    end
    return counts
end

local function broadcast(eventName: string, payload: any)
    local ev = Remotes.get(eventName) :: RemoteEvent
    for _, player in ipairs(Players:GetPlayers()) do
        ev:FireClient(player, payload)
    end
end

local function applyOutcome(effect: string)
    if effect == "" then return end
    -- "ending:Foo" is special — route through EndingService.
    local endingId = string.match(effect, "^ending:(.+)$")
    if endingId then
        for _, player in ipairs(Players:GetPlayers()) do
            endingService().tryTrigger(player, endingId)
        end
        return
    end
    -- Otherwise apply per-player WorldState mutations.
    for _, player in ipairs(Players:GetPlayers()) do
        for clause in string.gmatch(effect, "[^;]+") do
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
            end
        end
    end
end

local function findOption(optId: string): Votes.VoteOption?
    if not active then return nil end
    for _, opt in ipairs(active.def.options) do
        if opt.id == optId then return opt end
    end
    return nil
end

local function commitWinner(winnerId: string, count: number)
    if not active then return end
    local winningOption = findOption(winnerId)
    local notify = Remotes.get("Notify") :: RemoteEvent
    for _, player in ipairs(Players:GetPlayers()) do
        notify:FireClient(player, string.format("Vote: %s wins (%d votes).",
            winningOption and winningOption.label or winnerId, count))
    end
    if winningOption then
        applyOutcome(winningOption.effect)
    end
    broadcast("CloseVote", { voteId = active.def.id, winner = winnerId })
    active = nil
end

local function resolve()
    if not active or active.closing then return end
    active.closing = true

    local counts = tally()
    -- Find the maximum vote count and all options at that count.
    local maxCount = 0
    for _, opt in ipairs(active.def.options) do
        local c = counts[opt.id] or 0
        if c > maxCount then maxCount = c end
    end
    local tied = {}
    for _, opt in ipairs(active.def.options) do
        if (counts[opt.id] or 0) == maxCount then
            table.insert(tied, opt.id)
        end
    end

    -- Tie-breaker: if multiple options share the max AND at least one
    -- person voted, push to a duel between the tied voters. Single-option
    -- max (no tie) or zero-vote case falls through to first listed.
    if #tied > 1 and maxCount > 0 then
        local voteId = active.def.id
        local options = active.def.options
        local votesCopy: { [number]: string } = {}
        for k, v in pairs(active.votes) do votesCopy[k] = v end
        duelService().start(voteId, votesCopy, options, function(winnerId)
            -- Reopen the active slot just long enough to commit; a duel
            -- can outlive the original vote object so we re-find the count.
            local winnerCount = (counts[winnerId] or 0)
            -- We need `active` to reference the original def for commit;
            -- since resolve() set active.closing=true above and didn't nil
            -- it, it's still valid here.
            commitWinner(winnerId, winnerCount)
        end)
        return
    end

    commitWinner(tied[1] or active.def.options[1].id, maxCount)
end

local function maybeAutoResolve()
    if not active then return end
    local online = #Players:GetPlayers()
    local votes = 0
    for _, _v in pairs(active.votes) do votes += 1 end
    if votes >= online and online > 0 then
        resolve()
    end
end

function VoteService.open(voteId: string)
    if active then
        warn("[VoteService] another vote already active:", active.def.id)
        return
    end
    local def = Votes[voteId]
    if not def then
        warn("[VoteService] unknown vote id:", voteId)
        return
    end
    active = {
        def = def,
        votes = {},
        closing = false,
        expiresAt = os.clock() + def.timeoutSec,
    }
    broadcast("OpenVote", {
        voteId = def.id,
        prompt = def.prompt,
        options = def.options,
        timeoutSec = def.timeoutSec,
    })

    -- Timeout watcher.
    task.delay(def.timeoutSec + 0.1, function()
        if active and active.def.id == def.id then
            resolve()
        end
    end)
end

function VoteService.cast(player: Player, voteId: string, optionId: string)
    if not active or active.def.id ~= voteId or active.closing then return end
    -- Validate option id.
    local valid = false
    for _, opt in ipairs(active.def.options) do
        if opt.id == optionId then valid = true; break end
    end
    if not valid then return end

    active.votes[player.UserId] = optionId

    -- Replicate live tally.
    broadcast("VoteUpdate", {
        voteId = active.def.id,
        tally = tally(),
        votedCount = (function()
            local n = 0
            for _ in pairs(active.votes) do n += 1 end
            return n
        end)(),
        totalCount = #Players:GetPlayers(),
    })

    maybeAutoResolve()
end

function VoteService.init()
    local castEv = Remotes.get("CastVote") :: RemoteEvent
    castEv.OnServerEvent:Connect(function(player, voteId, optionId)
        if typeof(voteId) == "string" and typeof(optionId) == "string" then
            VoteService.cast(player, voteId, optionId)
        end
    end)
end

return VoteService
