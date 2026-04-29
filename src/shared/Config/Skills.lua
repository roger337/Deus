--!strict
-- Skill system. Each rank costs more points and applies a multiplier
-- to the relevant gameplay value (weapon damage, minigame difficulty, etc.).
-- Multiplier is applied to weapon damage / minigame difficulty / etc.

export type SkillRank = "Untrained" | "Trained" | "Advanced" | "Master"

export type SkillDef = {
    id: string,
    name: string,
    description: string,
    costs: { [SkillRank]: number },     -- skill points required to reach rank
    multipliers: { [SkillRank]: number }, -- effect multiplier
}

local Skills: { [string]: SkillDef } = {
    Pistol = {
        id = "Pistol",
        name = "Pistol",
        description = "Increases pistol-class weapon damage and accuracy.",
        costs = { Untrained = 0, Trained = 900, Advanced = 1800, Master = 3300 },
        multipliers = { Untrained = 1.0, Trained = 1.4, Advanced = 1.8, Master = 2.4 },
    },
    Rifle = {
        id = "Rifle",
        name = "Rifle",
        description = "Increases rifle-class weapon damage and accuracy.",
        costs = { Untrained = 0, Trained = 900, Advanced = 1800, Master = 3300 },
        multipliers = { Untrained = 1.0, Trained = 1.4, Advanced = 1.8, Master = 2.4 },
    },
    Heavy = {
        id = "Heavy",
        name = "Heavy Weapons",
        description = "Reduces sway with heavy weapons; increases damage.",
        costs = { Untrained = 0, Trained = 900, Advanced = 1800, Master = 3300 },
        multipliers = { Untrained = 1.0, Trained = 1.3, Advanced = 1.6, Master = 2.0 },
    },
    Melee = {
        id = "Melee",
        name = "Melee",
        description = "Mastery of melee and thrown weapons.",
        costs = { Untrained = 0, Trained = 450, Advanced = 900, Master = 1800 },
        multipliers = { Untrained = 1.0, Trained = 1.5, Advanced = 2.0, Master = 3.0 },
    },
    Computer = {
        id = "Computer",
        name = "Computer",
        description = "Improves chance to hack terminals and shortens hack time.",
        costs = { Untrained = 0, Trained = 450, Advanced = 900, Master = 1800 },
        multipliers = { Untrained = 1.0, Trained = 1.5, Advanced = 2.0, Master = 3.0 },
    },
    Lockpicking = {
        id = "Lockpicking",
        name = "Lockpicking",
        description = "Picks tougher locks with fewer picks consumed.",
        costs = { Untrained = 0, Trained = 450, Advanced = 900, Master = 1800 },
        multipliers = { Untrained = 1.0, Trained = 1.5, Advanced = 2.0, Master = 3.0 },
    },
    Medicine = {
        id = "Medicine",
        name = "Medicine",
        description = "Each medkit restores more health.",
        costs = { Untrained = 0, Trained = 450, Advanced = 900, Master = 1800 },
        multipliers = { Untrained = 1.0, Trained = 1.4, Advanced = 1.8, Master = 2.4 },
    },
    Environmental = {
        id = "Environmental",
        name = "Environmental Training",
        description = "Reduces damage from explosions, fire, and gas.",
        costs = { Untrained = 0, Trained = 450, Advanced = 900, Master = 1800 },
        multipliers = { Untrained = 1.0, Trained = 0.8, Advanced = 0.6, Master = 0.4 },
    },
    Swimming = {
        id = "Swimming",
        name = "Swimming",
        description = "Faster swim speed and longer breath hold.",
        costs = { Untrained = 0, Trained = 200, Advanced = 400, Master = 800 },
        multipliers = { Untrained = 1.0, Trained = 1.4, Advanced = 1.8, Master = 2.4 },
    },
}

local RANK_ORDER: { SkillRank } = { "Untrained", "Trained", "Advanced", "Master" }

local module = {}

module.Skills = Skills
module.RankOrder = RANK_ORDER

function module.nextRank(current: SkillRank): SkillRank?
    for i, rank in ipairs(RANK_ORDER) do
        if rank == current then
            return RANK_ORDER[i + 1]
        end
    end
    return nil
end

function module.rankIndex(rank: SkillRank): number
    for i, r in ipairs(RANK_ORDER) do
        if r == rank then
            return i
        end
    end
    return 1
end

return module
