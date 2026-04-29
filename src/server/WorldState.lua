--!strict
-- Per-player narrative state. Distinct from PlayerData (which tracks gameplay
-- stats: HP, inventory, skills) — WorldState tracks the *story*: faction
-- alignment, reputations, named flags ("defected", "killedAnna"), counters
-- ("civiliansKilled", "botsDisabled"). All branching dialog, mission gating,
-- and ending eligibility reads from this single source.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)

export type Faction = "UNATCO" | "NSF" | "Lone"

export type WorldState = {
    userId: number,
    faction: Faction,
    reputation: { [string]: number },   -- UNATCO, NSF, Illuminati, MJ12, Civilian
    flags: { [string]: boolean },
    counters: { [string]: number },
}

local cache: { [number]: WorldState } = {}

local function defaults(userId: number): WorldState
    return {
        userId = userId,
        faction = "UNATCO",
        reputation = {
            UNATCO = 50,
            NSF = -50,
            Illuminati = 0,
            MJ12 = -25,
            Civilian = 25,
        },
        flags = {
            defected = false,
            metTracerTong = false,
            killedAnna = false,
            sparedAnna = false,
            recoveredAllAmbrosia = false,
            chosenHelios = false,
            chosenIlluminati = false,
            chosenDarkAge = false,
            heliosLocked = false,
        },
        counters = {
            kills = 0,
            knockouts = 0,
            civiliansKilled = 0,
            botsDisabled = 0,
        },
    }
end

local module = {}

function module.get(player: Player): WorldState
    local existing = cache[player.UserId]
    if existing then return existing end
    local state = defaults(player.UserId)
    cache[player.UserId] = state
    return state
end

function module.set(player: Player, state: WorldState)
    cache[player.UserId] = state
end

function module.clear(player: Player)
    cache[player.UserId] = nil
end

function module.setFlag(player: Player, name: string, value: boolean)
    local state = module.get(player)
    state.flags[name] = value
    module.replicate(player)
end

function module.bumpCounter(player: Player, name: string, delta: number?)
    local state = module.get(player)
    state.counters[name] = (state.counters[name] or 0) + (delta or 1)
    -- Civilian harm gates the Helios ending.
    if name == "civiliansKilled" and state.counters[name] >= 3 then
        state.flags.heliosLocked = true
    end
    module.replicate(player)
end

function module.adjustReputation(player: Player, faction: string, delta: number)
    local state = module.get(player)
    state.reputation[faction] = (state.reputation[faction] or 0) + delta
    module.replicate(player)
end

function module.setFaction(player: Player, faction: Faction)
    local state = module.get(player)
    state.faction = faction
    module.replicate(player)
end

function module.replicate(player: Player)
    local state = module.get(player)
    local ev = Remotes.get("WorldStateUpdate") :: RemoteEvent
    ev:FireClient(player, {
        faction = state.faction,
        reputation = state.reputation,
        flags = state.flags,
        counters = state.counters,
    })
end

-- =========================================================================
-- Predicate evaluator. Compact DSL used by Dialog.lua, Objectives.lua, and
-- LevelManager transitions. Returns true/false for a state.
--
-- Supported forms (split by ";" for AND, "|" for OR):
--    flag:name              -> state.flags[name] is truthy
--    !flag:name             -> state.flags[name] is falsy
--    faction:X              -> state.faction == X
--    !faction:X             -> state.faction ~= X
--    counter:name>=N        -> state.counters[name] >= N
--    counter:name<N         -> state.counters[name] < N
--    counter:name>N         -> state.counters[name] > N
--    counter:name==N        -> state.counters[name] == N
--    rep:F>=N / <N / >N     -> state.reputation[F] compared to N
-- =========================================================================

local function parseClause(state: WorldState, clause: string): boolean
    clause = clause:match("^%s*(.-)%s*$")
    if clause == "" then return true end

    local negate = false
    if clause:sub(1, 1) == "!" then
        negate = true
        clause = clause:sub(2)
    end

    local kind, body = clause:match("^([%w]+):(.+)$")
    if not kind then return false end

    local result = false
    if kind == "flag" then
        result = state.flags[body] == true
    elseif kind == "faction" then
        result = state.faction == body
    elseif kind == "counter" or kind == "rep" then
        local field, op, num = body:match("^([%w_]+)%s*(>=?|<=?|==)%s*(%-?%d+)$")
        if not field then
            field, op, num = body:match("^([%w_]+)%s*(>=)%s*(%-?%d+)$")
        end
        if not field then
            -- Fall back to less restrictive parse: split on operators.
            for _, oprx in ipairs({ ">=", "<=", "==", ">", "<" }) do
                local i = body:find(oprx, 1, true)
                if i then
                    field = body:sub(1, i - 1):match("^%s*(.-)%s*$")
                    op = oprx
                    num = body:sub(i + #oprx):match("^%s*(.-)%s*$")
                    break
                end
            end
        end
        if not field or not op or not num then return false end
        local n = tonumber(num)
        if not n then return false end
        local val = (kind == "counter" and state.counters[field]) or (kind == "rep" and state.reputation[field]) or 0
        if op == ">=" then result = val >= n
        elseif op == "<=" then result = val <= n
        elseif op == "==" then result = val == n
        elseif op == ">"  then result = val > n
        elseif op == "<"  then result = val < n
        end
    end

    if negate then result = not result end
    return result
end

function module.evaluate(player: Player, expr: string?): boolean
    if not expr or expr == "" then return true end
    local state = module.get(player)
    -- Top-level OR: split on "|"
    for orClause in string.gmatch(expr, "[^|]+") do
        -- Each OR clause is an AND of clauses split on ";"
        local allTrue = true
        for andClause in string.gmatch(orClause, "[^;]+") do
            if not parseClause(state, andClause) then
                allTrue = false
                break
            end
        end
        if allTrue then return true end
    end
    return false
end

function module.serialize(player: Player): { [string]: any }
    local state = module.get(player)
    return {
        faction = state.faction,
        reputation = state.reputation,
        flags = state.flags,
        counters = state.counters,
    }
end

function module.deserialize(player: Player, payload: any)
    local state = module.get(player)
    if typeof(payload) ~= "table" then return end
    if typeof(payload.faction) == "string" then state.faction = payload.faction end
    if typeof(payload.reputation) == "table" then state.reputation = payload.reputation end
    if typeof(payload.flags) == "table" then state.flags = payload.flags end
    if typeof(payload.counters) == "table" then state.counters = payload.counters end
end

return module
