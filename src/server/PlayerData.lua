--!strict
-- Per-player runtime state. Source of truth for server; mirrored to client via remotes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Skills = require(Shared.Config.Skills)
local Augs = require(Shared.Config.Augmentations)

export type SkillState = {
    rank: Skills.SkillRank,
}

export type AugState = {
    installed: boolean,
    level: number,        -- 1..4 (0 = not installed)
    active: boolean,
}

export type ItemStack = {
    id: string,
    count: number,
    mods: { string }?,         -- weapon mod ids attached to this stack (weapons only)
}

export type PlayerData = {
    userId: number,
    saveSlot: number,
    health: number,
    maxHealth: number,
    energy: number,
    maxEnergy: number,
    skillPoints: number,
    credits: number,
    skills: { [string]: SkillState },
    augs: { [string]: AugState },
    inventory: { ItemStack },
    equipped: string?,
    objectives: { [string]: { progress: number, completed: boolean, started: boolean } },
    kills: number,
    knockouts: number,
    nonLethalRun: boolean,
}

local PlayerData = {}
PlayerData.__index = PlayerData

local cache: { [number]: PlayerData } = {}

local function defaultData(userId: number): PlayerData
    local skills: { [string]: SkillState } = {}
    for id, _ in pairs(Skills.Skills) do
        skills[id] = { rank = "Untrained" :: Skills.SkillRank }
    end
    local augStates: { [string]: AugState } = {}
    for id, _ in pairs(Augs.Augs) do
        augStates[id] = { installed = false, level = 0, active = false }
    end
    return {
        userId = userId,
        saveSlot = 1,
        health = 100,
        maxHealth = 100,
        energy = 100,
        maxEnergy = 100,
        skillPoints = 5000,
        credits = 500,
        skills = skills,
        augs = augStates,
        inventory = {
            { id = "Pistol10mm", count = 1 },
            { id = "Combat10mm", count = 1 },
            { id = "Ammo10mm", count = 30 },
            { id = "Medkit", count = 2 },
            { id = "Lockpick", count = 3 },
            { id = "Multitool", count = 3 },
        },
        equipped = "Pistol10mm",
        objectives = {},
        kills = 0,
        knockouts = 0,
        nonLethalRun = true,
    }
end

function PlayerData.get(player: Player): PlayerData
    local existing = cache[player.UserId]
    if existing then return existing end
    local data = defaultData(player.UserId)
    cache[player.UserId] = data
    return data
end

function PlayerData.set(player: Player, data: PlayerData)
    cache[player.UserId] = data
end

function PlayerData.clear(player: Player)
    cache[player.UserId] = nil
end

function PlayerData.all(): { [number]: PlayerData }
    return cache
end

return PlayerData
