--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Objectives = require(Shared.Config.Objectives)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)
local SkillService = require(script.Parent.SkillService)

local MissionService = {}

function MissionService.start(player: Player, objectiveId: string)
    local def = Objectives[objectiveId]
    if not def then return end
    local data = PlayerData.get(player)
    if data.objectives[objectiveId] then return end
    data.objectives[objectiveId] = { progress = 0, completed = false, started = true }
    MissionService.replicate(player)
    local notify = Remotes.get("Notify") :: RemoteEvent
    notify:FireClient(player, "New objective: " .. def.title)
end

function MissionService.advance(player: Player, objectiveId: string, amount: number?)
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
    end
    MissionService.replicate(player)
end

function MissionService.replicate(player: Player)
    local data = PlayerData.get(player)
    local ev = Remotes.get("ObjectiveUpdate") :: RemoteEvent
    ev:FireClient(player, data.objectives)
end

return MissionService
