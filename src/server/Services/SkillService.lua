--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Skills = require(Shared.Config.Skills)
local Remotes = require(Shared.Remotes)
local PlayerData = require(script.Parent.Parent.PlayerData)

local SkillService = {}

function SkillService.allocate(player: Player, skillId: string): boolean
    local def = Skills.Skills[skillId]
    if not def then return false end
    local data = PlayerData.get(player)
    local state = data.skills[skillId]
    if not state then return false end
    local nextRank = Skills.nextRank(state.rank)
    if not nextRank then return false end
    local cost = def.costs[nextRank]
    if data.skillPoints < cost then
        local notify = Remotes.get("Notify") :: RemoteEvent
        notify:FireClient(player, "Insufficient skill points.")
        return false
    end
    data.skillPoints -= cost
    state.rank = nextRank
    SkillService.replicate(player)
    return true
end

function SkillService.grantPoints(player: Player, amount: number)
    local data = PlayerData.get(player)
    data.skillPoints += amount
    SkillService.replicate(player)
end

function SkillService.multiplier(player: Player, skillId: string): number
    local data = PlayerData.get(player)
    local state = data.skills[skillId]
    local def = Skills.Skills[skillId]
    if not state or not def then return 1 end
    return def.multipliers[state.rank] or 1
end

function SkillService.replicate(player: Player)
    local data = PlayerData.get(player)
    local ev = Remotes.get("StatsUpdate") :: RemoteEvent
    ev:FireClient(player, {
        skills = data.skills,
        skillPoints = data.skillPoints,
    })
end

function SkillService.init()
    local ev = Remotes.get("AllocateSkill") :: RemoteEvent
    ev.OnServerEvent:Connect(function(player, skillId)
        if typeof(skillId) == "string" then
            SkillService.allocate(player, skillId)
        end
    end)
end

return SkillService
