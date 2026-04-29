--!strict
-- Per-player stats tracker scoped to the Demo map. Combat / Interaction
-- services call DemoStatsService.recordEvent(player, kind) on relevant
-- gameplay; the service silently ignores events when the player isn't
-- currently in the Demo map.
--
-- When a player exits the Demo (via Demo -> Lobby transition), LevelManager
-- calls DemoStatsService.flushFor(player), which fires ShowDemoStats on
-- the client with the summary, then resets that player's counters.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Remotes = require(Shared.Remotes)

local DemoStatsService = {}

-- Lazy-required to avoid circular import (LevelManager imports services).
local _LevelManager = nil
local function levelManager()
    if not _LevelManager then
        _LevelManager = require(script.Parent.Parent.LevelManager)
    end
    return _LevelManager
end

type Stats = {
    enteredAt: number,
    kills: number,
    knockouts: number,
    civiliansKilled: number,
    locksPicked: number,
    terminalsHacked: number,
    hitsTaken: number,
}

local stats: { [number]: Stats } = {}

local function freshStats(): Stats
    return {
        enteredAt = os.clock(),
        kills = 0,
        knockouts = 0,
        civiliansKilled = 0,
        locksPicked = 0,
        terminalsHacked = 0,
        hitsTaken = 0,
    }
end

local function isInDemo(): boolean
    return levelManager().currentMap() == "Demo"
end

function DemoStatsService.enter(player: Player)
    stats[player.UserId] = freshStats()
end

function DemoStatsService.recordEvent(player: Player, kind: string, amount: number?)
    if not isInDemo() then return end
    local s = stats[player.UserId]
    if not s then
        s = freshStats()
        stats[player.UserId] = s
    end
    local delta = amount or 1
    if kind == "kill" then s.kills += delta
    elseif kind == "knockout" then s.knockouts += delta
    elseif kind == "civilianKilled" then s.civiliansKilled += delta
    elseif kind == "lockpicked" then s.locksPicked += delta
    elseif kind == "hacked" then s.terminalsHacked += delta
    elseif kind == "hitTaken" then s.hitsTaken += delta
    end
end

function DemoStatsService.flushFor(player: Player)
    local s = stats[player.UserId]
    if not s then return end
    local elapsed = math.max(0, os.clock() - s.enteredAt)
    local payload = {
        kills = s.kills,
        knockouts = s.knockouts,
        civiliansKilled = s.civiliansKilled,
        locksPicked = s.locksPicked,
        terminalsHacked = s.terminalsHacked,
        hitsTaken = s.hitsTaken,
        elapsedSec = elapsed,
    }
    local ev = Remotes.get("ShowDemoStats") :: RemoteEvent
    ev:FireClient(player, payload)
    stats[player.UserId] = nil
end

function DemoStatsService.clearFor(player: Player)
    stats[player.UserId] = nil
end

return DemoStatsService
