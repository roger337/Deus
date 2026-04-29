--!strict
-- Nano-augmentations. Each occupies one slot, has 4 levels, and may be active or passive.
-- Activating an aug drains bio-energy per second; level 1 is cheap, level 4 is expensive.

export type AugDef = {
    id: string,
    name: string,
    slot: string,                -- "Cranial", "Eye", "Arms", "Legs", "Torso", "Subdermal"
    active: boolean,             -- true = toggleable, false = passive
    energyPerSec: number,        -- only if active
    description: string,
    levels: { string },          -- description per level (1..4)
    magnitudes: { number },      -- numeric strength per level
}

local Augs: { [string]: AugDef } = {
    CombatStrength = {
        id = "CombatStrength",
        name = "Combat Strength",
        slot = "Arms",
        active = true,
        energyPerSec = 60,
        description = "Increases damage of all melee attacks.",
        levels = {
            "Melee damage +50%",
            "Melee damage +100%",
            "Melee damage +200%",
            "Melee damage +400%",
        },
        magnitudes = { 1.5, 2.0, 3.0, 5.0 },
    },
    MicrofibralMuscle = {
        id = "MicrofibralMuscle",
        name = "Microfibral Muscle",
        slot = "Arms",
        active = false,
        energyPerSec = 0,
        description = "Allows lifting and throwing of heavy objects.",
        levels = {
            "Lift up to 100 kg",
            "Lift up to 200 kg",
            "Lift up to 400 kg",
            "Lift up to 800 kg",
        },
        magnitudes = { 100, 200, 400, 800 },
    },
    SpeedEnhancement = {
        id = "SpeedEnhancement",
        name = "Speed Enhancement",
        slot = "Legs",
        active = true,
        energyPerSec = 80,
        description = "Faster running and higher jumps.",
        levels = {
            "+25% speed, +25% jump",
            "+50% speed, +50% jump",
            "+100% speed, +100% jump",
            "+150% speed, +150% jump",
        },
        magnitudes = { 1.25, 1.5, 2.0, 2.5 },
    },
    SilentRun = {
        id = "SilentRun",
        name = "Run Silent",
        slot = "Legs",
        active = true,
        energyPerSec = 40,
        description = "Reduces noise made by your movement.",
        levels = { "Quieter", "Quieter still", "Near-silent", "Silent" },
        magnitudes = { 0.6, 0.4, 0.2, 0.0 },
    },
    Cloak = {
        id = "Cloak",
        name = "Cloak",
        slot = "Subdermal",
        active = true,
        energyPerSec = 200,
        description = "Renders you invisible to humans.",
        levels = {
            "Cloak vs. humans (low quality)",
            "Cloak vs. humans (med)",
            "Cloak vs. humans (high)",
            "Cloak vs. humans (perfect)",
        },
        magnitudes = { 0.5, 0.3, 0.15, 0.0 },
    },
    Regeneration = {
        id = "Regeneration",
        name = "Regeneration",
        slot = "Torso",
        active = true,
        energyPerSec = 120,
        description = "Drains bio-energy to restore health over time.",
        levels = {
            "+1 HP/s",
            "+2 HP/s",
            "+4 HP/s",
            "+8 HP/s",
        },
        magnitudes = { 1, 2, 4, 8 },
    },
    BallisticProtection = {
        id = "BallisticProtection",
        name = "Ballistic Protection",
        slot = "Subdermal",
        active = false,
        energyPerSec = 0,
        description = "Reduces damage from bullets.",
        levels = { "-15% bullet dmg", "-30%", "-45%", "-60%" },
        magnitudes = { 0.85, 0.70, 0.55, 0.40 },
    },
    Targeting = {
        id = "Targeting",
        name = "Targeting",
        slot = "Eye",
        active = true,
        energyPerSec = 30,
        description = "Highlights targets and improves aim accuracy.",
        levels = { "Tag enemies", "+ damage info", "+ weak spots", "+ predictive aim" },
        magnitudes = { 0.9, 0.75, 0.6, 0.4 }, -- spread multiplier
    },
    AggressiveDefense = {
        id = "AggressiveDefense",
        name = "Aggressive Defense System",
        slot = "Cranial",
        active = true,
        energyPerSec = 100,
        description = "Detonates incoming explosives in mid-air.",
        levels = { "30% chance", "50%", "75%", "100%" },
        magnitudes = { 0.3, 0.5, 0.75, 1.0 },
    },
    EMPShield = {
        id = "EMPShield",
        name = "EMP Shield",
        slot = "Subdermal",
        active = false,
        energyPerSec = 0,
        description = "Reduces damage from electrical and EMP sources.",
        levels = { "-25%", "-50%", "-75%", "-100%" },
        magnitudes = { 0.75, 0.5, 0.25, 0.0 },
    },
}

local Slots = { "Cranial", "Eye", "Arms", "Legs", "Torso", "Subdermal" }

local module = {}
module.Augs = Augs
module.Slots = Slots

function module.augsForSlot(slot: string): { string }
    local out = {}
    for id, def in pairs(Augs) do
        if def.slot == slot then
            table.insert(out, id)
        end
    end
    table.sort(out)
    return out
end

return module
