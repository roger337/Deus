--!strict
-- Co-op-aware mission service. Objectives are TEAM objectives in this game:
--   * MissionService.start(player, id)   starts for the whole team.
--   * MissionService.advance(player, id) advances for the whole team.
--   * MissionService.startSolo / advanceSolo are still available if you want
--     a single-player-only effect.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Objectives = require(Shared.Config.Objectives)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)
local SkillService = require(script.Parent.SkillService)
local VoiceService = require(script.Parent.VoiceService)

local MissionService = {}

function MissionService.startSolo(player: Player, objectiveId: string)
    local def = Objectives[objectiveId]
    if not def then return end
    local data = PlayerData.get(player)
    if data.objectives[objectiveId] then return end
    data.objectives[objectiveId] = { progress = 0, completed = false, started = true }
    MissionService.replicate(player)
    local notify = Remotes.get("Notify") :: RemoteEvent
    notify:FireClient(player, "New objective: " .. def.title)
    VoiceService.playFor(player, "Mission:objectiveAdded")
end

function MissionService.advanceSolo(player: Player, objectiveId: string, amount: number?)
    local def = Objectives[objectiveId]
    if not def then return end
    local data = PlayerData.get(player)
    local state = data.objectives[objectiveId]
    if not state or state.completed then return end
    state.progress = math.min(def.target, state.progress + (amount or 1))
    if state.progress >= def.target then
        state.completed = true
        SkillService.grantPoints(player, def.rewardSkillPoints)
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, "Objective complete: " .. def.title)
        VoiceService.playFor(player, "Mission:objectiveComplete")
    end
    MissionService.replicate(player)
end

-- Team versions: fan out to all online players.
function MissionService.start(_player: Player, objectiveId: string)
    for _, p in ipairs(Players:GetPlayers()) do
        MissionService.startSolo(p, objectiveId)
    end
end

function MissionService.advance(_player: Player, objectiveId: string, amount: number?)
    for _, p in ipairs(Players:GetPlayers()) do
        MissionService.advanceSolo(p, objectiveId, amount)
    end
end

function MissionService.replicate(player: Player)
    local data = PlayerData.get(player)
    local ev = Remotes.get("ObjectiveUpdate") :: RemoteEvent
    ev:FireClient(player, data.objectives)
end

return MissionService
